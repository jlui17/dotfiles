# Dotfiles

Canonical config source. Single setup across macOS (Homebrew) and Arch Linux (Pacman). All coding/terminal config changes go here.

## Principles

- **Canonical**: This repo is the source of truth. Every config change lands here first, then propagates via install.sh.
- **Cross-platform**: Single `install.sh` detects OS → picks right package manager.
- **Symlinks**: Configs symlinked from repo → standard paths. No copies.
- **Declarative**: Package lists and manifests over imperative scripts.
- **Minimal friction**: Plugin managers auto-install. One command setup.
- **Durable docs**: Docs capture intent, patterns, and design decisions — not file trees or config values that agents can read directly.

## Design

- `install.sh` — OS detection → packages → symlinks → plugin managers. Each section idempotent.
- Module dirs — Each subsystem owns a directory at repo root. Single-file configs (`zshrc`, `tmux.conf`) live at root.
- Agent skills — Each module has a maintenance skill under `.agents/skills/` with structure, install flow, and common tasks.

## Rules

- New module: create dir at repo root, add symlink + deps to `install.sh`.
- Names: lowercase, hyphens, no spaces.
- Symlinks: use XDG paths (`~/.config/`). Backup existing files before replacing.
- Test: new shell for zsh, new tmux session for tmux, manual for other tools.
- Run `./install.sh` to bootstrap or update.

## Skills

Each module has a maintenance skill under `.agents/skills/<name>/SKILL.md`. Agents discover them automatically — no need to list them here.
