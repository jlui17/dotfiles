---
name: terminal
description: Use when changing tmux or Ghostty config — keybindings, plugins, theme, or font — or when a tmux plugin isn't loading.
---

Symlink-based install. Tmux is a single file; Ghostty is a config file plus a `themes/` directory. Ghostty config changes apply instantly — no restart needed.

**Install flow** (install.sh):
- Tmux: clones tpm if missing, symlinks tmux.conf → ~/.config/tmux/tmux.conf
- Ghostty: symlinks ghostty/config to macOS path (~/Library/...) or Linux path (~/.config/ghostty/config), and ghostty/themes → ~/.config/ghostty/themes; skipped entirely on Ubuntu, which this repo treats as a headless VPS

**Ghostty themes are files, not inline palettes.** `ghostty/config` carries font and `theme = <name>` only; every color lives in `ghostty/themes/<name>`, which is an ordinary config fragment (background, foreground, cursor-color, selection-*, palette 0-15). Switching themes is a one-line edit; adding one is a new file, no install.sh change. On macOS the config and the themes land in *different* directories: Ghostty reads config from Application Support but only scans the XDG path for user themes, which is why setup_ghostty links two places.

The shipped themes are both tuned for red-green color vision deficiency, so the red slot is orange and the green slot is blue. A palette edit that "fixes" green back to green defeats the point. To verify a new or edited theme, simulate deuteranopia and protanopia (Vienot matrices in linear RGB), then check that every cross-family pair of text colors stays apart in CIE ΔE76 and that every color clears 4.5:1 on the background.

**Tasks:**
- Change tmux theme/flavor: edit @catppuccin_flavor (latte/frappe/macchiato/mocha), reload with `tmux source-file ~/.config/tmux/tmux.conf`
- Add tmux plugin: add `set -g @plugin 'user/repo'` before TPM init line, reload, prefix+I
- Update tmux plugins: prefix+U
- Change ghostty font/size: edit ghostty/config
- Switch ghostty theme: edit the `theme =` line; `ghostty +list-themes | grep user` shows what this repo ships
- Verify a theme resolves: `ghostty +show-config` should echo the theme's own background, and `ghostty +validate-config` should exit 0
