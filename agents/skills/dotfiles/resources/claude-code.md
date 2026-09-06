# Claude Code

Owns what only Claude Code reads: commands, Claude-only rule fragments in `rules.d/`, output styles, settings, statusline, the herdr hook, and plugins. `setup_claude_code` runs `setup_claude_code_skills` then `setup_claude_plugins`. Global skills, external skills, and the shared rules are not here; see `resources/agents.md`.

## Global rules

`rules.d/` here holds the fragments that mean nothing to Codex (`62-worker-cost.md`), so they reach `~/CLAUDE.md` only. The shared fragments, the assembly, the generated files, `99-local.md`, `SKIP_RULES`, and the line budget are in `resources/agents.md`.

## Output styles

`output-styles/*.md` are plain symlinks, frontmatter and all; `justin.md` is selected by `outputStyle` in `claude-code/settings.json`. An output style loads for the main session only, never for subagents. That is why the voice and session-reply rules live in the style: they govern how Claude talks to Justin in the terminal. A rule subagents also need is a rules fragment (`resources/agents.md`), not a style section.

## Commands

`commands/*.md` are plain symlinks into `~/.claude/commands`, pruned when the source is deleted.

## Settings, statusline, hook

`settings.json` is merged, not linked, because Claude Code rewrites `~/.claude/settings.json` at runtime (theme, model, `/fast`). `merge_json` deep-merges the repo's tracked keys into the machine's real file, repo winning on conflicts, and leaves machine-only keys alone. `settings.local.json` (gitignored) is merged after it, so for the keys it declares local wins over repo, re-asserted every run.

`statusline-command.sh` and `herdr-session-hook.sh` are plain symlinks; Claude Code never rewrites them. settings.json wires both in by path (`statusLine`, `hooks.SessionStart`).

## Plugins

Plugins cannot be symlinked: their state in `~/.claude/plugins/` carries machine-specific absolute paths, timestamps, and pinned commit SHAs. `setup_claude_plugins` replays `claude plugin marketplace add` and `claude plugin install` from `claude-code/plugins.txt` (format in its header), skipping any the state files already show installed.

The sync uninstalls any installed plugin missing from the manifest, unless it is listed in `KEEP_PLUGINS` in `.dotfiles-local`. That list is the home for machine-only plugins the shared manifest should not know about.

- Remove a plugin everywhere: delete its manifest line, re-run `./install.sh`.
- Keep a plugin on one machine: install it by hand, add it to `KEEP_PLUGINS`.

Installed state is read from Claude Code's own JSON (`installed_plugin_ids`, `marketplace_known`) rather than the CLI, because the `claude plugin` commands block indefinitely when install.sh runs inside a Claude Code session. An actual install or uninstall still calls the CLI, so run install.sh from a plain shell when the manifest changed.
