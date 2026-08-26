---
name: herdr-config
description: Use when changing herdr keybindings, theme, or sidebar config; when a herdr split or pane binding should match tmux's; or when editing herdr/config.toml.
---

Single-file config with symlink-based install, like ghostty/opencode.

**Install flow** (install.sh): `setup_herdr` symlinks `herdr/config.toml` → `~/.config/herdr/config.toml`. Installation itself goes through the `GUI_APPS` table (`brew install herdr` on macOS, the `herdr.dev/install.sh` universal installer on Arch/Ubuntu). Both the module (`SKIP_MODULES`) and the app install (`SKIP_APPS`, name `Herdr`) are individually skippable per-machine via `.dotfiles-local`.

**Split keybindings match tmux.conf**: tmux.conf doesn't override tmux's default split bindings, so tmux uses `%` (side-by-side) and `"` (stacked). Herdr's `split_vertical` (side-by-side) and `split_horizontal` (stacked) are bound to the same keys — `prefix+%` and `prefix+quote` — so the muscle memory carries over. Herdr's own naming matches this: "vertical" = side-by-side, "horizontal" = stacked (the reverse of tmux's `-h`/`-v` split-window flags, which is why the keys, not the flag names, are what's mirrored).

**Design language** (the intent behind the `[theme.custom]` and sidebar sections; any restyle stays inside it):

- **Frame vs panes**: `theme = "terminal"` keeps pane content matching Ghostty exactly; `[theme.custom]` restyles only herdr's own frame. Structural tokens (backgrounds, surfaces, text ladder, accent) are the built-in Catppuccin Mocha values verbatim (`Palette::catppuccin()` in herdr's `src/app/state.rs`) — extend from the Mocha ladder, don't invent colors.
- **The four state colors are Okabe-Ito, not Mocha, deliberately**: blocked/working/done/idle must stay separable under red-green color-vision deficiency, so never "fix" them back to theme reds and greens. They exist only until `ui.status_indicators = "symbols"` ships and shapes disambiguate the states.
- **Spacing is emphasis, not blank rows**: a terminal grid has no fractional rows, so each sidebar entry is a bright bold primary line (what Justin triages by: the tab name for agents, the space name for spaces) over a dim unbolded context line (space / branch + git status) that doubles as the separator; `row_gap` stays 0.
- **Row-token styling gotcha**: omitted style fields inherit the row's contextual default (a bold row stays bold under an `fg`-only override) — mute with an explicit `bold = false, dim = true`.
- **Keys ahead of the release** (`sidebar_bg`, `status_indicators`) sit commented with "Unreleased as of 0.8.0" notes and chosen values; after a herdr upgrade, try uncommenting and let `herdr config check` arbitrate.

**Tasks:**
- Reload config after an edit: `herdr server reload-config`
- Validate config: `herdr config check`
- Change theme: edit `[theme] name` (built-ins: catppuccin, terminal, tokyo-night, dracula, nord, gruvbox, one-dark, solarized, kanagawa, rose-pine, vesper)
- See all available keys/options: `herdr --default-config`
