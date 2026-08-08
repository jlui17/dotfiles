## Hunk review sessions

Justin reviews live in Hunk TUI sessions opened on the worktree being worked; his inline notes arrive silently — nothing pings the agent. During and after any review or PR round, run `hunk session list --json` and `hunk session comment list --repo . --type user`; address each note as its own commit, then reply via `hunk session comment apply --stdin` marking how each was addressed. `hunk session reload --repo . -- diff origin/main...` refreshes the diff and preserves user notes; never reload someone else's session pinned to a different worktree.
