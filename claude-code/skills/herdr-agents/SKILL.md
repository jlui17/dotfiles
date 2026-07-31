---
name: herdr-agents
description: Use when driving herdr programmatically — starting a new session, space, or tab; launching a coding agent (Claude Code, codex, etc.) in a pane; sending it a prompt; checking or waiting on its output; or tearing any of that down.
---

# Driving herdr

Herdr is a terminal workspace manager with a socket API; every `herdr` subcommand prints JSON. The hierarchy is session → space → tab → pane, and IDs are hierarchical (`w1` → `w1:t2` → `w1:p2`). The UI says "space"; the CLI calls the same thing `workspace`.

Commands target the default session unless told otherwise: pass `--session <name>` or set `HERDR_SESSION=<name>` for a named one (`HERDR_SOCKET_PATH` is the low-level override). `herdr api snapshot` dumps a session's entire state (spaces, tabs, panes, agents) in one call.

## Orient first

You may be running inside a herdr pane or in a plain terminal; both are normal. `herdr pane current` tells you which: it returns your own pane when inside (detection walks the process tree, no env vars needed) and errors when you're not in one. When inside, treat that pane as yours: don't close it, its tab, or start an agent in it.

## New headless session

```sh
HERDR_SESSION=<name> herdr server &   # creates and runs the session, no TUI
HERDR_SESSION=<name> herdr workspace create --cwd <dir> --label <label>
```

A fresh session has zero spaces, and every other call fails with `workspace_not_found` until that first `workspace create`. The user attaches visually later with `herdr session attach <name>`.

## Spaces and tabs

`workspace create` and `tab create` both take `--cwd`, `--label`, `--env KEY=VALUE`, and `--focus`/`--no-focus`, and both return their root pane's ID in the JSON. Scope listings with `herdr tab list --workspace <id>`. Default to `--no-focus` so you don't yank the user's view; `--focus` only when they asked to be taken there.

For parallel agents on one repo, `herdr worktree create --branch <name> [--base <ref>] --label <l>` opens a space backed by a fresh git worktree: one space per branch, no file conflicts.

## Spawn an agent

```sh
herdr tab create --cwd <dir> --label <task> --no-focus     # → root pane_id
herdr agent start <name> --kind claude --pane <pane_id>    # blocks until the agent is ready
herdr agent prompt <name> "<prompt>" --wait
```

Agents are named at `start`; every later command takes the name, not the pane ID. `--kind` covers claude, codex, gemini, opencode, amp, and more (see `herdr agent start --help`). The pane must be sitting at a shell prompt.

## Check on / wait for an agent

Herdr tracks each agent pane through semantic states: `working` (mid-turn), `blocked` (waiting on the user: a permission prompt or a question), `idle`/`done` (settled).

- `herdr agent list` — fleet view, one `agent_status` per agent.
- `herdr agent wait <name> --until blocked --until done --timeout <ms>` — block until a state; without `--until` it matches any settled state.
- `herdr agent read <name> --lines <n>` — the terminal screen, for what the agent actually said or asked.
- `herdr agent prompt --wait` — submit and block until settled in one call.

## Teardown

`herdr tab close <tab_id>` kills the tab and whatever runs in it. Sessions: `herdr session stop <name>`, then `herdr session delete <name>` (delete only accepts stopped sessions).

## Gotchas

- `agent_prompt_stalled` right after `agent start` is a startup race: the submit didn't land even though start reported ready. Retry once; `agent read` confirms whether the text arrived.
- `prompt --wait` doesn't track turns: prompting an already-`working` agent can match the *previous* turn's completion. Wait for a settled state before prompting.
- Layout commands (`pane split/swap/resize/zoom`) and raw-terminal control (`pane run/send-keys/wait-output`) exist but are rarely needed for agent driving; discover them via `herdr pane --help` when they are.
