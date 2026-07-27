---
name: pi
description: Pi coding agent module — themes, skills, packages, settings. Use when changing pi themes, skills, extensions, packages, or settings.
---

Manages pi agent config via declarative files. All changes land here, symlinked into ~/.pi/agent/.

**Install flow** (install.sh): symlinks themes/*.json → ~/.pi/agent/themes/, symlinks skills/*/ → ~/.pi/agent/skills/, symlinks extensions/*.ts → ~/.pi/agent/extensions/, symlinks settings.json → ~/.pi/agent/settings.json, runs `pi install` for each line in packages.txt.

**Tasks:**
- Add theme: drop .json in themes/ (51-color-token schema), optionally set in settings.json, run install.sh
- Add skill: create dir under skills/ with SKILL.md, run install.sh
- Add extension: drop .ts in extensions/, run install.sh
- Add package: add line to packages.txt (npm:foo, git:github.com/user/repo), run install.sh
- Remove package: comment/delete line in packages.txt, `pi remove <source>` (install.sh never removes)

**Default voice:** none — the global rules ship to Claude Code only (`~/AGENTS.md` was dropped when the skills module went Claude Code-specific). If pi sessions need Justin's voice, add a pi-native rules sink over the same `rules.d/` fragments.
