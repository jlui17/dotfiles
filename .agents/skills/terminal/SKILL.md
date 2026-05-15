---
name: terminal
description: Tmux (TPM + Catppuccin) and Ghostty (font/theme/size) configs.
---

Both are simple single-file configs with symlink-based install. Tmux uses TPM for plugin management (plugins declared via `set -g @plugin`, installed with prefix+I). Ghostty config changes apply instantly — no restart needed.

**Install flow** (install.sh):
- Tmux: clones tpm if missing, symlinks tmux.conf → ~/.config/tmux/tmux.conf
- Ghostty: symlinks ghostty/config to macOS path (~/Library/...) or Linux path (~/.config/ghostty/config)

**Tasks:**
- Change tmux theme/flavor: edit @catppuccin_flavor (latte/frappe/macchiato/mocha), reload with `tmux source-file ~/.config/tmux/tmux.conf`
- Add tmux plugin: add `set -g @plugin 'user/repo'` before TPM init line, reload, prefix+I
- Install/update tmux plugins: prefix+I
- Change ghostty font/theme/size: edit ghostty/config — takes effect immediately
