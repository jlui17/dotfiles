# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Homebrew shellenv (macOS)
if [[ -f "/opt/homebrew/bin/brew" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"
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

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Zinit snippets
zinit snippet OMZP::git

# Load completions
autoload -Uz compinit && compinit
zinit cdreplay -q

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

# Aliases
alias ls='ls --color'
alias vim='nvim'
alias src-zsh='source ~/.zshrc'
alias vim-zsh='nvim ~/.zshrc'
alias lg='lazygit'

# Mise (before shell integrations that depend on mise-managed tools)
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# Shell integrations
eval "$(fzf --zsh)"
enable-fzf-tab

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

eval "$(zoxide init --cmd cd zsh)"
