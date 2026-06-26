---
name: pi
description: Pi coding agent module — themes, skills, packages, settings.
---

Manages pi agent config via declarative files. All changes land here, symlinked into ~/.pi/agent/.

**Install flow** (install.sh): symlinks themes/*.json → ~/.pi/agent/themes/, symlinks skills/*/ → ~/.pi/agent/skills/, symlinks settings.json → .pi/settings.json, runs `pi install` for each line in packages.txt.

**Tasks:**
- Add theme: drop .json in themes/ (51-color-token schema), optionally set in settings.json, run install.sh
- Add skill: create dir under skills/ with SKILL.md, run install.sh
- Add extension: drop .ts in extensions/, run install.sh
- Add package: add line to packages.txt (npm:foo, git:github.com/user/repo), run install.sh
- Remove package: comment/delete line in packages.txt, `pi remove <source>` (install.sh never removes)

**Default voice:** pi inherits Justin's base voice from `~/AGENTS.md` (symlinked from `agent-skills/global-rules.md`); the full `voice` skill carries the per-artifact detail. No pi-specific extension.
