# AGENTS.md

## Project Overview
Personal dotfiles repository for shell and terminal configuration across macOS and Arch Linux.

## Project Structure
- `install.sh` - Cross-platform installation script with dependency management
- `zshrc` - Zsh configuration with plugin management via Zinit
- `tmux.conf` - Tmux configuration with plugin management via TPM
- `pi/` - Pi coding agent module (themes, skills, package list, project settings)
  - `themes/` - Theme JSON files (e.g. github-dark-default)
  - `skills/` - Local skill definitions (e.g. helium browser skill)
  - `packages.txt` - Declarative list of pi packages to install via CLI
  - `settings.json` - Project-local pi config (symlinked to .pi/settings.json)
  - `package.json` - Pi package manifest for auto-discovery

## Key Patterns
- **Installation**: Single script handles OS detection and package management
- **Symlinking**: Configs are symlinked from repo to standard locations
- **Plugin Management**: Auto-installation of plugin managers (Zinit, TPM)
- **Cross-platform**: Supports both Homebrew (macOS) and Pacman (Arch Linux)
- **Pi Module**: Declarative package list in `pi/packages.txt`; themes and skills symlinked to `~/.pi/agent/`

## Testing Approach
No automated tests. Manual verification:
- New shell session for zsh changes
- New tmux session for tmux changes
- Check plugin functionality after installation

## Common Operations
- **Install/Update**: `./install.sh`
- **Test zsh config**: Start new shell or `source ~/.zshrc`
- **Test tmux config**: `tmux source-file ~/.config/tmux/tmux.conf`
- **Install tmux plugins**: `prefix + I` in tmux session
- **Select pi theme**: Theme is set from `.pi/settings.json`, or change it via `/settings` in pi
- **Install pi packages**: Read `pi/packages.txt` and run `pi install <source>` for each
- **Reload pi config**: Run `/reload` in pi or just restart