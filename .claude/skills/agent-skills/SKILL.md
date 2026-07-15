---
name: agent-skills
description: Maintains the agent-skills module: global skills, slash commands, and rules.d/ instruction fragments shared across coding agents, fanned out from one source to ~/.claude and ~/.agents. Use when adding or editing a global skill, slash command, or CLAUDE.md/AGENTS.md rule, or when wiring up a new agent root.
---

One module, many agents. `agent-skills/` holds the global skills and slash commands Justin uses everywhere, authored once and symlinked into every agent root: `~/.claude` is where Claude Code discovers skills/commands, `~/.agents` is the shared root other coding agents read. Both get the identical module contents — a single canonical set of agent capabilities, not a Claude-Code-only config — and supporting another agent means adding its root to the install, not re-authoring anything.

**Layout:**
- `agent-skills/commands/*.md` — global slash commands (one file per command).
- `agent-skills/skills/<name>/SKILL.md` — global skills (one dir per skill).
- `agent-skills/rules.d/NN-<slug>.md` — global instruction rules, one section per file (the `NN-` prefix orders them, the slug names them). install.sh assembles them into generated `~/CLAUDE.md` and `~/AGENTS.md`, skipping any slugs in this machine's `SKIP_RULES` (`.dotfiles-local`). Generated, not symlinked, because per-machine section exclusion needs a per-machine artifact. `99-local.md` is gitignored for machine-only rules.
  - **Per-output composition:** both `~/CLAUDE.md` and `~/AGENTS.md` assemble the full `rules.d/` set, then each drops the slugs in its own repo-wide skip list (`CLAUDE_MD_SKIP_RULES` / `AGENTS_MD_SKIP_RULES` in install.sh). Opt-out, so a new fragment reaches both outputs unless a list excludes it. Use it for rules specific to one agent (e.g. `orchestration` names Claude model tiers and the Task tool, so it's in `AGENTS_MD_SKIP_RULES`). This is orthogonal to the per-machine `SKIP_RULES` in `.dotfiles-local`, which subtracts from both outputs on one box.

**Install flow** (install.sh `setup_agent_skills`): symlinks `commands/*.md` and `skills/<name>/` into each root in `agent_roots`, then `assemble_global_rules` regenerates both rules files. Backs up existing non-symlinks; idempotent.

**Editing a rule means re-running install.sh.** Edits to `rules.d/` reach `~/CLAUDE.md` and `~/AGENTS.md` only on the next `./install.sh` run (generated, not symlinked). Never edit the generated files directly; the next run overwrites them.

**Tasks:**
- Any add/edit (command, skill, rule fragment) lands by re-running `./install.sh`.
- Remove a capability: delete the file/dir; remove stale symlinks from each agent root manually (install.sh only links, never prunes).
- Support a new agent: append its config root to `agent_roots` in `setup_agent_skills`.

Note: this is a **repo maintenance** skill (lives in `.agents/skills/`, describes the module). The skills *inside* `agent-skills/skills/` are the **runtime** skills that get deployed to agents.
