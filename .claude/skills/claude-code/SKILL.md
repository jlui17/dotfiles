---
name: claude-code
description: Maintains the Claude Code config module: user-level settings.json deep-merged by install.sh, plugins replayed from claude-code/plugins.txt, and the statusline script. Use when adding/removing Claude Code plugins, changing shared settings or the statusline, or when a plugin unexpectedly disappears after install.sh (the manifest sync uninstalls unlisted plugins).
---

Claude-Code-specific config: user-level `settings.json` plus plugins. The cross-agent skills, commands, and global rules live in the [[agent-skills]] module instead (those apply to every coding agent, not just Claude Code).

**settings.json** — not symlinked, because Claude Code rewrites `~/.claude/settings.json` at runtime (theme, model, `/fast`). It stays a real machine-local file; install.sh (PHASE 6c) deep-merges the repo's tracked keys into it, **repo winning on conflicts** (merge_json in install.sh). So `claude-code/settings.json` is the source of truth for the keys it declares (model, theme, permissions, enabled plugins) and they propagate on re-run, while machine-only keys the repo doesn't declare are preserved. Secrets and per-machine values go in `~/.claude/settings.local.json`, which Claude Code merges on top and which stays untracked.

To change a shared setting: edit `claude-code/settings.json`, re-run install.sh. To keep a setting machine-local, don't add its key to the repo file (and if needed, put it in settings.local.json).

**statusLine** — `claude-code/statusline-command.sh` is symlinked to `~/.claude/statusline-command.sh` (unlike settings.json, this file is never rewritten at runtime, so a plain symlink works). `settings.json` points `statusLine.command` at it. It reads the statusline JSON on stdin and renders model name, reasoning effort (`.effort.level`), worktree (`.worktree.name` or `.workspace.git_worktree`), and context-window usage.

Plugins can't be symlinked. Their on-disk state in `~/.claude/plugins/` (`known_marketplaces.json`, `installed_plugins.json`, cloned `marketplaces/`, cached versions) carries machine-specific absolute paths, timestamps, and pinned commit SHAs. So instead of linking files, install.sh replays the install commands from a manifest — the `claude` CLI calls are idempotent and no-op when a plugin is already present.

**Manifest** — `claude-code/plugins.txt` (format documented in its header); install.sh PHASE 6c replays `claude plugin marketplace add` + `claude plugin install` per line, skipping with a warning if the `claude` CLI isn't on PATH.

**The sync uninstalls plugins missing from the manifest.** A plugin installed by hand on one machine gets removed on the next install.sh run unless it's listed in `KEEP_PLUGINS` in `.dotfiles-local` (gitignored) — that's the home for machine-only plugins the shared manifest shouldn't know about.

**Tasks:**
- Add a plugin: add (or extend) a line in `claude-code/plugins.txt`, re-run install.sh
- See what's installed: `claude plugin list`
- Inspect a plugin's components/cost: `claude plugin details <name>`
- Update a plugin: `claude plugin update <plugin@marketplace>` (restart to apply)
- Remove a plugin: delete its manifest entry, re-run install.sh (the sync uninstalls it)
- Keep a plugin on this machine only: install it by hand, add it to `KEEP_PLUGINS` in `.dotfiles-local`
