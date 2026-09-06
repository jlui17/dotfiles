# Claude Code

Owns what only Claude Code reads: commands, `rules.d/`, output styles, external skills, settings, statusline, the herdr hook, and plugins. `setup_claude_code` runs `setup_claude_code_skills` then `setup_claude_plugins`. Global skills are not here; see `resources/agents.md`.

## Global rules

"Update my global CLAUDE.md" means editing a fragment in `claude-code/rules.d/`. `assemble_global_rules` concatenates `NN-<slug>.md` files in filename order into a generated `~/CLAUDE.md`; the `NN-` prefix orders, the slug is what `SKIP_RULES` in `.dotfiles-local` names. Generated rather than symlinked because per-machine section exclusion needs a per-machine artifact; a symlink is all or nothing. Consequences:

- An edit reaches `~/CLAUDE.md` only on the next `./install.sh`.
- A direct edit to `~/CLAUDE.md` is overwritten on the next run (the file's header says so).
- `99-local.md` is gitignored and rides along for machine-only rules.
- `assemble_global_rules` warns when the generated file passes its line budget; the number lives there. Past it, distill a fragment or push detail into a skill.

The shared rules ship to Claude Code only. Codex and OpenCode read none of them; a rule written here binds Claude Code sessions alone. A harness that later needs them gets its own sink over the same `rules.d/` fragments, never a second rules source.

## Output styles

`output-styles/*.md` are plain symlinks, frontmatter and all; `justin.md` is selected by `outputStyle` in `claude-code/settings.json`. An output style loads for the main session only, never for subagents. That is why the voice and session-reply rules live in the style: they govern how Claude talks to Justin in the terminal. A rule subagents also need is a `rules.d/` fragment, not a style section.

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
