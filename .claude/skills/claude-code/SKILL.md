---
name: claude-code
description: Maintains the claude-code module, Justin's complete Claude Code setup: global skills, slash commands, rules.d/ instruction fragments, and the output style deployed to ~/.claude, plus user-level settings.json deep-merged by install.sh (per-machine overrides in gitignored settings.local.json), plugins replayed from plugins.txt, and the statusline script. Use when adding or editing a global skill, slash command, CLAUDE.md rule, or the output style; when adding/removing plugins or changing shared/per-machine settings; or when a plugin unexpectedly disappears after install.sh (the manifest sync uninstalls unlisted plugins).
---

One module, one consumer: `claude-code/` holds everything Claude Code reads, deployed by install.sh `setup_claude_code` in two halves — skills/commands/rules/output style (`setup_claude_code_skills`) and settings/statusline/plugins (`setup_claude_plugins`). Other harnesses get their own modules with harness-native config (`pi/`, `opencode/`); if one later needs the shared rules, add a sink over the same `rules.d/` fragments (the deleted `~/AGENTS.md` assembly in git history is the template) rather than a parallel rules source.

## Skills, commands, rules, output style

**Layout:**
- `claude-code/commands/*.md` — global slash commands (one file per command), symlinked into `~/.claude/commands/`.
- `claude-code/skills/<name>/SKILL.md` — global skills (one dir per skill), symlinked into `~/.claude/skills/`.
- `claude-code/rules.d/NN-<slug>.md` — global instruction rules, one section per file (the `NN-` prefix orders them, the slug names them). install.sh assembles them into the generated `~/CLAUDE.md`, skipping any slugs in this machine's `SKIP_RULES` (`.dotfiles-local`). Generated, not symlinked, because per-machine section exclusion needs a per-machine artifact. `99-local.md` is gitignored for machine-only rules.
- The voice-core fragments listed in `OUTPUT_STYLE_RULES` (install.sh) are additionally assembled into the Claude Code output style `~/.claude/output-styles/justin.md`, selected via `outputStyle` in `claude-code/settings.json`. `~/CLAUDE.md` keeps its copy of the same fragments because subagents load CLAUDE.md but never see output styles.

Skills named in this machine's `SKIP_SKILLS` (`.dotfiles-local`) are not linked — like `SKIP_RULES` but for whole skills; removing an already-linked skill from a machine also means deleting its symlink from `~/.claude/skills` manually (install.sh never prunes).

**Editing a rule means re-running install.sh.** Edits to `rules.d/` reach `~/CLAUDE.md` and the output style only on the next `./install.sh` run (generated, not symlinked). Never edit the generated files directly; the next run overwrites them.

## Settings, statusline, plugins

**settings.json** — not symlinked, because Claude Code rewrites `~/.claude/settings.json` at runtime (theme, model, `/fast`). It stays a real machine-local file; install.sh deep-merges the repo's tracked keys into it, **repo winning on conflicts** (merge_json in install.sh). So `claude-code/settings.json` is the source of truth for the keys it declares (model, theme, permissions, enabled plugins, outputStyle) and they propagate on re-run, while machine-only keys the repo doesn't declare are preserved.

**settings.local.json** — `claude-code/settings.local.json` (gitignored) holds this machine's overrides, mirroring the `.dotfiles-local` pattern. install.sh merges it into `~/.claude/settings.json` *after* the repo file, so on this machine **local wins over repo** for the keys it declares, and the override is re-asserted every run instead of being clobbered by the shared settings.

To change a shared setting: edit `claude-code/settings.json`, re-run install.sh. To pin a setting on this machine only (including overriding a repo-declared key): put it in `claude-code/settings.local.json`, re-run install.sh.

**statusLine** — `claude-code/statusline-command.sh` is symlinked to `~/.claude/statusline-command.sh` (unlike settings.json, this file is never rewritten at runtime, so a plain symlink works). `settings.json` points `statusLine.command` at it. It reads the statusline JSON on stdin and renders model name, reasoning effort (`.effort.level`), worktree (`.worktree.name` or `.workspace.git_worktree`), and context-window usage.

Plugins can't be symlinked. Their on-disk state in `~/.claude/plugins/` (`known_marketplaces.json`, `installed_plugins.json`, cloned `marketplaces/`, cached versions) carries machine-specific absolute paths, timestamps, and pinned commit SHAs. So instead of linking files, install.sh replays the install commands from a manifest — the `claude` CLI calls are idempotent and no-op when a plugin is already present.

**Manifest** — `claude-code/plugins.txt` (format documented in its header); install.sh replays `claude plugin marketplace add` + `claude plugin install` per line, skipping with a warning if the `claude` CLI isn't on PATH.

**The sync uninstalls plugins missing from the manifest.** A plugin installed by hand on one machine gets removed on the next install.sh run unless it's listed in `KEEP_PLUGINS` in `.dotfiles-local` (gitignored) — that's the home for machine-only plugins the shared manifest shouldn't know about.

## Tasks

- Any add/edit (command, skill, rule fragment, setting) lands by re-running `./install.sh`.
- Remove a capability: delete the file/dir; remove the stale symlink from `~/.claude` manually (install.sh only links, never prunes).
- Add a plugin: add (or extend) a line in `claude-code/plugins.txt`, re-run install.sh
- See what's installed: `claude plugin list`; inspect: `claude plugin details <name>`; update: `claude plugin update <plugin@marketplace>` (restart to apply)
- Remove a plugin: delete its manifest entry, re-run install.sh (the sync uninstalls it)
- Keep a plugin on this machine only: install it by hand, add it to `KEEP_PLUGINS` in `.dotfiles-local`

Note: this is a **repo maintenance** skill (lives in `.claude/skills/`, describes the module). The skills *inside* `claude-code/skills/` are the **runtime** skills that get deployed.
