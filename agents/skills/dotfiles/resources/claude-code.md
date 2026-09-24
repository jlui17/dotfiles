# Claude Code

Owns what only Claude Code reads: commands, Claude-only rule fragments in `rules.d/`, output styles, settings, statusline, the herdr hook, and plugins. `setup_claude_code` runs `setup_claude_code_skills` then `setup_claude_plugins`. Global skills, external skills, and the shared rules are not here; see `resources/agents.md`.

## Global rules

`rules.d/` here holds the fragments that mean nothing to Codex (`62-worker-cost.md`, which sends Claude's workers to Codex), so they reach `~/CLAUDE.md` only. The shared fragments, the assembly, the generated files, `99-local.md`, `SKIP_RULES`, and the line budget are in `resources/agents.md`.

## Output styles

`output-styles/*.md` are plain symlinks, frontmatter and all; `justin.md` is selected by `outputStyle` in `claude-code/settings.json`. An output style loads for the main session only, never for subagents, so it carries how Claude talks to Justin in the terminal and nothing else. A rule subagents also need is a rules fragment (`resources/agents.md`); the voice for artifacts is the style skill.

## Commands

`commands/*.md` are plain symlinks into `~/.claude/commands`, pruned when the source is deleted.

## Agents

`agents/*.md` are plain symlinks into `~/.claude/agents`, pruned when the source is deleted. They exist to pin a subagent's reasoning effort, which only frontmatter can set. A `model` passed to the Agent tool overrides the definition's `model`, so spawn these without one. The worker-cost rule is their only caller, so a machine with `worker-cost` in `SKIP_RULES` links none of them.

## Settings, statusline, hook

`settings.json` is merged, not linked, because Claude Code rewrites `~/.claude/settings.json` at runtime (theme, model, `/fast`). `merge_json` deep-merges the repo's tracked keys into the machine's real file, repo winning on conflicts, and leaves machine-only keys alone. `settings.local.json` (gitignored) is merged after it, so for the keys it declares local wins over repo, re-asserted every run.

`statusline-command.sh` and `herdr-session-hook.sh` are plain symlinks; Claude Code never rewrites them. settings.json wires both in by path (`statusLine`, `hooks.SessionStart`).

## Plugins

Plugins cannot be symlinked: their state in `~/.claude/plugins/` carries machine-specific absolute paths, timestamps, and pinned commit SHAs. `setup_claude_plugins` replays `claude plugin marketplace add` and `claude plugin install` from `claude-code/plugins.txt` (format in its header), skipping any the state files already show installed.

The sync uninstalls any installed plugin missing from the manifest, unless it is listed in `KEEP_PLUGINS` in `.dotfiles-local`. That list is the home for machine-only plugins the shared manifest should not know about.

`SKIP_PLUGINS` in `.dotfiles-local` is the opposite knob: a manifest plugin one machine does not want. A skipped plugin never enters the wanted set, which is also what removes it — the uninstall pass drops anything installed that nothing wants. A manifest line whose plugins are all skipped does not register its marketplace either.

- Remove a plugin everywhere: delete its manifest line, re-run `./install.sh`.
- Keep a plugin on one machine: install it by hand, add it to `KEEP_PLUGINS`.
- Drop a plugin on one machine: add it to `SKIP_PLUGINS`; every other machine keeps it.

Installed state is read from Claude Code's own JSON (`installed_plugin_ids`, `marketplace_known`) rather than the CLI. A steady-state run then makes no CLI calls at all, and a real install is reported as a change instead of assumed idempotent. Installs and uninstalls still go through the CLI.

That started as a workaround for `claude plugins list` hanging when install.sh ran inside a Claude Code session (`de0859f`). It stopped reproducing by CLI 2.1.278, checked 2026-09-21: `plugin list`, `plugin marketplace list`, `plugin uninstall`, and `plugin marketplace remove` all returned in about a second from inside a session. Running install.sh from inside a session is fine; the JSON reads are kept for speed and accuracy.
