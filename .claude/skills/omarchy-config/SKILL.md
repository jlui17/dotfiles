---
name: omarchy-config
description: Use when adding, changing, or reverting a Hyprland keybinding on the Arch machine, when a macOS-style shortcut doesn't work under Omarchy, when editing, adding, or re-syncing an Omarchy desktop theme shipped by this repo (fleet, rainynight), or when the Omarchy shell stops drawing — dead command bar, menus that won't open, missing notifications — while a game or other GPU-heavy app holds most of the VRAM.
---

Omarchy module: Hyprland keybinding overrides, the desktop themes this repo ships, and the software-rendering shim the shell needs on NVIDIA. Only runs on Arch; skipped entirely on macOS/Ubuntu.

## Keybindings

Single override file that unbinds and rebinds Omarchy's default keybindings to match macOS Cmd-key muscle memory. Edits propagate via symlink + hyprctl reload.

**Install flow** (install.sh): guards on OS=arch + omarchy-update exists. Symlinks bindings-override.conf → ~/.config/hypr/bindings-override.conf. Appends `source = bindings-override.conf` to hyprland.conf if missing.

**Tasks:**
- Add/modify binding: edit bindd lines, `hyprctl reload`
- Revert to default: comment/remove unbind+bindd lines for that binding, `hyprctl reload`
- SUPER key: Cmd on Apple keyboards, Windows key on PC — set by Omarchy, not this module

## Themes

Each dir under `omarchy/themes/` is symlinked to `~/.config/omarchy/themes/<name>` by install.sh. Apply with `omarchy theme set <name>`; after editing a theme's colors, re-apply the theme to regenerate app configs. Justin's taste, for new themes: calm cozy night-cafe dark, muted and sleek, One Piece; the colorblind rule in this repo's CLAUDE.md applies to every palette.

- **fleet** — custom theme, built here. Its ANSI palette is NOT canonical: `ghostty/themes/fleet-dark-colorblind` is, and `colors.toml` copies its slots verbatim (red=orange, green=blue is that file's deliberate colorblind retune — see the terminal skill for the verification recipe). A palette change starts in the ghostty file, then gets mirrored into `colors.toml`; only the non-terminal roles (backgrounds, muted, selection neutrals) are owned here.
- **rainynight** — vendored from https://github.com/atif-1402/omarchy-rainynight-theme (deliberately not a live clone: it carries local edits upstream wouldn't take: the Catppuccin `#f38ba8`/`#a6e3a1` red/green pair replaced by `#e57a3f`/`#56b09a` for colorblind safety, and the Mocha blue-purple base swapped for fleet's `#0f1011`/`#1e1f22`/`#2b2d30` neutrals with a muted `#7d9cc9` accent). To re-sync with upstream: diff against a fresh clone, take upstream's changes, re-apply the local color substitutions (git log this dir for the full map), re-verify per the terminal skill.

The One Piece wallpaper ships inside `fleet/backgrounds/`. For other themes it's a machine-local extra in `~/.config/omarchy/backgrounds/<theme>/` (user backgrounds sort first, so it becomes the default on theme switch).

## Software-rendered shell

`omarchy/bin/*` symlinks into `~/.local/bin`; `autostart-override.lua` calls `omarchy-shell-software` by name on `hyprland.start`, which relaunches the shell with `QT_QUICK_BACKEND=software`.

Why: the NVIDIA Wayland driver refuses a client's buffer allocation when VRAM is full instead of spilling to system RAM the way it does on X11 ([egl-wayland#185](https://github.com/NVIDIA/egl-wayland/issues/185), open, no vendor response). A game holding most of an 8GB card leaves quickshell unable to create surfaces, so the bar and menus stop drawing. Rendering on the CPU into shared memory means the shell never asks the GPU for anything, so it cannot be starved. The compositor is unaffected — NVIDIA already ships its `No VidMem Reuse` profile for Hyprland and Xwayland.

**Three mechanisms that do not work**, so they don't get retried: a shim named `omarchy-launch-shell` in `~/.local/bin` (Omarchy puts its own bin dir *first* on PATH), editing Omarchy's `default/hypr/autostart.lua` (package-owned, `omarchy-update` overwrites it, and there is no unbind for an exec), and a native knob (quickshell has no backend flag, `shell.json` has no render setting). Relaunching after Omarchy's default has started is what's left, and it costs a visible bar flash at login.

`QT_QUICK_BACKEND` stays out of the session environment on purpose: it would also catch moonlight and kdenlive, which want the GPU. Check `ldd` against `libQt6Quick` before assuming an app is unaffected — the variable only touches Qt Quick, not Qt Widgets.

**The launcher supervises**, relaunching Quickshell on an unclean exit, so anything that swaps the backend must kill the supervisor first or it restores the GPU-backed shell underneath. It also passes its own environment through to Quickshell, which is why setting the variable on the launcher works at all.

**Reproducing the bug takes seconds, not a session.** With a VRAM-hungry game running, start a throwaway GPU-backed shell against a scratch QML file; every panel open fails with `Could not create EGL surface (EGL error 0x3003)` and `eglSwapBuffers failed with 0x300d`. Measured 18 failures for 18 panel opens on the GPU backend, 0 on software.

**Profiling the shell**: `utime+stime` from `/proc/<pid>/stat` over a fixed window (`CLK_TCK` is 100) is exact where `top` sampling is not, and the `omarchy-shell shell toggle` IPC makes an identical workload scriptable across backends. Idle dominates any real day: measured 0.23% of one core on software vs 0.19% GPU-backed, with interaction 4.3x more expensive on software and still trivial. Don't trust an IPC ping as a startup-time signal — it answers before the shell draws.

**The other half is not in this repo.** Reserving VRAM for a game is per-game config: DXVK reads `$PWD/dxvk.conf`, and for a Steam/Proton title `$PWD` is the game's install root (verify with `readlink /proc/<pid>/cwd`, not by assuming the exe's directory). `dxgi.maxDeviceMemory = <MiB>` only changes what DXVK *reports* to the app, so it nudges an engine's streaming budget rather than capping allocations. Proton sets `DXVK_LOG_LEVEL=none`, so `PROTON_LOG=1` is what surfaces DXVK's `Found config file:` line in `~/steam-$APPID.log`.
