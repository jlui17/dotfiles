---
name: claude-code
description: Claude Code config — user-level settings.json deep-merged, plus plugins replayed via the `claude` CLI from claude-code/plugins.txt.
---

Claude-Code-specific config: user-level `settings.json` plus plugins. The cross-agent skills, commands, and global rules live in the [[agent-skills]] module instead (those apply to every coding agent, not just Claude Code).

**settings.json** — not symlinked, because Claude Code rewrites `~/.claude/settings.json` at runtime (theme, model, `/fast`). It stays a real machine-local file; install.sh (PHASE 6c) deep-merges the repo's tracked keys into it with `jq -s '.[0] * .[1]'`, **repo winning on conflicts**. So `claude-code/settings.json` is the source of truth for the keys it declares (model, theme, permissions, enabled plugins) and they propagate on re-run, while machine-only keys the repo doesn't declare are preserved. Secrets and per-machine values go in `~/.claude/settings.local.json`, which Claude Code merges on top and which stays untracked.

To change a shared setting: edit `claude-code/settings.json`, re-run install.sh. To keep a setting machine-local, don't add its key to the repo file (and if needed, put it in settings.local.json).

Plugins can't be symlinked. Their on-disk state in `~/.claude/plugins/` (`known_marketplaces.json`, `installed_plugins.json`, cloned `marketplaces/`, cached versions) carries machine-specific absolute paths, timestamps, and pinned commit SHAs. So instead of linking files, install.sh replays the install commands from a manifest — the `claude` CLI calls are idempotent and no-op when a plugin is already present.

**Manifest** — `claude-code/plugins.txt`, one line per marketplace:
`<github-owner/repo>  <plugin@marketplace> [<plugin@marketplace> ...]`
The first token is the marketplace repo; the rest are plugins to install from it.

**Install flow** (install.sh, PHASE 6c): for each line, `claude plugin marketplace add <repo>`, then `claude plugin install <plugin@marketplace>` for each plugin. Skips with a warning if the `claude` CLI isn't on PATH.

**The sync uninstalls plugins missing from the manifest.** A plugin installed by hand on one machine gets removed on the next install.sh run unless it's listed in `KEEP_PLUGINS` in `.dotfiles-local` (gitignored) — that's the home for machine-only plugins the shared manifest shouldn't know about.

**Tasks:**
- Add a plugin: add (or extend) a line in `claude-code/plugins.txt`, re-run install.sh
- See what's installed: `claude plugin list`
- Inspect a plugin's components/cost: `claude plugin details <name>`
- Update a plugin: `claude plugin update <plugin@marketplace>` (restart to apply)
- Remove a plugin: delete its manifest entry, re-run install.sh (the sync uninstalls it)
- Keep a plugin on this machine only: install it by hand, add it to `KEEP_PLUGINS` in `.dotfiles-local`
