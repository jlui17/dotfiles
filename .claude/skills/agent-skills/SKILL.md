---
name: agent-skills
description: Maintains the agent-skills module: Justin's global Claude Code setup — skills, slash commands, rules.d/ instruction fragments, and the output style, deployed to ~/.claude. Use when adding or editing a global skill, slash command, CLAUDE.md rule, or the output style.
---

One module, one consumer: Claude Code. `agent-skills/` holds the global skills, slash commands, and instruction rules Justin uses in every Claude Code session, deployed to `~/.claude`. Other harnesses get their own modules with harness-native config (`pi/`, `opencode/`); if one later needs the shared rules, add a sink over the same `rules.d/` fragments (the deleted `~/AGENTS.md` assembly in git history is the template) rather than a parallel rules source.

**Layout:**
- `agent-skills/commands/*.md` — global slash commands (one file per command), symlinked into `~/.claude/commands/`.
- `agent-skills/skills/<name>/SKILL.md` — global skills (one dir per skill), symlinked into `~/.claude/skills/`.
- `agent-skills/rules.d/NN-<slug>.md` — global instruction rules, one section per file (the `NN-` prefix orders them, the slug names them). install.sh assembles them into the generated `~/CLAUDE.md`, skipping any slugs in this machine's `SKIP_RULES` (`.dotfiles-local`). Generated, not symlinked, because per-machine section exclusion needs a per-machine artifact. `99-local.md` is gitignored for machine-only rules.
- The voice-core fragments listed in `OUTPUT_STYLE_RULES` (install.sh) are additionally assembled into the Claude Code output style `~/.claude/output-styles/justin.md`, selected via `outputStyle` in `claude-code/settings.json`. `~/CLAUDE.md` keeps its copy of the same fragments because subagents load CLAUDE.md but never see output styles.

**Install flow** (install.sh `setup_agent_skills`): symlinks `commands/*.md` and `skills/<name>/` into `~/.claude`, then regenerates `~/CLAUDE.md` and the output style. Backs up existing non-symlinks; idempotent. Skills named in this machine's `SKIP_SKILLS` (`.dotfiles-local`) are not linked — like `SKIP_RULES` but for whole skills; removing an already-linked skill from a machine also means deleting its symlink from `~/.claude/skills` manually (install.sh never prunes).

**Editing a rule means re-running install.sh.** Edits to `rules.d/` reach `~/CLAUDE.md` and the output style only on the next `./install.sh` run (generated, not symlinked). Never edit the generated files directly; the next run overwrites them.

**Tasks:**
- Any add/edit (command, skill, rule fragment) lands by re-running `./install.sh`.
- Remove a capability: delete the file/dir; remove the stale symlink from `~/.claude` manually (install.sh only links, never prunes).

Note: this is a **repo maintenance** skill (lives in `.claude/skills/`, describes the module). The skills *inside* `agent-skills/skills/` are the **runtime** skills that get deployed.
