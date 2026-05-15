# Dotfiles

Canonical config source. Single setup across macOS (Homebrew) and Arch Linux (Pacman). All coding/terminal config changes go here.

## Principles

- **Canonical**: This repo is the source of truth. Every config change lands here first, then propagates via install.sh.
- **Cross-platform**: Single `install.sh` detects OS → picks right package manager.
- **Symlinks**: Configs symlinked from repo → standard paths. No copies.
- **Declarative**: Package lists and manifests over imperative scripts.
- **Minimal friction**: Plugin managers auto-install. One command setup.

## Design

- `install.sh` — OS detection → packages → symlinks → plugin managers. Each section idempotent.
- Module dirs — Each subsystem owns a directory (`pi/`, `nvim/`, `opencode/`, `ghostty/`, `omarchy/`, `zsh-functions/`).
- Root files — `zshrc`, `tmux.conf`. Single-file configs documented here.

## Rules

- New module: create dir at repo root, add symlink + deps to `install.sh`.
- Names: lowercase, hyphens, no spaces.
- Symlinks: use XDG paths (`~/.config/`). Backup existing files before replacing.
- Test: new shell for zsh, new tmux session for tmux, manual for other tools.
- Run `./install.sh` to bootstrap or update.

## Root-level Configs

### `install.sh`
Cross-platform installer. Detects OS, installs packages, symlinks configs, provisions plugin managers.

### `zshrc`
Zsh with Zinit plugin manager. Reload: new shell or `source ~/.zshrc`.

### `tmux.conf`
Tmux with TPM plugin manager. Reload: new session or `tmux source-file ~/.config/tmux/tmux.conf`. Install plugins: `prefix + I`.
