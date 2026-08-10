---
name: herdr-config
description: Herdr terminal/agent multiplexer config (keybindings, theme, sidebar). Use when changing herdr keybindings, theme, or other config.toml settings.
---

Single-file config with symlink-based install, like ghostty/opencode.

**Install flow** (install.sh): `setup_herdr` symlinks `herdr/config.toml` → `~/.config/herdr/config.toml`. Installation itself goes through the `GUI_APPS` table (`brew install herdr` on macOS, the `herdr.dev/install.sh` universal installer on Arch/Ubuntu). Both the module (`SKIP_MODULES`) and the app install (`SKIP_APPS`, name `Herdr`) are individually skippable per-machine via `.dotfiles-local`.

**Split keybindings match tmux.conf**: tmux.conf doesn't override tmux's default split bindings, so tmux uses `%` (side-by-side) and `"` (stacked). Herdr's `split_vertical` (side-by-side) and `split_horizontal` (stacked) are bound to the same keys — `prefix+%` and `prefix+quote` — so the muscle memory carries over. Herdr's own naming matches this: "vertical" = side-by-side, "horizontal" = stacked (the reverse of tmux's `-h`/`-v` split-window flags, which is why the keys, not the flag names, are what's mirrored).

**Tasks:**
- Reload config after an edit: `herdr server reload-config`
- Validate config: `herdr config check`
- Change theme: edit `[theme] name` (built-ins: catppuccin, terminal, tokyo-night, dracula, nord, gruvbox, one-dark, solarized, kanagawa, rose-pine, vesper)
- See all available keys/options: `herdr --default-config`
