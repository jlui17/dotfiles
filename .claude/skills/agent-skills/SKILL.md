---
name: agent-skills
description: Global agent skills & slash commands shared across coding agents — one source fanned out to ~/.claude and ~/.agents.
---

One module, many agents. `agent-skills/` holds the global skills and slash commands Justin uses everywhere, authored once and symlinked into every agent root. The intent is a single canonical set of agent capabilities — not a Claude-Code-only config — so the same skill works whether the agent reading it is Claude Code or another tool.

**Layout:**
- `agent-skills/commands/*.md` — global slash commands (one file per command).
- `agent-skills/skills/<name>/SKILL.md` — global skills (one dir per skill).
- `agent-skills/rules.d/NN-<slug>.md` — global instruction rules, one section per file (the `NN-` prefix orders them, the slug names them). install.sh assembles them into generated `~/CLAUDE.md` and `~/AGENTS.md`, skipping any slugs in this machine's `SKIP_RULES` (`.dotfiles-local`). Generated, not symlinked, because per-machine section exclusion needs a per-machine artifact. `99-local.md` is gitignored for machine-only rules.
  - **Per-output composition:** both `~/CLAUDE.md` and `~/AGENTS.md` assemble the full `rules.d/` set, then each drops the slugs in its own repo-wide skip list (`CLAUDE_MD_SKIP_RULES` / `AGENTS_MD_SKIP_RULES` in install.sh). Opt-out, so a new fragment reaches both outputs unless a list excludes it. Use it for rules specific to one agent (e.g. `orchestration` names Claude model tiers and the Task tool, so it's in `AGENTS_MD_SKIP_RULES`). This is orthogonal to the per-machine `SKIP_RULES` in `.dotfiles-local`, which subtracts from both outputs on one box.

**Why two roots:** `~/.claude` is where Claude Code discovers skills/commands; `~/.agents` is the shared root other coding agents read. Both get the identical module contents, so a capability added once is live in every agent. Adding a third agent later means adding its root to the install — not re-authoring anything.

**Install flow** (install.sh `setup_agent_skills`): for each root in `~/.claude` and `~/.agents`, symlinks every `commands/*.md` → `<root>/commands/` and every `skills/<name>/` → `<root>/skills/`. Then `assemble_global_rules` concatenates `rules.d/` (minus `SKIP_RULES`) into `~/CLAUDE.md` and `~/AGENTS.md`. Backs up existing non-symlinks. Idempotent. Add an agent root by extending the `agent_roots` array.

**Editing a rule means re-running install.sh.** The generated files don't track `rules.d/` the way the old symlink tracked `global-rules.md` — an edit lands in `~/CLAUDE.md`/`~/AGENTS.md` only after the next `./install.sh` run. Never edit the generated files directly; the next run overwrites them.

**Tasks:**
- Add a command: drop `name.md` in `agent-skills/commands/`; re-run install.sh to link into all roots.
- Add a skill: create `agent-skills/skills/<name>/SKILL.md` (+ any support files); re-run install.sh.
- Change a global rule: edit the matching `rules.d/` fragment (or add a new `NN-<slug>.md`), re-run install.sh, commit.
- Exclude a rules section on this machine: add its slug to `SKIP_RULES` in `.dotfiles-local`, re-run install.sh.
- Machine-only rules: put them in `rules.d/99-local.md` (gitignored), re-run install.sh.
- Support a new agent: append its config root to `agent_roots` in `setup_agent_skills`.
- Remove a capability: delete the file/dir; remove stale symlinks from each agent root manually (install.sh only links, never prunes).

Note: this is a **repo maintenance** skill (lives in `.agents/skills/`, describes the module). The skills *inside* `agent-skills/skills/` are the **runtime** skills that get deployed to agents.
