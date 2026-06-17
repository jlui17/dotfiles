---
name: claude-code
description: Claude Code plugins — marketplaces and plugins replayed via the `claude` CLI from claude-code/plugins.txt.
---

Claude-Code-specific config. Today that's plugins; the cross-agent skills, commands, and global rules live in the [[agent-skills]] module instead (those apply to every coding agent, not just Claude Code).

Plugins can't be symlinked. Their on-disk state in `~/.claude/plugins/` (`known_marketplaces.json`, `installed_plugins.json`, cloned `marketplaces/`, cached versions) carries machine-specific absolute paths, timestamps, and pinned commit SHAs. So instead of linking files, install.sh replays the install commands from a manifest — the `claude` CLI calls are idempotent and no-op when a plugin is already present.

**Manifest** — `claude-code/plugins.txt`, one line per marketplace:
`<github-owner/repo>  <plugin@marketplace> [<plugin@marketplace> ...]`
The first token is the marketplace repo; the rest are plugins to install from it.

**Install flow** (install.sh, PHASE 6c): for each line, `claude plugin marketplace add <repo>`, then `claude plugin install <plugin@marketplace>` for each plugin. Skips with a warning if the `claude` CLI isn't on PATH.

**Tasks:**
- Add a plugin: add (or extend) a line in `claude-code/plugins.txt`, re-run install.sh
- See what's installed: `claude plugin list`
- Inspect a plugin's components/cost: `claude plugin details <name>`
- Update a plugin: `claude plugin update <plugin@marketplace>` (restart to apply)
- Remove a plugin: `claude plugin uninstall <plugin@marketplace>` and delete its manifest entry
