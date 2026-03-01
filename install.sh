#!/bin/zsh

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# OS Detection
OS=""

detect_os() {
    if [[ "$(uname)" == "Darwin" ]]; then
        OS="macos"
    elif [[ -f "/etc/arch-release" ]]; then
        OS="arch"
    else
        OS="unknown"
    fi
}

# Run command if current OS is in the comma-separated list
run_if_os() {
    local os_list="$1"
    shift
    [[ ",$os_list," == *",$OS,"* ]] && "$@"
}

CURRENT_USER="$(whoami)"
IS_WORK_COMPUTER=false
[[ "$CURRENT_USER" == "juslui" ]] && IS_WORK_COMPUTER=true

# Detect OS early
detect_os

# --- Dependency Installation ---
echo "Checking and installing dependencies..."

# macOS package installation
run_if_os "macos" check_brew_and_install

check_brew_and_install() {
    if ! command_exists brew; then
        echo "Homebrew not found. Please install it first: https://brew.sh/"
        exit 1
    fi
    
    brew_packages=(git fzf zoxide tmux zsh neovim ghostty lazygit)
    for package in "${brew_packages[@]}"; do
        if ! brew list --formula | grep -q "^${package}\$"; then
            brew install "$package"
        else
            echo "$package is already installed."
        fi
    done
}

# Arch Linux package installation  
run_if_os "arch" check_sudo_and_install

check_sudo_and_install() {
    if ! command_exists sudo; then
        echo "sudo is required to install packages on Arch Linux."
        exit 1
    fi
    
    pacman_packages=(git fzf zoxide tmux zsh neovim ghostty lazygit)
    sudo pacman -Syu --noconfirm

    for package in "${pacman_packages[@]}"; do
        if ! pacman -Qs "^${package}\$" > /dev/null; then
            sudo pacman -S --noconfirm "$package"
        else
            echo "$package is already installed."
        fi
    done
}

# Handle unsupported OS
run_if_os "unknown" unsupported_os

unsupported_os() {
    echo "Unsupported OS. This script supports macOS and Arch Linux."
    exit 1
}

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
    run_if_os "macos" brew install neovim
    run_if_os "arch" sudo pacman -S --noconfirm neovim
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
set_ghostty_dir() {
    if [[ "$OS" == "macos" ]]; then
        echo "$HOME/Library/Application Support/com.mitchellh.ghostty"
    else
        echo "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
    fi
}
GHOSTTY_CONF_DIR=$(set_ghostty_dir)
if [ ! -d "$GHOSTTY_CONF_DIR" ]; then
  mkdir -p "$GHOSTTY_CONF_DIR"
fi
if [ -f "$GHOSTTY_CONF_DIR/config" ]; then
    mv "$GHOSTTY_CONF_DIR/config" "$GHOSTTY_CONF_DIR/config.bak"
fi
ln -sf "$DOTFILES_DIR/ghostty/config" "$GHOSTTY_CONF_DIR/config"

# --- Omarchy Setup (macOS keybindings) ---
setup_omarchy_keybindings() {
    if command_exists omarchy-update; then
        echo "Omarchy detected - setting up macOS keybindings..."
        
        # Ensure hypr config directory exists
        HYPR_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
        mkdir -p "$HYPR_CONF_DIR"
        
        # Symlink macOS bindings override file
        ln -sf "$DOTFILES_DIR/omarchy/hypr/bindings-override.conf" "$HYPR_CONF_DIR/bindings-override.conf"
        
        # Ensure bindings-override.conf is sourced in hyprland.conf
        if ! grep -q "source = bindings-override.conf" "$HYPR_CONF_DIR/hyprland.conf"; then
            echo "" >> "$HYPR_CONF_DIR/hyprland.conf"
            echo "# macOS-style keybindings" >> "$HYPR_CONF_DIR/hyprland.conf"
            echo "source = bindings-override.conf" >> "$HYPR_CONF_DIR/hyprland.conf"
        fi
        
        echo "macOS keybindings configured for Omarchy."
    fi
}
run_if_os "arch" setup_omarchy_keybindings

echo ""
echo "✅ Dotfiles installation complete!"
echo ""
echo "Notes:"
echo "- Zsh plugins will be automatically installed the first time you open zsh."
echo "- To install tmux plugins, start tmux and press 'prefix + I' (Ctrl+b + I)."
echo "- Neovim configuration is now linked. Run 'nvim' to start using it. Also run :MasonInstallAll"
echo "- Ghostty configuration is now linked to the platform-appropriate config location."
