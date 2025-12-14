# AGENTS.md

## Project Overview
Personal dotfiles repository for shell and terminal configuration across macOS and Arch Linux.

## Project Structure
- `install.sh` - Cross-platform installation script with dependency management
- `zshrc` - Zsh configuration with plugin management via Zinit
- `tmux.conf` - Tmux configuration with plugin management via TPM

## Key Patterns
- **Installation**: Single script handles OS detection and package management
- **Symlinking**: Configs are symlinked from repo to standard locations
- **Plugin Management**: Auto-installation of plugin managers (Zinit, TPM)
- **Cross-platform**: Supports both Homebrew (macOS) and Pacman (Arch Linux)

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