---
name: omarchy
description: Use when adding, changing, or reverting a Hyprland keybinding on the Arch machine, when a macOS-style shortcut doesn't work under Omarchy, or when editing, adding, or re-syncing an Omarchy desktop theme shipped by this repo (fleet, rainynight).
---

Omarchy module: Hyprland keybinding overrides plus the desktop themes this repo ships. Only runs on Arch; skipped entirely on macOS/Ubuntu.

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
