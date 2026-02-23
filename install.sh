#!/bin/zsh

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

CURRENT_USER="$(whoami)"
IS_WORK_COMPUTER=false
[[ "$CURRENT_USER" == "juslui" ]] && IS_WORK_COMPUTER=true

# --- Dependency Installation ---
echo "Checking and installing dependencies..."

if [[ "$(uname)" == "Darwin" ]]; then
  # macOS
  if ! command_exists brew; then
    echo "Homebrew not found. Please install it first: https://brew.sh/"
    exit 1
  fi
  
  brew_packages=(git fzf zoxide tmux zsh neovim ghostty)
  for package in "${brew_packages[@]}"; do
    if ! brew list --formula | grep -q "^${package}\$"; then
      brew install "$package"
    else
      echo "$package is already installed."
    fi
  done

elif [[ -f "/etc/arch-release" ]]; then
  # Arch Linux
  if ! command_exists sudo; then
      echo "sudo is required to install packages on Arch Linux."
      exit 1
  fi
  
  pacman_packages=(git fzf zoxide tmux zsh neovim ghostty)
  # Update pacman database
  sudo pacman -Syu --noconfirm

  for package in "${pacman_packages[@]}"; do
    if ! pacman -Qs "^${package}\$" > /dev/null; then
      sudo pacman -S --noconfirm "$package"
    else
      echo "$package is already installed."
    fi
  done

else
  echo "Unsupported OS. This script supports macOS and Arch Linux."
  exit 1
fi

# --- TPM (Tmux Plugin Manager) ---
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo "Cloning Tmux Plugin Manager (tpm)..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo "Tmux Plugin Manager (tpm) is already installed."
fi


DOTFILES_DIR="${0:A:h}"

# --- Symlinking ---
echo "Backing up and creating symlinks..."

# zshrc
if [[ "$IS_WORK_COMPUTER" == true ]]; then
  echo "Work computer detected — skipping zshrc symlink."
else
  if [ -f "$HOME/.zshrc" ]; then
      mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
  fi
  ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
fi

# tmux.conf
TMUX_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
if [ ! -d "$TMUX_CONF_DIR" ]; then
  mkdir -p "$TMUX_CONF_DIR"
fi
if [ -f "$TMUX_CONF_DIR/tmux.conf" ]; then
    mv "$TMUX_CONF_DIR/tmux.conf" "$TMUX_CONF_DIR/tmux.conf.bak"
fi
ln -sf "$DOTFILES_DIR/tmux.conf" "$TMUX_CONF_DIR/tmux.conf"

# nvim
echo "Setting up Neovim configuration..."
NVIM_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

# Check if neovim is installed
if ! command_exists nvim; then
    echo "Neovim not found. Installing..."
    if [[ "$(uname)" == "Darwin" ]]; then
        brew install neovim
    elif [[ -f "/etc/arch-release" ]]; then
        sudo pacman -S --noconfirm neovim
    fi
else
    echo "Neovim is already installed."
fi

# Check if nvim config already exists and is a symlink to our dotfiles
if [ -L "$NVIM_CONF_DIR" ] && [ "$(readlink "$NVIM_CONF_DIR")" = "$DOTFILES_DIR/nvim" ]; then
    echo "Neovim configuration is already linked to dotfiles."
elif [ -d "$NVIM_CONF_DIR" ] || [ -e "$NVIM_CONF_DIR" ]; then
    echo "⚠️  Existing Neovim configuration found at $NVIM_CONF_DIR"
    echo "   Skipping nvim setup. Please back it up or remove it, then re-run this script."
else
    echo "Creating symlink for Neovim configuration..."
    ln -sf "$DOTFILES_DIR/nvim" "$NVIM_CONF_DIR"
fi

# ghostty config
if [[ "$(uname)" == "Darwin" ]]; then
  GHOSTTY_CONF_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
else
  GHOSTTY_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
fi
if [ ! -d "$GHOSTTY_CONF_DIR" ]; then
  mkdir -p "$GHOSTTY_CONF_DIR"
fi
if [ -f "$GHOSTTY_CONF_DIR/config" ]; then
    mv "$GHOSTTY_CONF_DIR/config" "$GHOSTTY_CONF_DIR/config.bak"
fi
ln -sf "$DOTFILES_DIR/ghostty/config" "$GHOSTTY_CONF_DIR/config"

echo ""
echo "✅ Dotfiles installation complete!"
echo ""
echo "Notes:"
echo "- Zsh plugins will be automatically installed the first time you open zsh."
echo "- To install tmux plugins, start tmux and press 'prefix + I' (Ctrl+b + I)."
echo "- Neovim configuration is now linked. Run 'nvim' to start using it. Also run :MasonInstallAll"
echo "- Ghostty configuration is now linked to the platform-appropriate config location."
