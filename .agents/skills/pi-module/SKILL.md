---
name: pi-module
description: Maintenance guide for the pi coding agent module in this dotfiles repo. Covers the module structure at pi/, how installation works, and how to add themes, skills, and packages.
---

# Pi Module Maintenance

This repo contains a pi coding agent module at `pi/` — a self-contained bundle of themes, skills, and a declarative package list that provisions the user's `~/.pi/agent` setup.

## Module Structure

```
pi/
├── package.json             # Pi package manifest (discovers themes/, skills/)
├── settings.json            # Project-level config (selects theme)
├── packages.txt             # Declarative list of pi packages (one per line)
├── themes/
│   └── github-dark-default.json
└── skills/
    └── helium/
        └── SKILL.md
```

Project-local pi config is at `.pi/settings.json` (symlink to `pi/settings.json`).

## How Installation Works

The `install.sh` script handles pi provisioning inside its "Pi Coding Agent" section:

1. **Themes** — Each `.json` file in `pi/themes/` is symlinked to `~/.pi/agent/themes/`. If a regular file already exists at the destination, it gets backed up with a `.bak` suffix before replacement.
2. **Skills** — Each directory under `pi/skills/` is symlinked to `~/.pi/agent/skills/`. Existing non-symlink directories are backed up.
3. **Project settings** — `.pi/settings.json` is symlinked to `pi/settings.json` so pi discovers the theme selection when working in this repo.
4. **Packages** — Each non-empty, non-comment line in `packages.txt` is installed via `pi install`. If the pi CLI is not found, instructions are printed instead.

## Maintenance Tasks

### Add a new theme

1. Drop a `.json` file into `pi/themes/` (see [pi theme format](https://github.com/earendil-works/pi-mono/blob/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json) for the required 51 color tokens)
2. Optionally update `pi/settings.json` to set `"theme": "your-theme-name"` (the `name` field in the JSON file)
3. Re-run `./install.sh` to symlink it, or symlink manually: `ln -sf "$PWD/pi/themes/your-theme.json" ~/.pi/agent/themes/`

### Add a new skill

1. Create a directory under `pi/skills/` with a `SKILL.md` (see [Agent Skills spec](https://agentskills.io/specification))
2. The directory name becomes the skill name — use lowercase, hyphens, no spaces
3. Re-run `./install.sh` to symlink it, or symlink manually

### Add an npm/git pi package

1. Add the package source to `pi/packages.txt` (one line per source, e.g. `npm:some-package` or `git:github.com/user/repo`)
2. Lines starting with `#` are ignored (use for comments)
3. Re-run `./install.sh` to install it

### Remove a pi package

1. Delete or comment out its line in `pi/packages.txt`
2. Run `pi remove <source>` manually to uninstall it (install.sh only installs, never removes)

## Design Rationale

- **No vendored extensions** — Extensions come from installed packages, not source files in this repo. The `packages.txt` file tracks what to install declaratively, avoiding fork maintenance and merge conflicts.
- **Symlinks, not copies** — Themes and skills are symlinked so updates to this repo are reflected immediately in `~/.pi/agent/` without re-running the install script every time.
- **Project settings** — `.pi/settings.json` makes pi pick up the theme automatically when working in this directory.
