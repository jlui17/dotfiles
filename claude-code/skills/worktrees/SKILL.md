---
name: worktrees
description: "Justin's task-level git worktree flow. Use when starting task work that needs its own checkout or herdr space; when the user says wtnew, cdw, cdwrm, or 'start a worktree/space for this task'; when wtnew fails with 'no setup defined' and a repo's setup file must be written; or when tearing down a finished task's worktree and space. Covers the worktree-per-task model and the worktree-setups registry in the dotfiles repo."
---

# Task worktrees

**The model: a coding task gets its own worktree, and its herdr space is bound to it.** The worktree lives at `<repo>/.worktrees/<name>` on a new branch `<name>` (the task ID when one exists); space granularity and labeling are canonical in the `herdr-agents` skill. `.worktrees/` is in the global gitignore, and repos are never taught about this flow: teammates don't use herdr, so every convention lives in the dotfiles repo, not the codebase.

This covers *task-level* worktrees the user works in. Your own delegation isolation (subagent worktrees, `isolation: "worktree"`) is separate machinery and doesn't go through this flow.

**Task scaffolding lives at `.luidocs/` inside the worktree** (decision records especially). `.luidocs/` is globally gitignored, so scaffolding can't leak into the task's PR or dirty a checkout, and it dies with the worktree. No worktree yet → keep it in the session scratchpad and move it in once one exists; never write it into a shared or main checkout, or into a repo's tracked docs. A plan the repo treats as a deliverable (reviewed, committed via PR) is a different artifact and follows the repo's own conventions.

## Start a task

```sh
wtnew <name> [summary...]     # e.g. wtnew colony-562 flow viewer
wtnew --space <name> [summary...]   # kickoff: also open the herdr space
```

`wtnew` (zsh function, `zsh-functions/wtnew.sh`) runs in order: look up the repo's setup file (refuse loudly if missing), create the worktree (its own `git worktree add .worktrees/<name> -b <name>` plus `wt_setup`, or the repo's `wt_create` — see the registry below), then open a focused herdr space labeled `[<name>] <summary...>` bound to it. Outside herdr it cd's into the worktree instead. Two non-obvious facts: wtnew's own path branches from the main checkout's *current HEAD*, not `origin/main`, so check what it's parked on first; and a failed hook leaves the worktree in place with no space — fix and bind it with `herdr worktree open`, or drop it with `cdwrm`.

**From an agent shell (`CLAUDECODE=1`), wtnew skips the herdr space by default**: a session doing the task itself works from its own tab and can't inhabit the new space's pane, so the space would sit as an empty tab. Just `cd` into the worktree and work. A **kickoff** is the one agent flow that wants the space — the new agent starts in its root pane — so it passes `--space` (opened unfocused) and takes `root_pane.pane_id` from the JSON output for `herdr agent start`. Forgot `--space` on a kickoff → the worktree exists with no space; bind it with `herdr worktree open`, don't re-run wtnew.

## The setup registry

`zsh-functions/worktree-setups/<repo>.sh`, keyed by the main checkout's directory basename. Each file defines exactly one of two hooks (both run in a subshell with `REPO_ROOT`, `WORKTREE_PATH`, and `BRANCH` set), plus optionally `wt_dir="dir"`, a repo-relative override of the `.worktrees` location:

- `wt_setup()` — post-create hook: wtnew runs `git worktree add -b` itself, then this inside the fresh worktree. Empty body (`:`) when a repo needs nothing; the explicit file is the point.
- `wt_create()` — creation owner, for a repo with its own worktree tooling: runs from the repo root, delegates creation wholesale to that tooling, and must leave a worktree at `WORKTREE_PATH` on branch `BRANCH`. wtnew skips its own `git worktree add` and only binds the herdr space to the result.

**When `wtnew` refuses with "no setup defined", discovery goes docs-first**: search the repo's docs and scripts for repo-specific worktree tooling; when it exists, write a `wt_create()` delegating to it — never re-implement a slice of it (a hand-copied step drifts the moment the repo's script changes). When no such tooling exists, read the repo's dev-setup docs for what a fresh checkout needs (env files, deps, generated code) and confirm the proposed setup with Justin before adding anything. Either way the file commits to dotfiles as its own change; the refusal is the onboarding path, so never bypass it by creating the worktree manually — raw `herdr worktree create` and the TUI's new-worktree binding are the same bypass (neither runs the registry).

**A missing entry can be deliberate: check before writing one.** Colony has no setup file on purpose — its worktrees go through Claude Code's native machinery (`.worktreeinclude` copies `.env`; `tools/worktree.sh` only manages docker stacks), so `wtnew` refusing on colony is correct; don't re-add an entry.

## Navigate and tear down

- `cdw` / `cdw <name>` / `cdw -` — fzf over, jump to, or leave the repo's worktrees. Reads `git worktree list`, so it sees every worktree regardless of who created it (wtnew, an agent, plain `git worktree add`).
- `cdwrm [-f] [<name>...]` — remove worktrees; bare `cdwrm` opens an fzf multi-select, and an ambiguous basename errors listing the candidate paths.
- A worktree that exists but has no space yet: `herdr worktree open --cwd <repo-root> --path <worktree> --label <space label>`.
- Task done: close the space (`herdr workspace close <id>` or `prefix+shift+d`) and remove the worktree; `herdr worktree remove --workspace <id>` does both at once. Closing a space alone never deletes the worktree, no path deletes the task branch, and a dirty checkout needs `--force`/`-f` on either removal path.
