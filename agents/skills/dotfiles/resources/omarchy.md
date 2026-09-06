# Omarchy

The `omarchy/` directory owns the Hyprland overrides, the desktop themes this repo ships (fleet, rainynight), and the PATH shim that keeps the Omarchy shell off the GPU. `setup_omarchy` installs all three on Arch only.

## Ours vs Omarchy's

Ours, symlinked from this repo:

- `omarchy/hypr/{bindings,input,windows}-override.lua`. Every Hyprland personalization lands in one of these three.
- `omarchy/themes/{fleet,rainynight}/`. fleet is built here; rainynight is vendored with local edits.
- `omarchy/bin/quickshell`. The shim, linked at `/usr/local/bin/quickshell`: the one file this repo installs with sudo.

Omarchy's, upgraded out from under us by `omarchy-update`, never edited in place:

- `~/.local/share/omarchy/default/hypr/**`: the defaults, including `bindings/*.lua`.
- `~/.config/hypr/{hyprland,bindings,input,looknfeel,autostart,monitors}.lua`: seeded by Omarchy, then owned by the machine. `setup_omarchy` appends `require()` lines to `hyprland.lua` and touches nothing else there.

Anything else under `~/.config/hypr/` is machine-local, unmanaged, and may be stale.

Omarchy restructures its own config between releases and re-execs its components (the shell, the launcher) on events we do not control: pacman transactions, theme changes, `omarchy-update`. Two rules follow. A personalization that must survive the next migration lives in this repo's `*-override.lua`, never in the Omarchy-seeded `~/.config/hypr/*.lua`. Anything that must hold for every launch of a component belongs at a chokepoint every launch passes through, not in a startup hook. A hook that fires on `hyprland.start` misses every restart Omarchy triggers later.

## Keybindings

`bindings-override.lua` is loaded after Omarchy's defaults, so an `hl.unbind` plus `o.bind` pair wins. After editing:

```sh
hyprctl reload
```

Under Omarchy, Hyprland's live config is Lua. The old `.conf` chain (`hyprland.conf`, `bindings.conf`, and the files it sourced) was left in place by Omarchy's migration and nothing reads it, so the files in `~/.config/hypr` are not the truth. Verify against the compositor:

```sh
hyprctl systeminfo | grep configProvider   # lua
hyprctl binds                              # every live bind reads dispatcher: __lua
hyprctl getoption input:kb_options
```

A bind whose dispatcher is anything other than `__lua` came from a `.conf`. If none does, no `.conf` is being read, even when `hyprctl binds` shows entries that happen to match lines in `bindings.conf` (Omarchy's defaults reuse the same keys).

Third-party installers that write their binding into a `.conf` file report success and the bind silently does not exist. Re-declare the binding in `bindings-override.lua` instead of leaving it where the installer put it; that survives the tool's next setup run and reaches the machine through `install.sh`. The hyprwhspr binding is the existing case.

Before deleting a superseded config, diff it against live state (`hyprctl getoption`, `hyprctl binds`), not against its successor file. The successor is mostly commented-out template and looks falsely equivalent. A migration that leaves old files in place turns lost settings into silent drift: the old file still reads as if it were in force, and the keys just do something else. Not every `.conf` under `~/.config/hypr/` is dead: `hypridle.conf`, `hyprlock.conf`, `hyprsunset.conf`, and `xdph.conf` configure separate daemons and are live. Check who reads a file before removing it.

## Themes

Each directory under `omarchy/themes/` is linked into `~/.config/omarchy/themes/`. Apply a theme, and re-apply it after editing its colors so Omarchy regenerates the per-app configs:

```sh
omarchy theme set <name>
```

The colorblind rule applies to every palette here. The verification recipe is in `resources/terminal.md`. Justin's taste for a new theme: calm, cozy, night-cafe dark, muted and sleek, One Piece.

**fleet.** Its ANSI palette is not canonical. `ghostty/themes/fleet-dark-colorblind` is, and `colors.toml` copies its slots verbatim, including the deliberate red=orange, green=blue retune. A palette change starts in the ghostty file and is then mirrored into `colors.toml`. Only the roles without a ghostty slot (background and foreground ladders, muted, selection, orange, brown) are owned in this module.

**rainynight.** Vendored from https://github.com/atif-1402/omarchy-rainynight-theme, deliberately not a live clone, because it carries edits upstream would not take:

| Upstream | Local | Why |
| --- | --- | --- |
| `#f38ba8` red / `#a6e3a1` green | `#e57a3f` / `#56b09a` | colorblind safety, across every per-app file |
| `#1e1e2e` family (Mocha blue-purple base) | `#0f1011` / `#1e1f22` / `#2b2d30` | fleet's neutrals; Mocha read too blue |
| `#cdd6f4` foreground | `#dfe1e5` | matches the neutral base |
| `#89b4fa` accent | `#7d9cc9` | muted |

To re-sync: diff against a fresh clone, take upstream's changes, re-apply the substitutions above, re-verify per `resources/terminal.md`.

The One Piece wallpaper ships inside `fleet/backgrounds/`. For any other theme it is a machine-local extra in `~/.config/omarchy/backgrounds/<theme>/`. User backgrounds sort before the theme's own, so it becomes the default on theme switch.

## Software-rendered shell

`omarchy/bin/quickshell` execs the real binary with `QT_QUICK_BACKEND=software`. The shim's own comments cover how it finds the binary and why it walks PATH.

**Why.** The NVIDIA Wayland driver refuses a client's buffer allocation when VRAM is full instead of spilling to system RAM the way it does on X11 ([egl-wayland#185](https://github.com/NVIDIA/egl-wayland/issues/185)). A game holding most of the card leaves Quickshell unable to create surfaces, so the bar and menus stop drawing. Rendering on the CPU into shared memory means the shell never asks the GPU for anything, so it cannot be starved. The compositor is unaffected: NVIDIA ships its own `No VidMem Reuse` profile for Hyprland and Xwayland, so a VRAM-reuse profile for the shell was the wrong altitude and was dropped.

**Why a PATH shim.** Omarchy calls `quickshell` unqualified everywhere, and `/usr/local/bin` precedes `/usr/bin` in the session PATH, so the shim is the one chokepoint every launch passes through, restarts included. An autostart hook fired once on `hyprland.start`. A later pacman transaction re-exec'd the launcher with an untouched environment and put the shell back on the GPU until a dead command bar surfaced it. `/usr/local/bin` is the FHS local-override directory: the `filesystem` package owns the directory but no package owns files in it, so the shim shadows a pacman binary by precedence without conflicting with one.

**Root.** Writing the link needs sudo. `setup_omarchy` reads the link first and reaches sudo only when it is missing or stale, so a steady-state run never prompts. Keep that guard when editing.

**Keep `QT_QUICK_BACKEND` out of the session environment.** It would also catch moonlight and kdenlive, which want the GPU. The variable touches Qt Quick only, not Qt Widgets, so check `ldd <binary> | grep libQt6Quick` before assuming an app is unaffected.

**Which backend a running shell is on:**

```sh
tr '\0' '\n' < /proc/$(pgrep -xn quickshell)/environ | grep QT_QUICK_BACKEND
nvidia-smi   # a software-rendered shell does not appear at all
```

**Reproducing the bug takes seconds.** With a VRAM-hungry game running, start a throwaway GPU-backed quickshell against a scratch QML file and open a panel. The GPU backend fails with `Could not create EGL surface (EGL error 0x3003)` and `eglSwapBuffers failed with 0x300d`; the software backend does not.

**Profiling.** `utime+stime` from `/proc/<pid>/stat` over a fixed window (`CLK_TCK` is 100) is exact where `top` sampling is not, and `omarchy-shell shell toggle` makes an identical panel workload scriptable across backends. Idle cost on software is indistinguishable from GPU rendering; interaction costs more and stays trivial. Do not read an IPC ping as a startup-time signal: it answers before the shell draws.

**The launcher supervises.** `omarchy-launch-shell` relaunches Quickshell on an unclean exit, so stopping the shell without stopping the launcher first just restarts it. Find the launcher as Quickshell's parent process (systemd-cat execs, so it is the direct parent). `pkill -f omarchy-launch-shell` also matches any shell whose command line merely mentions it.

**The other half is not in this repo.** Reserving VRAM for a game is per-game config. DXVK reads `$PWD/dxvk.conf`, and for a Steam/Proton title `$PWD` is the game's install root; verify with `readlink /proc/<pid>/cwd` rather than assuming the exe's directory. `dxgi.maxDeviceMemory = <MiB>` only changes what DXVK reports to the app, so it nudges an engine's streaming budget rather than capping allocations. Proton sets `DXVK_LOG_LEVEL=none`, so `PROTON_LOG=1` is what surfaces DXVK's `Found config file:` line in `~/steam-<appid>.log`.
