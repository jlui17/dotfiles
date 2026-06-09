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

# Machine-local config (gitignored) — holds machine-specific answers such as
# whether this is a work computer. Created on first run via a prompt; edit or
# delete it to change the answer. Never tracked in this shared repo.
DOTFILES_LOCAL_CONFIG="$DOTFILES_DIR/.dotfiles-local"
IS_WORK_COMPUTER=false

# Collects human-readable labels of steps that failed. A bootstrap script
# shouldn't abort because one package was unavailable, but it also shouldn't
# claim success when it didn't. We track failures and report them at the end
# (and exit non-zero), instead of using `set -e` — much of this script relies
# on non-zero exit codes as normal control flow (presence checks, greps).
FAILURES=()

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
COMMON_PACKAGES=(git fzf zoxide tmux zsh neovim ghostty lazygit mise tree-sitter-cli)

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

# Run a fallible command without aborting the install. On failure, record a
# human-readable label in FAILURES (surfaced in the final summary) and return
# the command's exit code so callers can branch if they want.
track() {
  local label="$1"; shift
  # `&&` (not `if`) so $? still holds the command's real exit code on failure —
  # an `if` with no `else` resets $? to 0 when the condition is false.
  "$@" && return 0
  local rc=$?
  echo "  ⚠️  $label failed (exit $rc)."
  FAILURES+=("$label")
  return $rc
}

# Resolve whether this is a work computer. Reads the gitignored local config
# if present; otherwise prompts once and persists the answer. Work computers
# skip the personal zshrc symlink.
resolve_work_computer() {
  if [[ -f "$DOTFILES_LOCAL_CONFIG" ]]; then
    source "$DOTFILES_LOCAL_CONFIG"
    return
  fi
  local response
  read -r -p "  Is this a work computer? (skips personal zshrc symlink) [y/N] " response
  [[ "$response" =~ ^[Yy]$ ]] && IS_WORK_COMPUTER=true || IS_WORK_COMPUTER=false
  {
    echo "# dotfiles machine-local config — gitignored, never committed."
    echo "# Delete this file to be prompted again on the next install."
    echo "IS_WORK_COMPUTER=$IS_WORK_COMPUTER"
  } > "$DOTFILES_LOCAL_CONFIG"
  echo "  Saved this machine's answer to ${DOTFILES_LOCAL_CONFIG:t}."
}

# Symlink src → dst, backing up whatever was there first. The single backup
# primitive for the whole installer — handles files, directories, and symlinks:
#   - already linked to src      → no-op (idempotent re-runs stay quiet)
#   - real file/dir OR foreign    → moved to dst.bak before linking
#     symlink (points elsewhere)
# Uses `ln -sfn` so an existing dst directory is replaced, not linked into.
backup_and_link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "  $(basename "$dst") already linked."
    return
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    echo "  Backing up existing $(basename "$dst")..."
    mv "$dst" "$dst.bak"
  fi
  ln -sfn "$src" "$dst"
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
  track "update $PKG_MANAGER" "$PKG_UPDATE[@]"

  for package in "${COMMON_PACKAGES[@]}"; do
    if "$PKG_QUERY[@]" "^${package}\$" >/dev/null 2>&1; then
      echo "  $package is already installed."
    else
      echo "  Installing $package..."
      track "install $package" "$PKG_INSTALL[@]" "$package"
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
    track "clone tpm" git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  fi
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 3 — Shell & terminal symlinks
# ──────────────────────────────────────────────

setup_zshrc() {
  echo "==> zshrc..."
  resolve_work_computer
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
    echo ""
    read -r -p "  Backup existing config and replace with symlink? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      local backup_dir="$DOTFILES_DIR/nvim-bak.$(date +%Y%m%d-%H%M%S)"
      echo "  Backing up to $backup_dir..."
      mv "$nvim_dir" "$backup_dir"
      echo "  Creating symlink for Neovim configuration..."
      ln -sf "$DOTFILES_DIR/nvim" "$nvim_dir"
    else
      echo "  Skipping nvim setup."
    fi
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

  backup_and_link "$DOTFILES_DIR/opencode/opencode.json" "$opencode_dir/opencode.json"
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
  for theme_file in "$DOTFILES_DIR/pi/themes/"*.json; do
    [[ -f "$theme_file" ]] || continue
    backup_and_link "$theme_file" "$pi_agent_dir/themes/$(basename "$theme_file")"
  done

  # -- Skills ---------------------------------------------------------------
  ensure_dir "$pi_agent_dir/skills"
  for skill_dir in "$DOTFILES_DIR/pi/skills/"*/; do
    [[ -d "$skill_dir" ]] || continue
    backup_and_link "${skill_dir%/}" "$pi_agent_dir/skills/$(basename "$skill_dir")"
  done

  # -- Extensions ------------------------------------------------------------
  ensure_dir "$pi_agent_dir/extensions"
  for ext_file in "$DOTFILES_DIR/pi/extensions/"*.ts; do
    [[ -f "$ext_file" ]] || continue
    backup_and_link "$ext_file" "$pi_agent_dir/extensions/$(basename "$ext_file")"
  done

  # -- Global settings ------------------------------------------------------
  # Lives at the global scope (~/.pi/agent/settings.json) so the theme and
  # other preferences apply in every project, not just the dotfiles repo.
  ensure_dir "$pi_agent_dir"
  ln -sf "$DOTFILES_DIR/pi/settings.json" "$pi_agent_dir/settings.json"
  echo "  Linked global pi settings."

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
      # Show real errors (no 2>/dev/null) and record genuine failures rather
      # than assuming every failure means "already installed."
      track "pi package $pkg_source" pi install "$pkg_source"
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
#  PHASE 7 — Global gitignore
# ──────────────────────────────────────────────

setup_gitignore() {
  echo "==> Global gitignore..."
  local git_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/git"
  ensure_dir "$git_config_dir"
  backup_and_link "$DOTFILES_DIR/gitignore/ignore" "$git_config_dir/ignore"
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 8 — Raycast (macOS only)
# ──────────────────────────────────────────────

setup_raycast() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi
  echo "==> Raycast..."
  if brew list --cask raycast >/dev/null 2>&1; then
    echo "  Raycast is already installed."
  else
    echo "  Installing Raycast..."
    brew install --cask raycast
  fi
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 9 — AltTab (macOS only)
# ──────────────────────────────────────────────

setup_alttab() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi
  echo "==> AltTab..."
  if brew list --cask alt-tab >/dev/null 2>&1; then
    echo "  AltTab is already installed."
  else
    echo "  Installing AltTab..."
    brew install --cask alt-tab
  fi
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 10 — macOS defaults
# ──────────────────────────────────────────────

setup_macos_defaults() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi
  echo "==> macOS defaults..."

  # Dock: auto-hide, no delay before showing, fast animation.
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock autohide-time-modifier -float 0.1
  killall Dock 2>/dev/null || true
  echo "  Dock set to auto-hide with 0.1s animation."
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 11 — Zed IDE
# ──────────────────────────────────────────────

setup_zed() {
  echo "==> Zed IDE..."
  case "$OS" in
    macos)
      if brew list --cask zed >/dev/null 2>&1; then
        echo "  Zed is already installed."
      else
        echo "  Installing Zed..."
        brew install --cask zed
      fi
      ;;
    arch)
      if command_exists zed; then
        echo "  Zed is already installed."
      else
        echo "  Installing Zed..."
        sudo pacman -S --noconfirm zed
      fi
      ;;
  esac
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 12 — 1Password CLI
# ──────────────────────────────────────────────

setup_op() {
  echo "==> 1Password CLI (op)..."
  if command_exists op; then
    echo "  op is already installed."
    echo ""
    return
  fi
  case "$OS" in
    macos)
      echo "  Installing 1password-cli..."
      brew install --cask 1password-cli
      ;;
    arch)
      if command_exists yay; then
        echo "  Installing 1password-cli via yay (AUR)..."
        yay -S --noconfirm 1password-cli
      elif command_exists paru; then
        echo "  Installing 1password-cli via paru (AUR)..."
        paru -S --noconfirm 1password-cli
      else
        echo "  ⚠️  No AUR helper found (yay/paru). Install manually:"
        echo "     https://developer.1password.com/docs/cli/get-started/#install"
      fi
      ;;
  esac
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 13 — Hunk (review-first terminal diff viewer)
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
  setup_gitignore
  setup_raycast
  setup_alttab
  setup_macos_defaults
  setup_zed
  setup_op
  setup_hunk

  if (( ${#FAILURES[@]} )); then
    echo "⚠️  Dotfiles installation finished with ${#FAILURES[@]} issue(s):"
    for f in "${FAILURES[@]}"; do
      echo "   - $f"
    done
  else
    echo "✅ Dotfiles installation complete!"
  fi
  echo ""
  echo "Notes:"
  echo "- Zsh plugins will be installed automatically the first time you open zsh."
  echo "- To install tmux plugins, start tmux and press prefix + I (Ctrl+b, then I)."
  echo "- Neovim: open nvim and wait for vim.pack to install plugins, then run :checkhealth."
  echo "- Ghostty config is linked to the platform-appropriate path."
  echo "- Pi theme is linked. Select it in pi via /settings or edit settings.json."

  # Non-zero exit if anything failed, so callers/CI can detect a partial install.
  (( ${#FAILURES[@]} == 0 ))
}

main "$@"
