#!/bin/zsh

# ──────────────────────────────────────────────────────────────
#  dotfiles — install.sh
#  One script, two platforms. Clean phases, single source of
#  truth for packages, no inline function definitions.
# ──────────────────────────────────────────────────────────────

# set -euo pipefail          # opt-in; not enabled to preserve
                             # existing error-handling style

# ──────────────────────────────────────────────
#  GLOBALS & OS DETECTION
# ──────────────────────────────────────────────

DOTFILES_DIR="${0:A:h}"
CURRENT_USER="$(whoami)"
IS_WORK_COMPUTER=false
[[ "$CURRENT_USER" == "juslui" ]] && IS_WORK_COMPUTER=true

# -- OS detection -----------------------------------------------------------
OS=""
case "$(uname)" in
  Darwin) OS="macos" ;;
  Linux)
    if [[ -f /etc/arch-release ]]; then
      OS="arch"
    else
      OS="unknown"
    fi
    ;;
  *) OS="unknown" ;;
esac

# -- Platform package configuration -----------------------------------------
# Single source of truth — add new tools here, not in two places.
COMMON_PACKAGES=(git fzf zoxide tmux zsh neovim ghostty lazygit)

case "$OS" in
  macos)
    PKG_MANAGER="brew"
    PKG_INSTALL=(brew install)
    PKG_QUERY=(brew list --formula)
    PKG_UPDATE=(brew update)
    ;;
  arch)
    PKG_MANAGER="pacman"
    PKG_INSTALL=(sudo pacman -S --noconfirm)
    PKG_QUERY=(pacman -Qs)
    PKG_UPDATE=(sudo pacman -Syu --noconfirm)
    ;;
esac

# ──────────────────────────────────────────────
#  HELPERS
# ──────────────────────────────────────────────

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Run a command only when the current OS matches one of the
# comma-separated values in $1.
run_if_os() {
  local os_list="$1"
  shift
  [[ ",$os_list," == *",$OS,"* ]] && "$@"
}

ensure_dir() {
  [[ -d "$1" ]] || mkdir -p "$1"
}

# Back up an existing file (not a symlink) and symlink in its place.
backup_and_link() {
  local src="$1" dst="$2"
  if [[ -f "$dst" && ! -L "$dst" ]]; then
    echo "  Backing up existing $(basename "$dst")..."
    mv "$dst" "$dst.bak"
  fi
  ln -sf "$src" "$dst"
  echo "  Linked $(basename "$dst")."
}

# ──────────────────────────────────────────────
#  PHASE 1 — OS packages
# ──────────────────────────────────────────────

install_packages() {
  echo "==> Installing packages..."

  if [[ "$OS" == "unknown" ]]; then
    echo "Unsupported OS. This script supports macOS and Arch Linux."
    exit 1
  fi

  # Ensure the package manager itself is available
  if [[ "$OS" == "macos" ]] && ! command_exists brew; then
    echo "Homebrew not found. Install it first: https://brew.sh/"
    exit 1
  fi
  if [[ "$OS" == "arch" ]] && ! command_exists sudo; then
    echo "sudo is required to install packages on Arch Linux."
    exit 1
  fi

  echo "  Updating $PKG_MANAGER..."
  "$PKG_UPDATE[@]"

  for package in "${COMMON_PACKAGES[@]}"; do
    if "$PKG_QUERY[@]" "^${package}\$" >/dev/null 2>&1; then
      echo "  $package is already installed."
    else
      echo "  Installing $package..."
      "$PKG_INSTALL[@]" "$package"
    fi
  done
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 2 — Tmux Plugin Manager
# ──────────────────────────────────────────────

setup_tpm() {
  echo "==> Tmux Plugin Manager (tpm)..."
  TPM_DIR="$HOME/.tmux/plugins/tpm"
  if [[ -d "$TPM_DIR" ]]; then
    echo "  tpm is already installed."
  else
    echo "  Cloning tpm..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  fi
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 3 — Shell & terminal symlinks
# ──────────────────────────────────────────────

setup_zshrc() {
  echo "==> zshrc..."
  if [[ "$IS_WORK_COMPUTER" == true ]]; then
    echo "  Work computer detected — skipping zshrc symlink."
  else
    backup_and_link "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"
  fi
  echo ""
}

setup_tmux() {
  echo "==> tmux.conf..."
  local tmux_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
  ensure_dir "$tmux_dir"
  backup_and_link "$DOTFILES_DIR/tmux.conf" "$tmux_dir/tmux.conf"
  echo ""
}

setup_nvim() {
  echo "==> Neovim configuration..."
  local nvim_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

  # Safety net: ensure nvim is installed (normally handled by install_packages)
  if ! command_exists nvim; then
    echo "  Neovim not found. Installing..."
    run_if_os "macos" brew install neovim
    run_if_os "arch" sudo pacman -S --noconfirm neovim
  else
    echo "  Neovim is already installed."
  fi

  if [[ -L "$nvim_dir" && "$(readlink "$nvim_dir")" == "$DOTFILES_DIR/nvim" ]]; then
    echo "  Neovim configuration is already linked to dotfiles."
  elif [[ -d "$nvim_dir" || -e "$nvim_dir" ]]; then
    echo "  ⚠️  Existing Neovim configuration found at $nvim_dir"
    echo "     Skipping nvim setup. Please back it up or remove it, then re-run."
  else
    echo "  Creating symlink for Neovim configuration..."
    ln -sf "$DOTFILES_DIR/nvim" "$nvim_dir"
  fi
  echo ""
}

setup_ghostty() {
  echo "==> Ghostty configuration..."
  case "$OS" in
    macos)
      ghostty_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
      ;;
    *)
      ghostty_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
      ;;
  esac
  ensure_dir "$ghostty_dir"
  backup_and_link "$DOTFILES_DIR/ghostty/config" "$ghostty_dir/config"
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 4 — Omarchy (Arch Linux only)
# ──────────────────────────────────────────────

setup_omarchy() {
  if [[ "$OS" != "arch" ]]; then
    return
  fi
  echo "==> Omarchy macOS keybindings..."
  if command_exists omarchy-update; then
    local hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
    ensure_dir "$hypr_dir"

    ln -sf "$DOTFILES_DIR/omarchy/hypr/bindings-override.conf" \
           "$hypr_dir/bindings-override.conf"
    echo "  Linked bindings-override.conf."

    if ! grep -q "source = bindings-override.conf" "$hypr_dir/hyprland.conf" 2>/dev/null; then
      {
        echo ""
        echo "# macOS-style keybindings"
        echo "source = bindings-override.conf"
      } >> "$hypr_dir/hyprland.conf"
      echo "  Added source directive to hyprland.conf."
    else
      echo "  hyprland.conf already sources bindings-override.conf."
    fi
  else
    echo "  omarchy-update not found — skipping Omarchy setup."
  fi
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 5 — OpenCode
# ──────────────────────────────────────────────

setup_opencode() {
  echo "==> OpenCode configuration..."
  local opencode_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
  ensure_dir "$opencode_dir"

  if [[ -f "$opencode_dir/opencode.json" && ! -L "$opencode_dir/opencode.json" ]]; then
    echo "  Backing up existing OpenCode configuration..."
    mv "$opencode_dir/opencode.json" "$opencode_dir/opencode.json.bak"
  fi

  ln -sf "$DOTFILES_DIR/opencode/opencode.json" "$opencode_dir/opencode.json"
  echo "  Linked opencode.json."
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 6 — Pi coding agent
# ──────────────────────────────────────────────

setup_pi() {
  echo "==> Pi coding agent configuration..."
  local pi_agent_dir="$HOME/.pi/agent"

  # -- Themes ---------------------------------------------------------------
  ensure_dir "$pi_agent_dir/themes"
  for theme_file in "$DOTFILES_DIR/pi/themes/"*.json;  do
    [[ -f "$theme_file" ]] || continue
    local theme_name="$(basename "$theme_file")"
    local target="$pi_agent_dir/themes/$theme_name"
    if [[ -f "$target" && ! -L "$target" ]]; then
      echo "  Backing up existing theme: $theme_name"
      mv "$target" "$target.bak"
    fi
    ln -sf "$theme_file" "$target"
    echo "  Linked theme: $theme_name"
  done

  # -- Skills ---------------------------------------------------------------
  for skill_dir in "$DOTFILES_DIR/pi/skills/"*/; do
    [[ -d "$skill_dir" ]] || continue
    local skill_name="$(basename "$skill_dir")"
    local target="$pi_agent_dir/skills/$skill_name"
    if [[ -d "$target" && ! -L "$target" ]]; then
      echo "  Backing up existing skill: $skill_name"
      mv "$target" "$target.bak"
    fi
    ln -sfn "$skill_dir" "$target"
    echo "  Linked skill: $skill_name"
  done

  # -- Project-level settings symlink ---------------------------------------
  local pi_project_dir="$DOTFILES_DIR/.pi"
  ensure_dir "$pi_project_dir"
  ln -sf "$DOTFILES_DIR/pi/settings.json" "$pi_project_dir/settings.json"
  echo "  Linked project-level settings."

  # -- Pi packages ----------------------------------------------------------
  if command_exists pi; then
    while IFS= read -r pkg_source; do
      # Skip empty lines and comments
      [[ -z "$pkg_source" || "$pkg_source" == \#* ]] && continue
      # Trim whitespace
      pkg_source="${pkg_source## }"
      pkg_source="${pkg_source%% }"
      [[ -z "$pkg_source" ]] && continue
      echo "  Installing pi package: $pkg_source"
      pi install "$pkg_source" 2>/dev/null || echo "  ⚠️  Failed to install $pkg_source (already installed?)"
    done < "$DOTFILES_DIR/pi/packages.txt"
  else
    echo "  ⚠️  pi CLI not found. Install pi first: https://pi.dev"
    echo "     Packages to install manually:"
    while IFS= read -r pkg_source; do
      [[ -z "$pkg_source" || "$pkg_source" == \#* ]] && continue
      pkg_source="${pkg_source## }"
      pkg_source="${pkg_source%% }"
      [[ -z "$pkg_source" ]] && continue
      echo "       pi install $pkg_source"
    done < "$DOTFILES_DIR/pi/packages.txt"
  fi
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 7 — Hunk (review-first terminal diff viewer)
# ──────────────────────────────────────────────

setup_hunk() {
  echo "==> Hunk (terminal diff viewer)..."
  case "$OS" in
    macos)
      if command_exists hunk; then
        echo "  Hunk is already installed."
      else
        echo "  Tapping modem-dev/tap..."
        brew tap modem-dev/tap 2>/dev/null || true
        echo "  Installing hunk..."
        brew install hunk
      fi
      ;;
    arch)
      if command_exists hunk; then
        echo "  Hunk is already installed."
      else
        if command_exists npm; then
          echo "  Installing hunk via npm (hunkdiff)..."
          npm i -g hunkdiff
        else
          echo "  ⚠️  npm not found. Install Node.js first, then run: npm i -g hunkdiff"
        fi
      fi
      ;;
  esac
  echo ""
}

# ──────────────────────────────────────────────
#  MAIN
# ──────────────────────────────────────────────

main() {
  echo "───────────────────────────────────────"
  echo "  dotfiles — $OS ($CURRENT_USER)"
  echo "───────────────────────────────────────"
  echo ""

  install_packages
  setup_tpm
  setup_zshrc
  setup_tmux
  setup_nvim
  setup_ghostty
  setup_omarchy
  setup_opencode
  setup_pi
  setup_hunk

  echo "✅ Dotfiles installation complete!"
  echo ""
  echo "Notes:"
  echo "- Zsh plugins will be installed automatically the first time you open zsh."
  echo "- To install tmux plugins, start tmux and press prefix + I (Ctrl+b, then I)."
  echo "- Neovim: run nvim + lazy sync (or :Lazy sync) and :MasonInstallAll."
  echo "- Ghostty config is linked to the platform-appropriate path."
  echo "- Pi theme is linked. Select it in pi via /settings or edit settings.json."
}

main "$@"
