---
name: pi
description: Maintenance guide for the pi coding agent module at pi/. Covers structure, install.sh provisioning, and adding themes/skills/packages.
---

## Structure

```
pi/
├── package.json          # Pi manifest (discovers themes/, skills/)
├── settings.json         # Theme selection
├── packages.txt          # Declarative pi packages (one per line)
├── themes/
└── skills/
```

`.pi/settings.json` = symlink → `pi/settings.json`.

## Install Flow (in install.sh)

1. **Themes**: `pi/themes/*.json` → symlink to `~/.pi/agent/themes/`. Existing file backed up with `.bak`.
2. **Skills**: `pi/skills/*/` → symlink to `~/.pi/agent/skills/`. Existing dir backed up.
3. **Settings**: `.pi/settings.json` → symlink to `pi/settings.json`.
4. **Packages**: Each non-empty, non-`#` line in `packages.txt` → `pi install`. No pi CLI = print instructions.

## Tasks

### Add theme
1. Drop `.json` in `pi/themes/` (51 color tokens; see [schema](https://github.com/earendil-works/pi-mono/blob/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json))
2. Optionally set `"theme": "<name>"` in `pi/settings.json`
3. `./install.sh` or `ln -sf "$PWD/pi/themes/<file>.json" ~/.pi/agent/themes/`

### Add skill
1. Create dir under `pi/skills/` with `SKILL.md` ([Agent Skills spec](https://agentskills.io/specification))
2. Dir name = skill name. Lowercase, hyphens, no spaces.
3. `./install.sh` or symlink manually

### Add pi package
1. Add source to `packages.txt` (one per line, `#` for comments, e.g. `npm:foo` or `git:github.com/user/repo`)
2. `./install.sh`

### Remove pi package
1. Comment out or delete line in `packages.txt`
2. `pi remove <source>` (install.sh never removes)

## Rationale

- **No vendored extensions** — Extensions come from packages, not source files. `packages.txt` tracks declaratively.
- **Symlinks, not copies** — Changes in repo reflect immediately in `~/.pi/agent/`.
- **Project settings** — `.pi/settings.json` makes pi pick up the theme when CWD is in this repo.
