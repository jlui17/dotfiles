#!/bin/zsh

DOTFILES_DIR="$HOME/src/dotfiles"

# Create symlinks
ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/tmux.conf" "$XDG_CONFIG_HOME/tmux/tmux.conf"

echo "Dotfiles installed!"
