---
name: herdr-agents
description: Use when driving herdr programmatically — starting a new session, space, or tab; launching a coding agent (Claude Code, codex, etc.) in a pane; sending it a prompt; checking or waiting on its output; or tearing any of that down.
---

# Driving herdr

Herdr is a terminal workspace manager with a socket API; every `herdr` subcommand prints JSON. The hierarchy is session → space → tab → pane, and IDs are hierarchical (`w1` → `w1:t2` → `w1:p2`). The UI says "space"; the CLI calls the same thing `workspace`.

Commands target one session's socket at a time: pass `--session <name>` (`default` is a valid name) for a specific one. Inside a herdr pane the CLI inherits `HERDR_SOCKET_PATH` pointing at that pane's own session, and the `HERDR_SESSION` env var loses to it, so `--session` is the only override that always works. `herdr api snapshot` dumps a session's entire state (spaces, tabs, panes, agents) in one call.

This skill covers cross-session orchestration; pane-level mechanics in the current session (splits and geometry, `pane run`/`wait-output`, read sources, the alternate-screen fallback) are canonical in the skill the binary ships: run `herdr --skill` and follow it for that work. It's versioned with the installed binary, so never restate its contents here. One deliberate divergence: it defaults to sibling panes in the caller's tab, while spawned sessions here get their own tabs/spaces so each agent owns its tab.

## Orient first

You may be running inside a herdr pane or in a plain terminal; both are normal, and a SessionStart hook already injects which one at startup. The ground truth is the environment: herdr exports `HERDR_ENV=1`, `HERDR_PANE_ID`, `HERDR_TAB_ID`, and `HERDR_WORKSPACE_ID` into every pane shell, so a set `HERDR_PANE_ID` means you're inside that pane. When inside, treat that pane as yours: don't close it, its tab, or start an agent in it. (`herdr pane current` is NOT you: it returns the session's focused pane, whoever that is.)

## When to start a session (and how to kick it off)

A herdr session is a new main session: fully steerable by the user, visible in the picker, alive after you're gone. Starting one is user-opt-in; the trigger lives in the always-on orchestration rule (`~/CLAUDE.md`), and delegation inside your own task (searches, review passes, verification, parallel slices) uses the Agent tool and worktrees, not herdr.

Write the kickoff prompt for a peer, not a worker: task, constraints, and deliverable, with the method left to the session — including spawning its own subagents and running its own review pass before opening a PR. Scope limits are fine ("keep the change surgical"); role limits are not: a session told to just execute and idle stops delegating and skips its own verification. Dividing labor with the spawner is fine when it's real ("the parent session babysits the PR review round").

## New headless session

```sh
herdr --session <name> server &   # creates and runs the session, no TUI
herdr --session <name> workspace create --cwd <dir> --label <label>
```

A fresh session has zero spaces, and every other call fails with `workspace_not_found` until that first `workspace create`. The user attaches visually later with `herdr session attach <name>`.

## Spaces and tabs

**A space is a task or a themed cluster of related small tasks; a tab is one agent session's work** (canonical here; the `worktrees` skill points at this). Label a task space `[<task-id>] <summary>` when a task ID exists; a task-less or cluster space gets a short plain name ("review", "agent upgrades"). More sessions for the same task or cluster means more tabs in that space, not another space. A coding-task space on a repo should be worktree-backed via the `worktrees` skill's flow (`wtnew`); read that skill before creating one.

`workspace create` and `tab create` both take `--cwd`, `--label`, `--env KEY=VALUE`, and `--focus`/`--no-focus`, and both return their root pane's ID in the JSON. Scope listings with `herdr tab list --workspace <id>`. Default to `--no-focus` so you don't yank the user's view; `--focus` only when they asked to be taken there.

For parallel agents on one repo, give each *task* a worktree-backed space via the `worktrees` skill's flow, so the repo's setup registry runs; raw `herdr worktree create --branch <name>` skips the registry and produces an un-set-up checkout. Parallel sessions on the *same* task still share one space as tabs.

## Spawn an agent

```sh
herdr tab create --cwd <dir> --label <task> --no-focus     # → root pane_id
herdr agent start <name> --kind claude --pane <pane_id>    # blocks until the agent is ready
herdr agent prompt <name> "<prompt>"                       # fire-and-forget
herdr agent prompt <name> "<prompt>" --wait                # blocks until the agent settles
```

Agents are named at `start`; every later command takes the name, not the pane ID. `--kind` covers claude, codex, gemini, opencode, amp, and more (see `herdr agent start --help`). The pane must be sitting at a shell prompt.

Only use `--wait` if you need the agent's output; a kickoff is fire-and-forget.

Every message to another herdr agent opens with a sender tag in a fixed shape: `[Agent tab <tab_id>, space <space_id>, session <name>]: <message>`, values from the `HERDR_*` env vars in Orient first, so the recipient knows who's asking and where to address a reply.

## Check on / wait for an agent

Herdr tracks each agent pane through semantic states: `working` (mid-turn), `blocked` (waiting on the user: a permission prompt or a question), `idle`/`done` (settled). `done` is `idle` in a tab nobody has focused since the work finished, and CLI reads don't mark it seen — so in a fleet listing, `done` agents are the ones with results the user hasn't looked at. `unknown` means herdr can't classify the pane; it doesn't prove completion.

- `herdr agent list` — fleet view, one `agent_status` per agent.
- `herdr agent wait <name> --until blocked --until done --timeout <ms>` — block until a state; without `--until` it matches any settled state.
- `herdr agent read <name> --lines <n>` — the terminal screen, for what the agent actually said or asked.
- `herdr agent prompt --wait` — submit and block until settled in one call.

## Teardown

`herdr tab close <tab_id>` kills the tab and whatever runs in it. Sessions: `herdr session stop <name>`, then `herdr session delete <name>` (delete only accepts stopped sessions).

## Gotchas

- `agent_prompt_stalled`: a prompt sent to a non-`working` agent must produce an observed lifecycle change within five seconds, or herdr returns this instead of waiting forever. Right after `agent start` it's usually a startup race (the submit didn't land even though start reported ready): retry once, and `agent read` confirms whether the text arrived.
- `prompt --wait` doesn't track turns: prompting an already-`working` agent can match the *previous* turn's completion. Wait for a settled state before prompting.
