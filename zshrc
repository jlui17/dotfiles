# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Cache for `eval "$(tool init ...)"` shell integrations: the tools emit
# static init scripts, so paying their fork+startup on every shell buys
# nothing. Generation runs in a scrubbed env because the output may embed it
# (mise activate, seeing a nested shell's live activation, prepends a
# deactivation block with that shell's PATH baked in as a literal export).
# The scrub cuts both ways: tool config vars that alter the emitted script
# (zoxide's _ZO_*) are ignored at generation, so they can't be set via env.
# Invalidated on the newer of the binary's stat/lstat mtimes: brew repoints
# the symlink on install but bottle targets keep build-time mtimes (which can
# predate the cache), while `brew update` rewrites the target behind the
# never-repointed `brew` link.
_cached_eval() {
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-eval/${(j:-:)${(@)argv//[^A-Za-z0-9._-]/_}}.zsh"
  local bin="${commands[$1]:-$1}"
  zmodload -F zsh/stat b:zstat
  local -A st
  local bin_mtime=0 cache_mtime=0
  zstat -H st -- "$bin" 2>/dev/null && bin_mtime=$st[mtime]
  zstat -L -H st -- "$bin" 2>/dev/null && (( st[mtime] > bin_mtime )) && bin_mtime=$st[mtime]
  zstat -H st -- "$cache" 2>/dev/null && cache_mtime=$st[mtime]
  if [[ ! -s "$cache" ]] || (( bin_mtime > cache_mtime )); then
    local tmp="$cache.new.$$"
    mkdir -p "${cache:h}"
    command env -i HOME="$HOME" PATH="$PATH" "$@" >| "$tmp" \
      && command mv -f "$tmp" "$cache" || command rm -f "$tmp"
  fi
  [[ -s "$cache" ]] && source "$cache"
}

# Homebrew shellenv (macOS)
if [[ -f "/opt/homebrew/bin/brew" ]] then
  _cached_eval /opt/homebrew/bin/brew shellenv
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Word deletion stops at path separators, dots, dashes, equals
WORDCHARS=${WORDCHARS//[\/.\-=]/}

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Trust the existing completion dump (-C) unless it's older than a day: the
# daily full pass picks up newly installed completions, -C skips the audit
# and fpath scan on every other startup.
_cached_compinit() {
  setopt localoptions extendedglob
  autoload -Uz compinit
  local dump="${ZDOTDIR:-$HOME}/.zcompdump"
  if [[ -n ${dump}(#qN.mh-24) ]]; then
    compinit -C -d "$dump"
  else
    compinit -d "$dump"
    touch "$dump"
  fi
  # zcompile writes in place (no temp+rename), and a concurrent shell sourcing
  # a torn .zwc ranges from silently-stale to SIGBUS — so compile to a temp
  # name and rename over.
  if [[ ! -s "${dump}.zwc" || "$dump" -nt "${dump}.zwc" ]]; then
    zcompile "${dump}.$$" "$dump" 2>/dev/null \
      && command mv -f "${dump}.$$.zwc" "${dump}.zwc" \
      || command rm -f "${dump}.$$.zwc"
  fi
}

# Plugins load after the first prompt (zinit turbo); p10k instant prompt
# covers the gap. Ordering: compinit before fzf-tab (its requirement), fzf-tab
# before the widget-wrapping plugins (syntax-highlighting, autosuggestions),
# and the compdef replay in the LAST entry's atload — zinit captures compdef
# calls made while sourcing each plugin (OMZP::git makes ten) into the replay
# list, so replaying any earlier would drop them.
zinit wait lucid light-mode for \
  atinit'_cached_compinit' \
    Aloxaf/fzf-tab \
  blockf \
    zsh-users/zsh-completions \
  OMZP::git \
  zsh-users/zsh-syntax-highlighting \
  atload'_zsh_autosuggest_start; zicdreplay; zinit cdclear -q' \
    zsh-users/zsh-autosuggestions

# compinit is deferred to the turbo block above, so compdef doesn't exist yet
# for the zsh-functions files below; queue calls into zinit's replay list
# (drained by zicdreplay after compinit defines the real compdef).
compdef() { ZINIT_COMPDEF_REPLAY+=( "${(j: :)${(q)@}}" ) }

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Note: These CSI escape sequences (^[[1;5D etc.) are Linux/xterm specific.
# macOS Terminal/iTerm2 don't send these sequences, so these bindings only
# apply to Linux terminals (Alacritty, Kitty, etc.). Safe to use on both OSes.

# Ctrl+Arrow for macOS-style line navigation (beginning/end of line)
bindkey '^[[1;5D' beginning-of-line   # Ctrl+Left - beginning of line
bindkey '^[[1;5C' end-of-line         # Ctrl+Right - end of line
bindkey '^H' kill-whole-line          # Ctrl+Backspace - delete whole line

# Alt+Arrow for word navigation
bindkey '^[[1;3D' backward-word       # Alt+Left - word back
bindkey '^[[1;3C' forward-word        # Alt+Right - word forward

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion Styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Environment
export TERM=xterm-256color
export EDITOR='nvim'

# Login shells started by SSH do not read ~/.profile. Add user-level install
# locations here instead of relying on PATH inherited from a terminal app.
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.npm-global/bin"
  "$HOME/.bun/bin"
  "$HOME/.local/share/pnpm"
  "$HOME/.opencode/bin"
  "$HOME/bin"
  # mise activate (below) only rewrites PATH from prompt hooks, so a
  # non-interactive `zsh -c` never sees mise-managed tools. Shims cover those;
  # activate prepends the real install dirs, so it still wins interactively.
  "$HOME/.local/share/mise/shims"
  $path
)

# Aliases
alias ls='ls --color'
alias vim='nvim'
alias src-zsh='source ~/.zshrc'
alias vim-zsh='nvim ~/.zshrc'
alias lg='lazygit'
alias claude='claude --dangerously-skip-permissions'
# colony's script owns the ADC scope roster and probes before re-authing;
# the fallback is the pre-script two-command form for machines without colony.
gauth() {
  if [[ -x "$HOME/src/colony/scripts/gcloud-auth.sh" ]]; then
    "$HOME/src/colony/scripts/gcloud-auth.sh" "$@"
  else
    gcloud auth login && gcloud auth application-default login
  fi
}
# Force a completion-dump rebuild now instead of waiting for the daily full
# compinit pass (e.g. right after installing a tool). exec, not an in-place
# compinit: the replay list holding the manual compdef registrations is
# drained after startup, so re-running compinit in this shell would lose them.
alias update_zcomp='rm -f "${ZDOTDIR:-$HOME}/.zcompdump" "${ZDOTDIR:-$HOME}/.zcompdump.zwc" && exec zsh'

# update_pkgs also evicts the zsh-eval cache: _cached_eval's mtime check can't
# see upgrades of mise-shimmed tools (the shim never changes) and can miss
# Homebrew bottles whose build predates the cache.
if command -v brew &>/dev/null; then
  alias update_pkgs='brew update && brew upgrade && mise up && zinit update && zinit cclear && rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/zsh-eval"'
  alias update_cc='brew update && brew upgrade claude-code@latest'
elif command -v pacman &>/dev/null; then
  alias update_pkgs='sudo pacman -Syu && mise up && zinit update && zinit cclear && rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/zsh-eval"'
elif command -v apt-get &>/dev/null; then
  alias update_pkgs='sudo apt-get update && sudo apt-get upgrade && mise up && zinit update && zinit cclear && rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/zsh-eval"'
fi

# Mise (before shell integrations that depend on mise-managed tools)
if command -v mise &>/dev/null; then
  _cached_eval mise activate zsh
fi

# Bun-installed global CLIs (after mise so mise-managed tools keep precedence)
export PATH="$PATH:$HOME/.bun/bin"

# Shell integrations (fzf-tab re-wraps fzf's Tab binding when it loads
# post-prompt, so no explicit enable-fzf-tab here)
_cached_eval fzf --zsh

# Custom functions
DOTFILES_DIR="${${(%):-%x}:A:h}"

# 1Password CLI plugins (aliases for op plugin run -- ...)
[[ -f "$HOME/.config/op/plugins.sh" ]] && source "$HOME/.config/op/plugins.sh"

# Dotfiles-managed shell functions (sourced after plugins.sh so functions
# can shadow op-plugin aliases if needed).
setopt NULL_GLOB
for file in "$DOTFILES_DIR/zsh-functions"/*.sh; do
  [[ -f "$file" ]] && source "$file"
done
unsetopt NULL_GLOB

# Machine-local overrides (gitignored, never committed). Sourced last so it wins
# over everything above. Must come after ~/.p10k.zsh, which wipes all
# POWERLEVEL9K_* vars on load — e.g. POWERLEVEL9K_DISABLE_GITSTATUS lives here.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

_cached_eval zoxide init --cmd cd zsh

# OpenClaw Completion
[ -f "/home/openclaw/.openclaw/completions/openclaw.zsh" ] && source "/home/openclaw/.openclaw/completions/openclaw.zsh"
export NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
export OPENCLAW_NO_RESPAWN=1
