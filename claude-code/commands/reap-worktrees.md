Reap dead worktrees and local branches in this repo: classify every one with evidence, remove the dead, and report the survivors with the reason each stays. Branches are the durable record and worktrees are just checkouts, so removing a clean worktree loses nothing (its branch keeps the commits); deleting a branch is the destructive step and needs landed-or-abandoned evidence. Guidance below, not a script — adapt to what the repo actually contains.

**Proving "merged" is the hard part.** Squash merges mean `git branch --merged` never fires, and the forge may rewrite a merged PR's head ref (Gitea: to `refs/pull/N/head`), so neither git ancestry nor a branch→PR join finds landed work. The reliable test is content subsumption: `git merge-tree --write-tree <main-snapshot> <tip>` produces the snapshot's own tree exactly when main already contained everything the branch has. Test against main *as it stood in the weeks after the branch's last commit*, not only current main: later churn (a repo reorg especially) turns long-landed branches into false conflicts. A daily-snapshot pass over that window is cheap and catches most; an every-commit pass settles the rest, since a same-day merge hides between daily snapshots.

**Safe to purge:**
- Content subsumed by main at any point in its history (the work landed).
- Tip reachable from another ref that stays (a kept branch, a remote ref, a merged tip).
- Explicitly abandoned: its PR was closed without merging.
- Spent scaffolding: pre-rebase and backup branches of work that since shipped, construction branches rebased into a deliverable that merged, local PR-review checkouts (the content lives on the remote's pull refs), and registrations whose directory no longer exists.

**Never auto-dead** — keep these and report them instead:
- A dirty worktree: the uncommitted files may be the only copy.
- Anything attached to live work: a locked worktree, an open PR, a running session or agent.
- Unique content with no abandonment signal. Age sorts this list; it doesn't decide it.

**Where to look.** Start from `git fetch --prune`, then `git worktree list --porcelain` — worktrees accumulate in several families (the repo's own worktree dir, `.claude/worktrees/` agent and workflow leftovers, herdr worktrees, review checkouts inside session scratchpads) and the porcelain list sees them all, plus lock flags. Prefer the repo's own teardown tooling where it exists (colony's `tools/worktree.sh rm` also stops the worktree's docker stack and cleans its registry) and sweep that tooling's registry for orphaned entries too. The forge's PR list gives open/closed/merged state; live sessions come from `herdr workspace list`.

**Safety.** Record every tip SHA before deleting, so anything comes back with `git branch <name> <sha>` until gc prunes. Verify removals by recounting afterward rather than trusting exit status: a wrong cwd can make a batched `git branch -D` a silent no-op.
