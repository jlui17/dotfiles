---
name: terminal
description: Tmux (TPM + Catppuccin) and Ghostty (font/theme/size) configs. Use when changing tmux or Ghostty config, plugins, themes, or fonts.
---

Both are simple single-file configs with symlink-based install. Ghostty config changes apply instantly — no restart needed.

**Install flow** (install.sh):
- Tmux: clones tpm if missing, symlinks tmux.conf → ~/.config/tmux/tmux.conf
- Ghostty: symlinks ghostty/config to macOS path (~/Library/...) or Linux path (~/.config/ghostty/config)

**Tasks:**
- Change tmux theme/flavor: edit @catppuccin_flavor (latte/frappe/macchiato/mocha), reload with `tmux source-file ~/.config/tmux/tmux.conf`
- Add tmux plugin: add `set -g @plugin 'user/repo'` before TPM init line, reload, prefix+I
- Update tmux plugins: prefix+U
- Change ghostty font/theme/size: edit ghostty/config
