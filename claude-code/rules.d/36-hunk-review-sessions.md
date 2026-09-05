## Hunk review sessions

Justin reviews live in Hunk TUI sessions opened on the worktree being worked; his inline notes arrive silently — nothing pings the agent. During and after any review or PR round, poll for them: `hunk session list --json`, then `hunk session comment list --repo . --type user`. Address each note as its own commit (per the feedback-commits rule) and reply marking how each was addressed. The rest of the flow — the reply and reload commands, and what to do when no live session exists — is in the Hunk skill (`hunk skill path`).
