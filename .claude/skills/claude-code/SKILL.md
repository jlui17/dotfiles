---
name: claude-code
description: Maintains the claude-code module, Justin's complete Claude Code setup: global skills, slash commands, rules.d/ instruction fragments, and the output style deployed to ~/.claude, plus user-level settings.json deep-merged by install.sh (per-machine overrides in gitignored settings.local.json), plugins replayed from plugins.txt, and the statusline script. Use when adding or editing a global skill, slash command, CLAUDE.md rule, or the output style; when adding/removing plugins or changing shared/per-machine settings; or when a plugin unexpectedly disappears after install.sh (the manifest sync uninstalls unlisted plugins).
---

Deployed by install.sh `setup_claude_code` (the comment there describes the module split). The shared rules ship to Claude Code only: the old `~/AGENTS.md` assembly was dropped when the module went Claude Code-specific, so other harnesses (pi, opencode) have no default voice. If one later needs the rules, add a harness-native sink over the same `rules.d/` fragments rather than a parallel rules source; the deleted AGENTS.md assembly in git history is the template.

## Skills, commands, rules, output style

`rules.d/NN-<slug>.md` fragments (the `NN-` prefix orders them, the rest of the filename is the slug) are assembled into the generated `~/CLAUDE.md`, skipping slugs in this machine's `SKIP_RULES` (`.dotfiles-local`). Generated, not symlinked, because per-machine section exclusion needs a per-machine artifact; edits reach `~/CLAUDE.md` only on the next `./install.sh` run, and direct edits to the generated file get overwritten. `99-local.md` is gitignored for machine-only rules.

The fragments listed in `OUTPUT_STYLE_RULES` (install.sh) are additionally assembled into the output style `~/.claude/output-styles/justin.md`, selected via `outputStyle` in `claude-code/settings.json`. `~/CLAUDE.md` keeps its copy of the same fragments because subagents load CLAUDE.md but never see output styles.

Skills named in this machine's `SKIP_SKILLS` (`.dotfiles-local`) are not linked; removing an already-linked skill from a machine also means deleting its symlink from `~/.claude/skills` manually (install.sh never prunes).

## Settings, statusline, plugins

**settings.json** is not symlinked, because Claude Code rewrites `~/.claude/settings.json` at runtime (theme, model, `/fast`). It stays a real machine-local file; install.sh deep-merges the repo's tracked keys into it, **repo winning on conflicts** (merge_json in install.sh), while machine-only keys the repo doesn't declare are preserved.

**settings.local.json** (gitignored) holds this machine's overrides; install.sh merges it *after* the repo file, so on this machine **local wins over repo** for the keys it declares, re-asserted every run instead of being clobbered by the shared settings.

**statusline-command.sh** is a plain symlink; unlike settings.json it is never rewritten at runtime.

**Plugins** can't be symlinked: their state in `~/.claude/plugins/` carries machine-specific absolute paths, timestamps, and pinned commit SHAs. install.sh instead replays `claude plugin marketplace add` + `claude plugin install` from `claude-code/plugins.txt` (format in its header); the CLI calls are idempotent. **The sync uninstalls plugins missing from the manifest**: a hand-installed plugin gets removed on the next run unless listed in `KEEP_PLUGINS` in `.dotfiles-local`, the home for machine-only plugins the shared manifest shouldn't know about.

## Tasks

- Any add/edit (command, skill, rule fragment, setting) lands by re-running `./install.sh`.
- Remove a capability: delete the file/dir, then remove the stale symlink from `~/.claude` manually (install.sh only links, never prunes).
- Remove a plugin: delete its manifest line, re-run install.sh (the sync uninstalls it).
- Keep a plugin on this machine only: install it by hand, add it to `KEEP_PLUGINS`.

Note: this is the **repo maintenance** skill (lives in `.agents/skills/`); the skills inside `claude-code/skills/` are the **runtime** skills that get deployed.
