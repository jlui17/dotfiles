---
name: worktrees
description: "Justin's task-level git worktree flow. Use when starting task work that needs its own checkout or herdr space; when the user says wtnew, cdw, cdwrm, or 'start a worktree/space for this task'; when wtnew fails with 'no setup defined' and a repo's setup file must be written; or when tearing down a finished task's worktree and space. Covers the space = task = worktree model and the worktree-setups registry in the dotfiles repo."
---

# Task worktrees

**The model: a coding task gets its own worktree, and its herdr space is bound to it.** The worktree lives at `<repo>/.worktrees/<name>` on a new branch `<name>` (the task ID when one exists); space granularity and labeling are canonical in the `herdr-agents` skill. `.worktrees/` is in the global gitignore, and repos are never taught about this flow: teammates don't use herdr, so every convention lives in the dotfiles repo, not the codebase.

This covers *task-level* worktrees the user works in. Your own delegation isolation (subagent worktrees, `isolation: "worktree"`) is separate machinery and doesn't go through this flow.

## Start a task

```sh
wtnew <name> [summary...]     # e.g. wtnew colony-562 flow viewer
```

`wtnew` (zsh function, `zsh-functions/wtnew.sh`) runs in order: look up the repo's setup file (refuse loudly if missing), `git worktree add .worktrees/<name> -b <name>` from the main checkout, run `wt_setup` inside the new worktree, then open a focused herdr space labeled `[<name>] <summary...>` bound to it. Outside herdr it cd's into the worktree instead.

## The setup registry

`zsh-functions/worktree-setups/<repo>.sh`, keyed by the main checkout's directory basename. Each file defines:

- `wt_setup()` — required, runs inside the fresh worktree with `REPO_ROOT`, `WORKTREE_PATH`, and `BRANCH` set. Empty body (`:`) when a repo needs nothing; the explicit file is the point.
- `wt_dir="dir"` — optional, repo-relative override of the `.worktrees` location.

**When `wtnew` refuses with "no setup defined", discovery goes docs-first**: search the repo's docs and scripts for repo-specific worktree tooling (colony's `scripts/worktree.sh` is the canonical example); when it exists, `wt_setup` delegates to it — never re-implement a slice of it (a hand-copied step drifts the moment the repo's script changes). When no such tooling exists, read the repo's dev-setup docs for what a fresh checkout needs (env files, deps, generated code) and confirm the proposed setup with Justin before adding anything. Either way the file commits to dotfiles as its own change; the refusal is the onboarding path, so never bypass it by creating the worktree manually.

## Navigate and tear down

- `cdw` / `cdw <name>` / `cdw -` — fzf over, jump to, or leave the repo's worktrees. Reads `git worktree list`, so it sees every worktree regardless of who created it (wtnew, an agent, plain `git worktree add`).
- `cdwrm <name>` (`-f` to force) — remove worktrees.
- A worktree that exists but has no space yet: `herdr worktree open --cwd <repo-root> --path <worktree> --label '[<name>] <summary>'`.
- Task done: close the space (`herdr workspace close` or `prefix+shift+d`) and remove the worktree; `herdr worktree remove --workspace <id>` does both at once. Closing a space alone never deletes the worktree.
