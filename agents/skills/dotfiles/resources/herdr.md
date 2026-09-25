# Herdr

Owns `herdr/config.toml` (keybindings, theme, sidebar), `herdr/herdr-goto` (the fzf pane picker on `prefix+g`, linked into `~/.local/bin`), and the server supervisor: `herdr/herdr.service` (systemd user unit, Linux) or `herdr/herdr.plist` (LaunchAgent, macOS), all linked by `setup_herdr`. The app itself installs through the `Herdr` row of `GUI_APPS`, so `SKIP_MODULES` and `SKIP_APPS` skip the config and the app independently. Check the server with `herdr status server --json`: `detached_server_daemon` must be true, or `herdr machine add` from another machine refuses it. That flag is why the plist wraps the server in perl's `setsid` and why brew's own service is stopped and replaced: launchd does not start jobs as session leaders. Loading the supervisor restarts the server once (panes die); after that the module leaves a running server alone, so an edit to `herdr.plist` or `herdr-server-daemon` takes effect only after `launchctl bootout gui/$UID/herdr` and a re-run (another one-time restart). This resource covers the config only; driving herdr programmatically (sessions, panes, agents) is the sibling global skill `herdr-agents`.

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

## Testing a keybinding in a second session

The CLI has no command that presses a key, so a binding is tested from a second herdr session with a client attached inside `<pane>`, a scratch pane you create in the live session and close afterwards. `pane send-keys` then types into that client, and `pane read` shows what it drew, popups included.

```sh
env -i HOME=$HOME USER=$USER SHELL=/bin/zsh PATH=/usr/bin:/bin:/usr/sbin:/sbin "$(command -v herdr)" --session keytest server &
herdr --session keytest workspace create --cwd /tmp --label alpha --no-focus
herdr pane run <pane> "env -u HERDR_ENV -u HERDR_SOCKET_PATH -u HERDR_PANE_ID -u HERDR_TAB_ID -u HERDR_WORKSPACE_ID herdr --session keytest"
herdr pane send-keys <pane> ctrl+b g
herdr pane read <pane> --source visible
```

`env -i` with that PATH is what launchd gives the real server, and a popup or shell command inherits it. `ctrl+b q` detaches the client; `herdr session stop keytest` and `herdr session delete keytest` remove the session. A throwaway config goes in through `HERDR_CONFIG_PATH` on both the server and the client, and it needs `onboarding = false`: without it the first client opens the welcome modal, then an integrations page where Enter installs an agent integration into `~/.claude`.

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
