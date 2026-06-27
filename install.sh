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
SCRIPT_ARGS=("$@")

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

# GUI / extra tools that aren't simple cross-platform CLI packages. Declarative
# table — add a row, no new function or main() wiring needed.
#   name | check (is it installed?) | macOS install | Arch install
# An empty install cell means "not available on that OS" (skipped). Arch AUR
# installs use yay, which Omarchy ships by default.
GUI_APPS=(
  "Raycast|brew list --cask raycast|brew install --cask raycast|"
  "AltTab|brew list --cask alt-tab|brew install --cask alt-tab|"
  "Zed|command -v zed|brew install --cask zed|sudo pacman -S --noconfirm zed"
  "1Password CLI|command -v op|brew install --cask 1password-cli|yay -S --noconfirm 1password-cli"
  "Hunk|command -v hunk|brew tap modem-dev/tap 2>/dev/null; brew install hunk|npm i -g hunkdiff"
  "OpenCode|command -v opencode|brew install opencode|"
  "Pi|command -v pi|brew install pi-coding-agent|"
)

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

  # Ensure the package manager itself is available. On macOS we bootstrap
  # Homebrew when missing, then load it into this run's PATH so the package
  # installs below can see it (Apple Silicon and Intel use different prefixes).
  if [[ "$OS" == "macos" ]] && ! command_exists brew; then
    echo "  Homebrew not found. Installing..."
    track "install Homebrew" /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      [[ -x "$brew_bin" ]] && eval "$("$brew_bin" shellenv)" && break
    done
    if ! command_exists brew; then
      echo "Homebrew installation failed. Install it manually: https://brew.sh/"
      exit 1
    fi
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
#  PHASE 1b — mise global runtimes
# ──────────────────────────────────────────────

# Python toolchain version. No true Python LTS exists; 3.12 is the broad-compat
# stable line. Used by both providers (uv pin / mise tool version).
MISE_PYTHON_VERSION="3.12"

# Link the shared runtime manifest and realize it. Without global node/go,
# nvim's Mason can't build the servers it auto-installs (gopls needs Go; ts_ls
# and pyright need Node).
#
# Python is machine-local. PYTHON_PROVIDER in .dotfiles-local picks the strategy:
#   uv     (default) — mise installs uv; uv owns Python (install + global pin).
#   system           — OS package manager installs Python (brew/pacman). For
#                      locked-down machines whose security policy SIGKILLs
#                      Astral's standalone binaries — that's both the uv binary
#                      AND mise's own Python (mise uses python-build-standalone),
#                      so on those machines neither uv nor mise-managed Python
#                      can run; the notarized Homebrew/pacman build does.
# The uv provider writes a conf.d/ overlay that mise merges on top of the shared
# config, keeping the committed manifest machine-agnostic. `mise exec` resolves
# uv without depending on mise shims being on PATH here. pyright/ts_ls/gopls are
# Node/Go-based, so nvim's LSP works under either provider.
setup_mise() {
  echo "==> mise global runtimes..."
  local mise_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
  ensure_dir "$mise_dir"
  backup_and_link "$DOTFILES_DIR/mise/config.toml" "$mise_dir/config.toml"

  local python_provider="uv"
  [[ -f "$DOTFILES_LOCAL_CONFIG" ]] && source "$DOTFILES_LOCAL_CONFIG"
  [[ -n "$PYTHON_PROVIDER" ]] && python_provider="$PYTHON_PROVIDER"
  echo "  Python provider: $python_provider."

  # uv → add uv to mise via overlay; system → no mise-managed Python at all.
  ensure_dir "$mise_dir/conf.d"
  local overlay="$mise_dir/conf.d/dotfiles-python.toml"
  if [[ "$python_provider" == "uv" ]]; then
    printf '# Generated by dotfiles install.sh — machine-local Python provider.\n[tools]\nuv = "latest"\n' \
      > "$overlay"
  else
    rm -f "$overlay"
  fi

  if ! command_exists mise; then
    echo "  ⚠️  mise not found — skipping global runtime install."
    echo ""
    return
  fi

  [[ "$python_provider" == "uv" ]] && echo "  Installing mise tools (node, go, uv)..." \
                                   || echo "  Installing mise tools (node, go)..."
  track "mise install" mise install

  case "$python_provider" in
    uv)
      echo "  Installing Python $MISE_PYTHON_VERSION via uv..."
      track "uv python install" mise exec -- uv python install "$MISE_PYTHON_VERSION"
      track "uv python pin" mise exec -- uv python pin --global "$MISE_PYTHON_VERSION"
      ;;
    system)
      echo "  Installing Python $MISE_PYTHON_VERSION via OS package manager..."
      run_if_os "macos" track "brew python@$MISE_PYTHON_VERSION" brew install "python@$MISE_PYTHON_VERSION"
      run_if_os "arch" track "pacman python" sudo pacman -S --noconfirm python
      ;;
  esac
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
#  PHASE 6b — Agent skills & commands
# ──────────────────────────────────────────────

# Fan the agent-skills module out to every agent root. ~/.claude wires up
# Claude Code; ~/.agents wires up other coding agents that read the same
# layout. Same source, multiple consumers — add a root here and it inherits
# the whole module.
setup_agent_skills() {
  echo "==> Agent skills & commands..."
  local module_dir="$DOTFILES_DIR/agent-skills"
  local agent_roots=("$HOME/.claude" "$HOME/.agents")
  local root

  for root in "${agent_roots[@]}"; do
    local commands_dir="$root/commands"
    ensure_dir "$commands_dir"
    for cmd_file in "$module_dir/commands/"*.md; do
      [[ -f "$cmd_file" ]] || continue
      backup_and_link "$cmd_file" "$commands_dir/$(basename "$cmd_file")"
    done

    local skills_dir="$root/skills"
    ensure_dir "$skills_dir"
    for skill_dir in "$module_dir/skills/"*/; do
      [[ -d "$skill_dir" ]] || continue
      backup_and_link "${skill_dir%/}" "$skills_dir/$(basename "$skill_dir")"
    done
  done

  # One canonical rules file, surfaced under both names agents look for in $HOME.
  backup_and_link "$module_dir/global-rules.md" "$HOME/CLAUDE.md"
  backup_and_link "$module_dir/global-rules.md" "$HOME/AGENTS.md"
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 6c — Claude Code config
# ──────────────────────────────────────────────

# settings.json links like any other config. Plugins can't be linked — their
# on-disk state carries machine-specific paths and pinned commit SHAs — so we
# replay the marketplace+install commands from the manifest; both no-op cleanly
# when the plugin is already present.
setup_claude_plugins() {
  echo "==> Claude Code config..."

  # User-level settings.json is the shareable layer (machine-specific or secret
  # values belong in the gitignored settings.local.json). Link it like any other
  # config; plugins below can't be linked and are replayed instead.
  backup_and_link "$DOTFILES_DIR/claude-code/settings.json" "$HOME/.claude/settings.json"

  local manifest="$DOTFILES_DIR/claude-code/plugins.txt"

  if ! command_exists claude; then
    echo "  ⚠️  claude CLI not found — skipping. Install Claude Code and re-run."
    echo "     Plugins are declared in claude-code/plugins.txt."
    echo ""
    return
  fi

  # Collect wanted plugins from manifest.
  local -a wanted_plugins=()
  local line repo plugin
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    repo="${line%%[[:space:]]*}"
    for plugin in ${=line#$repo}; do
      wanted_plugins+=("$plugin")
    done
  done < "$manifest"

  # Uninstall plugins present on this machine but removed from the manifest.
  local installed
  while IFS= read -r installed; do
    [[ -z "$installed" ]] && continue
    if (( ! ${wanted_plugins[(Ie)$installed]} )); then
      echo "  Uninstalling removed plugin: $installed"
      track "claude plugins uninstall $installed" claude plugins uninstall "$installed"
    fi
  done < <(claude plugins list 2>/dev/null | awk '/❯/{print $NF}')

  # Install/no-op wanted plugins.
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    repo="${line%%[[:space:]]*}"          # first token: the marketplace repo
    echo "  Adding marketplace: $repo"
    track "claude marketplace $repo" claude plugin marketplace add "$repo"
    for plugin in ${=line#$repo}; do      # remaining tokens: plugin@marketplace
      echo "  Installing plugin: $plugin"
      track "claude plugin $plugin" claude plugin install "$plugin"
    done
  done < "$manifest"
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
#  PHASE 7b — Git user config & personal identity
# ──────────────────────────────────────────────

setup_git_config() {
  echo "==> Git user config..."
  local git_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/git"
  ensure_dir "$git_config_dir"
  local git_config="$git_config_dir/config"
  local git_config_personal="$git_config_dir/config-personal"

  ensure_dir "$HOME/src/personal"

  if [[ ! -f "$git_config" ]]; then
    local primary_email
    read -r -p "  Primary git email: " primary_email
    cat > "$git_config" <<EOF
[user]
	name = Justin Lui
	email = $primary_email

[includeIf "gitdir:~/src/personal/"]
	path = ~/.config/git/config-personal
EOF
    echo "  Created $git_config."
  else
    echo "  $git_config already exists — skipping."
  fi

  if [[ ! -f "$git_config_personal" ]]; then
    local personal_email
    read -r -p "  Personal git email (for ~/src/personal/): " personal_email
    printf '[user]\n\temail = %s\n' "$personal_email" > "$git_config_personal"
    echo "  Created config-personal."
  else
    echo "  config-personal already exists — skipping."
  fi

  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 8 — GUI / extra apps (declarative table)
# ──────────────────────────────────────────────

setup_apps() {
  echo "==> GUI apps..."
  for row in "${GUI_APPS[@]}"; do
    local name check macos_cmd arch_cmd
    IFS='|' read -r name check macos_cmd arch_cmd <<< "$row"
    local cmd
    case "$OS" in
      macos) cmd="$macos_cmd" ;;
      arch)  cmd="$arch_cmd" ;;
    esac
    [[ -z "$cmd" ]] && continue          # not available on this OS
    if eval "$check" >/dev/null 2>&1; then
      echo "  $name already installed."
    else
      echo "  Installing $name..."
      track "install $name" eval "$cmd"
    fi
  done
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 9 — macOS defaults
# ──────────────────────────────────────────────

setup_macos_defaults() {
  if [[ "$OS" != "macos" ]]; then
    return
  fi
  echo "==> macOS defaults..."

  killall Dock 2>/dev/null || true
}

# ──────────────────────────────────────────────
#  MAIN
# ──────────────────────────────────────────────

maybe_relocate_dotfiles() {
  local desired="$HOME/src/personal/dotfiles"
  [[ "$DOTFILES_DIR" == "$desired" ]] && return

  echo "==> Dotfiles at $DOTFILES_DIR, expected $desired. Relocating..."

  if [[ -e "$desired" ]]; then
    echo "  ERROR: $desired already exists. Move or remove it, then re-run."
    exit 1
  fi

  ensure_dir "$HOME/src/personal"
  mv "$DOTFILES_DIR" "$desired"
  echo "  Moved to $desired."

  local old="$DOTFILES_DIR"
  find "$HOME" -maxdepth 6 -type l 2>/dev/null | while read -r link; do
    local target
    target=$(readlink "$link")
    if [[ "$target" == "$old"* ]]; then
      ln -sfn "${target/$old/$desired}" "$link"
      echo "  Relinked: $link"
    fi
  done

  echo "  Re-executing from new location..."
  exec "$desired/install.sh" "${SCRIPT_ARGS[@]}"
}

main() {
  echo "───────────────────────────────────────"
  echo "  dotfiles — $OS ($CURRENT_USER)"
  echo "───────────────────────────────────────"
  echo ""

  maybe_relocate_dotfiles
  install_packages
  setup_mise
  setup_tpm
  setup_zshrc
  setup_tmux
  setup_nvim
  setup_ghostty
  setup_omarchy
  setup_opencode
  setup_pi
  setup_agent_skills
  setup_claude_plugins
  setup_gitignore
  setup_git_config
  setup_apps
  setup_macos_defaults

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
