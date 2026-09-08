# Herdr

Owns `herdr/config.toml` (keybindings, theme, sidebar) and `herdr/herdr.service`, the systemd user unit that keeps the server up on Linux; both linked by `setup_herdr`. The app itself installs through the `Herdr` row of `GUI_APPS`, so `SKIP_MODULES` and `SKIP_APPS` skip the config and the app independently. On macOS the server is brew's LaunchAgent (`brew services`), so the unit is Linux-only; check it with `systemctl --user status herdr`. This resource covers the config only; driving herdr programmatically (sessions, panes, agents) is the sibling global skill `herdr-agents`.

## Split keys mirror tmux

`tmux.conf` leaves tmux's split bindings at their defaults: `%` splits side by side, `"` splits stacked. Herdr binds `split_vertical` and `split_horizontal` to the same two keys so the muscle memory carries over. Mirror the keys, never the names: herdr's "vertical" is side by side and "horizontal" is stacked, which is the reverse of tmux's `-h`/`-v` split flags.

## Design language behind `[theme.custom]` and the sidebar

Any restyle stays inside these rules.

- **Frame vs panes.** `theme = "terminal"` keeps pane content identical to what Ghostty draws. `[theme.custom]` restyles only herdr's own frame. The structural tokens (backgrounds, surfaces, text ladder, accent) are the values herdr ships for its built-in `catppuccin` (Mocha) theme, copied verbatim. Extend from that ladder; do not invent colors.
- **The four state colors are Okabe-Ito, not Mocha, on purpose.** `red`, `yellow`, `teal`, and `green` carry blocked, working, done, and idle. Mocha's own red and green collapse under red-green color-vision deficiency, so these four come from the Okabe-Ito palette and must never be "fixed" back to theme values. They earn their place while a colored dot is the only state channel; with `ui.status_indicators = "symbols"` a distinct glyph carries each state and the override becomes redundant. The colorblind rule lives in the global CLAUDE.md; the verification recipe is in `resources/terminal.md`.
- **Spacing is emphasis, not blank rows.** A terminal grid has no fractional rows. Each sidebar entry is a bright bold primary line (the tab name for agents, the space name for spaces) over a dim unbolded context line (space, or branch plus git status) that doubles as the separator. `row_gap` stays 0 in both sidebar sections.
- **Row-token inheritance gotcha.** An omitted style field inherits the row's contextual default, so a bold row stays bold under an `fg`-only override. Mute a token with an explicit `bold = false, dim = true`.

## Keys the installed release may not accept

A key chosen before the installed herdr accepts it sits commented in `config.toml` with its intended value. After a herdr upgrade, uncomment it and let the validator arbitrate:

```sh
herdr config check
```

If it passes, keep it. If it fails, re-comment it.

## Commands

Apply an edit to the running server:

```sh
herdr server reload-config
```

Validate the file:

```sh
herdr config check
```

List every key with its default and the built-in theme names:

```sh
herdr --default-config
```
