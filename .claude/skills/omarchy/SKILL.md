---
name: omarchy
description: Use when adding, changing, or reverting a Hyprland keybinding on the Arch machine, when a macOS-style shortcut doesn't work under Omarchy, when editing, adding, or re-syncing an Omarchy desktop theme shipped by this repo (fleet, rainynight), or when the Omarchy shell stops drawing — dead command bar, menus that won't open, missing notifications — while a game or other GPU-heavy app holds most of the VRAM.
---

Omarchy module: Hyprland keybinding overrides, the desktop themes this repo ships, and the NVIDIA driver profile the shell needs. Only runs on Arch; skipped entirely on macOS/Ubuntu.

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

## NVIDIA shell profile

`omarchy/nvidia/*.json` symlinks into `~/.nv/nvidia-application-profiles-rc.d/` (first entry in the driver's documented search path, Appendix J3 — no root, and nothing in `/etc` to collide with a driver update). Guarded on `omarchy-hw-nvidia`, so an Omarchy box without an NVIDIA card gets nothing.

The driver loads **every** file in that directory and ignores extensions, so `backup_and_link`'s `.bak` is a second live copy of the rule, not an inert backup. Delete it after a first-time link, or a later edit to the repo file leaves the stale duplicate still in force.

Why it exists: the NVIDIA Wayland driver fails a client's buffer allocation outright when VRAM is full instead of spilling to system RAM the way it does on X11 ([egl-wayland#185](https://github.com/NVIDIA/egl-wayland/issues/185), open, no vendor response — the kernel tell is `Failed to allocate NVKMS memory for GEM object`). NVIDIA mitigates it for compositors by shipping the `No VidMem Reuse` profile (`GLVidHeapReuseRatio=0`, stop hoarding freed buffers in the per-process pool) for plasmashell, cosmic-comp, Hyprland, Xwayland, kwin, mutter, wlroots and weston — but not quickshell, which Omarchy's shell runs as. So the compositor survives a VRAM-hungry game and the shell doesn't.

We only add the missing `procname` rule and reuse NVIDIA's own profile by name; never redefine the key. Check what the driver already covers before adding a rule, in `/usr/share/nvidia/nvidia-application-profiles-*-rc` — and drop our file once quickshell appears there.

**Verifying a rule.** The driver logs profile parsing to stderr under `__GL_APPLICATION_PROFILE_LOG=1` (not `__GL_DEBUG_APP_PROFILES`, which is not a real variable and silently does nothing). It names files it parses and complains about a rule referencing an unknown profile, but says nothing when a rule resolves — so silence only means "no error", and confirming the log works needs a control: add a second rule pointing at a bogus profile name, see it flagged, delete it. Run it against a throwaway shell rather than the live one, and give it a real window or GL never initializes and nothing is logged at all:

```zsh
__GL_APPLICATION_PROFILE_LOG=1 quickshell -n -p /tmp/probe/shell.qml
```

Profiles are read at process start, so a change needs `omarchy-restart-shell`.

**The other half is not in this repo.** Reserving VRAM so the shell always has some to claim is per-game config: DXVK reads `$PWD/dxvk.conf`, and for a Steam/Proton title `$PWD` is the game's install root (verify with `readlink /proc/<pid>/cwd`, not by assuming the exe's directory). `dxgi.maxDeviceMemory = <MiB>` caps what the game thinks the card has. Proton sets `DXVK_LOG_LEVEL=none`, so `PROTON_LOG=1` is what surfaces DXVK's `Found config file:` line in `~/steam-$APPID.log`.
