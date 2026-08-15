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

# Machine-local config (gitignored) — this machine's profile: work-computer
# flag, Python provider, and skip lists for modules/packages/apps the machine
# can't or shouldn't install. Created on first run via a prompt; edit or delete
# it to change answers. Never tracked in this shared repo.
DOTFILES_LOCAL_CONFIG="$DOTFILES_DIR/.dotfiles-local"
IS_WORK_COMPUTER=false

# Skip lists, overridable from .dotfiles-local. Opt-out (not opt-in) because
# machines want almost everything: a fresh personal machine needs zero config,
# and new modules added to the repo reach every machine by default.
#   SKIP_MODULES  — names from the MODULES registry below (whole phases)
#   SKIP_PACKAGES — entries in COMMON_PACKAGES
#   SKIP_APPS     — name column of GUI_APPS
#   SKIP_RULES    — global-rules sections (claude-code/rules.d/ slugs) left
#                   out of this machine's generated ~/CLAUDE.md
#   SKIP_SKILLS   — global skills (claude-code/skills/ dirs) not linked into
#                   this machine's ~/.claude
#   KEEP_PLUGINS  — machine-local Claude Code plugins (plugin@marketplace) the
#                   manifest sync must not uninstall
SKIP_MODULES=()
SKIP_PACKAGES=()
SKIP_APPS=()
SKIP_RULES=()
SKIP_SKILLS=()
KEEP_PLUGINS=()

# Collects human-readable labels of steps that failed. A bootstrap script
# shouldn't abort because one package was unavailable, but it also shouldn't
# claim success when it didn't. We track failures and report them at the end
# (and exit non-zero), instead of using `set -e` — much of this script relies
# on non-zero exit codes as normal control flow (presence checks, greps).
FAILURES=()

# -- Output plumbing --------------------------------------------------------
# The terminal is the exception, not the default. open_log points stdout and
# stderr at the log for the whole run and keeps the terminal on fd 3, so the
# only route to the screen is the output API below (emit/result/warn/note/ask).
# A module that ignores the API can't leak: its output lands in the log, which
# costs a summary line and nothing else. See .agents/skills/installer.
INSTALL_LOG="/tmp/dotfiles-install.log"

# Terminal lines the module loop is composing. LABEL_PENDING holds the open
# (newline-less) progress label; LABEL_INTERRUPTED records that a warning
# broke that line, so the result knows to re-print the label.
LABEL_PENDING=""
LABEL_INTERRUPTED=""

# Per-module state, reset by run_module. MODULE_CHANGES names what changed (one
# entry per change, all of them printed); MODULE_UNCHANGED counts the no-ops;
# MODULE_RESULT is an explicit override for modules whose story isn't links.
MODULE_CHANGES=()
MODULE_UNCHANGED=0
MODULE_RESULT=""

# Follow-up actions, printed at the end. A note is registered by the module
# that did the work making it relevant, so a re-run that changes nothing
# prints no notes at all.
NOTES=()

# -- OS detection -----------------------------------------------------------
OS=""
case "$(uname)" in
  Darwin) OS="macos" ;;
  Linux)
    if [[ -f /etc/arch-release ]]; then
      OS="arch"
    elif grep -qE '^(ID|ID_LIKE)=.*(ubuntu|debian)' /etc/os-release 2>/dev/null; then
      OS="ubuntu"
    else
      OS="unknown"
    fi
    ;;
  *) OS="unknown" ;;
esac

# -- Platform package configuration -----------------------------------------
# Single source of truth — add new tools here, not in two places.
COMMON_PACKAGES=(git fzf zoxide tmux zsh neovim ghostty lazygit mise tree-sitter-cli jq ripgrep)

case "$OS" in
  macos)
    PKG_MANAGER="brew"
    PKG_INSTALL=(brew install)
    # No --formula: some COMMON_PACKAGES are casks (ghostty), and a
    # formula-only query reports them missing forever, so every run claims to
    # install one. Bare `brew list <name>` matches either kind.
    PKG_QUERY=(brew list)
    PKG_UPDATE=(brew update)
    ;;
  arch)
    PKG_MANAGER="pacman"
    PKG_INSTALL=(sudo pacman -S --noconfirm)
    PKG_QUERY=(pacman -Qi)
    PKG_UPDATE=(sudo pacman -Syu --noconfirm)
    ;;
  ubuntu)
    PKG_MANAGER="apt"
    PKG_INSTALL=(sudo apt-get install -y)
    PKG_QUERY=(apt_pkg_installed)
    PKG_UPDATE=(sudo apt-get update)
    ;;
esac

# dpkg -s alone won't do as the query: it exits 0 for packages that were
# removed but not purged (status "deinstall ok config-files").
apt_pkg_installed() {
  [[ "$(dpkg-query -W -f '${db:Status-Status}' "$1" 2>/dev/null)" == "installed" ]]
}

# Ubuntu here means a headless server (VPS, SSH-only) — desktop Linux is the
# Arch/Omarchy machine. apt covers the base packages; tools apt lacks or ships
# too old for our configs route through mise (package → mise registry name):
#   fzf      — zshrc runs `fzf --zsh`, which needs fzf ≥ 0.48; LTS apt is older
#   zoxide   — zshrc runs `zoxide init --cmd cd`, needing ≥ 0.8; 22.04 ships 0.4
#   neovim   — the nvim config uses vim.pack; apt's neovim predates it
#   lazygit / tree-sitter-cli — not in Ubuntu's repos at all
typeset -A UBUNTU_MISE_PACKAGES=(
  fzf             fzf
  zoxide          zoxide
  neovim          neovim
  lazygit         lazygit
  tree-sitter-cli tree-sitter
)
# No headless use — a GUI terminal emulator configures the machine you sit at.
UBUNTU_DROP_PACKAGES=(ghostty)

# GUI / extra tools that aren't simple cross-platform CLI packages. Declarative
# table — add a row, no new function or main() wiring needed.
#   name | check (is it installed?) | macOS install | Arch install | Ubuntu install
# An empty install cell means "not available on that OS" (skipped). Arch AUR
# installs use yay, which Omarchy ships by default. Ubuntu is a headless VPS,
# so its column carries only CLI tools, npm-installed into mise's node.
GUI_APPS=(
  "Raycast|brew list --cask raycast|brew install --cask raycast||"
  "AltTab|brew list --cask alt-tab|brew install --cask alt-tab||"
  "Zed|command -v zed|brew install --cask zed|sudo pacman -S --noconfirm zed|"
  "1Password CLI|command -v op|brew install --cask 1password-cli|yay -S --noconfirm 1password-cli|"
  "Hunk|command -v hunk|brew tap modem-dev/tap 2>/dev/null; brew install hunk|npm i -g hunkdiff|npm i -g hunkdiff"
  "OpenCode|command -v opencode|brew install opencode||npm i -g opencode-ai"
  "Pi|command -v pi|brew install pi-coding-agent|npm i -g @earendil-works/pi-coding-agent|npm i -g @earendil-works/pi-coding-agent"
  "Herdr|command -v herdr|brew install herdr|sh -c \"\$(curl -fsSL https://herdr.dev/install.sh)\"|sh -c \"\$(curl -fsSL https://herdr.dev/install.sh)\""
)

# Ordered module registry: name:function[:os,os]. main() runs every entry
# through run_module, which honors SKIP_MODULES. The knob template appended to
# .dotfiles-local derives its module list from here too (as a snapshot at
# append time), so this is the single place a module is named.
#
# The optional OS list is what makes the progress counter honest: a module that
# can't apply here is filtered out before numbering rather than occupying a
# slot that prints nothing. Ubuntu is a headless VPS, so no terminal emulator
# config; Hyprland and the macOS defaults are their own platforms' business.
MODULES=(
  packages:install_packages
  mise:setup_mise
  apps:setup_apps
  tpm:setup_tpm
  zshrc:setup_zshrc
  tmux:setup_tmux
  nvim:setup_nvim
  ghostty:setup_ghostty:macos,arch
  omarchy:setup_omarchy:arch
  opencode:setup_opencode
  pi:setup_pi
  herdr:setup_herdr
  claude-code:setup_claude_code
  gitignore:setup_gitignore
  git-config:setup_git_config
  macos-defaults:setup_macos_defaults:macos
)

# ──────────────────────────────────────────────
#  HELPERS
# ──────────────────────────────────────────────

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Park the terminal on fd 3 and give the log stdout and stderr for the rest of
# the run. Overwrites the log, so it always describes the run you just did.
#
# maybe_relocate_dotfiles re-execs this script; DOTFILES_LOG_OPEN travels with
# it so the second pass appends rather than truncating, and doesn't re-derive
# fd 3 from a stdout that now points at the log.
open_log() {
  if [[ -n "$DOTFILES_LOG_OPEN" ]]; then
    exec >>"$INSTALL_LOG" 2>&1
    return
  fi
  exec 3>&1
  export DOTFILES_LOG_OPEN=1
  : > "$INSTALL_LOG"
  exec >>"$INSTALL_LOG" 2>&1
}

# What run this log describes. Written after the machine profile is resolved,
# because a skip list silently changing behaviour is exactly the thing you'd
# otherwise chase for twenty minutes.
log_run_header() {
  print -r -- "════ run"
  print -r -- "  date:    $(date '+%Y-%m-%d %H:%M:%S %Z')"
  print -r -- "  os:      $OS"
  print -r -- "  user:    $CURRENT_USER"
  print -r -- "  script:  $DOTFILES_DIR/install.sh ${(j: :)SCRIPT_ARGS}"
  print -r -- "  work:    $IS_WORK_COMPUTER"
  print -r -- "  python:  ${PYTHON_PROVIDER:-uv}"
  print -r -- "  skips:   modules=(${(j: :)SKIP_MODULES}) packages=(${(j: :)SKIP_PACKAGES}) apps=(${(j: :)SKIP_APPS})"
  print -r -- "           rules=(${(j: :)SKIP_RULES}) skills=(${(j: :)SKIP_SKILLS}) keep-plugins=(${(j: :)KEEP_PLUGINS})"
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

# The non-blank, non-comment lines of a manifest file. Every manifest this
# repo reads (pi/packages.txt, claude-code/external-skills.txt, plugins.txt)
# shares this shape; splitting a line into tokens stays with the caller.
manifest_lines() {
  local line
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    print -r -- "$line"
  done < "$1"
}

# -- The output API ---------------------------------------------------------

# Send a line to the terminal and the log, keeping the log a superset of what
# was shown.
emit() { print -r -- "$*" >&3; print -r -- "$*"; }

# The progress label is terminal-only: it's an unfinished line waiting for a
# result, and in the log the "════ <module>" banner already marks the module.
label_partial() { print -rn -- "$*" >&3 }

# Close an open progress label so an out-of-band line (a warning, a failure
# tail) starts on its own row instead of colliding with the label.
label_break() {
  [[ -n "$LABEL_PENDING" ]] || return 0
  print -r -- "" >&3
  LABEL_INTERRUPTED=1
}

# A problem worth the user's attention that doesn't stop the install. Failure
# bookkeeping is the caller's (track does it, so do the merge_json paths).
warn() {
  label_break
  emit "  ⚠️  $*"
}

# Register a follow-up action for the closing Notes block.
note() { NOTES+=("$*") }

# Record one thing this module changed. Every recorded change is named in the
# module's result line; a no-op bumps MODULE_UNCHANGED instead.
changed() { MODULE_CHANGES+=("$*") }

# Override the synthesized result line for modules whose work isn't symlinks
# and packages (mise's provider, the plugin replay).
result() { MODULE_RESULT="$*" }

# Prompt on the terminal. zsh's `read -r "var?prompt"` writes its prompt to
# stderr, which the log now owns — the prompt would vanish and the install
# would look hung, so the prompt goes to fd 3 by hand. stdin is untouched.
ask() {
  local var="$1" prompt="$2"
  print -rn -- "$prompt" >&3
  print -rn -- "$prompt"
  read -r "$var"
  print -r -- "${(P)var}"
}

# An unrecoverable problem. Says where the log is, since the summary that
# normally prints the path is never reached.
die() {
  warn "$*"
  emit "  Log: $INSTALL_LOG"
  exit 1
}

# Run a fallible command with its output routed to the log, under a label
# written before the command starts so a hung or interrupted run still leaves
# evidence of what it was doing. On failure, record a human-readable label in
# FAILURES (surfaced in the final summary), show a bounded tail of the output
# on the terminal, and return the command's exit code so callers can branch.
track() {
  local label="$1"; shift
  print -r -- ""
  print -r -- "--- $label: $*"
  local start_line
  start_line=$(wc -l < "$INSTALL_LOG")
  # `&&` (not `if`) so $? still holds the command's real exit code on failure —
  # an `if` with no `else` resets $? to 0 when the condition is false.
  "$@" && return 0
  local rc=$?
  # Read the tail before warning: warn writes to the log too, and would
  # otherwise be the last thing the tail picks up.
  local tail_text
  tail_text=$(tail -n +$((start_line + 1)) "$INSTALL_LOG" | tail -n 15 | sed 's/^/      /')
  warn "$label failed (exit $rc):"
  # Terminal only — this text is already in the log, a few lines up.
  print -r -- "$tail_text" >&3
  FAILURES+=("$label")
  return $rc
}

# Slugs of the global-rules sections, one per line: rules.d/NN-<slug>.md →
# <slug>. The NN- prefix is ordering only; slugs are what SKIP_RULES names.
rule_section_slugs() {
  local f
  for f in "$DOTFILES_DIR/claude-code/rules.d/"*.md(N); do
    echo "${${${f:t}%.md}#*-}"
  done
}

# Names of the global skills, one per line: claude-code/skills/<name>/ →
# <name>. These are what SKIP_SKILLS names.
global_skill_names() {
  local d
  for d in "$DOTFILES_DIR/claude-code/skills/"*/(N); do
    echo "${${d%/}:t}"
  done
}

# Include list (not a skip list): the voice-core fragments also emitted as a
# Claude Code output style, which rides in the system prompt with adherence
# reminders. CLAUDE.md keeps its copy of the same fragments because subagents
# load CLAUDE.md but never see output styles. Keep this list minimal: every
# listed fragment loads twice in a main session (CLAUDE.md + output style).
OUTPUT_STYLE_RULES=(style session-replies)

# Column the result lines align to. "macos-defaults" is the longest module name.
MODULE_LABEL_WIDTH=16

# Does a MODULES entry apply to this OS? An entry's optional third field is a
# comma-separated OS list; without one the module runs everywhere.
module_applies() {
  local -a fields=("${(s.:.)1}")
  [[ -z "${fields[3]}" ]] && return 0
  [[ ",${fields[3]}," == *",$OS,"* ]]
}

# Run one module: open its progress label, run it, close the label with a
# result. A skipped module prints why (so an install never looks like a phase
# silently vanished) and still succeeds.
#
# The result line is synthesized from what the shared helpers recorded, so a
# module made of symlinks needs no reporting code of its own. Reporting nothing
# means nothing changed, which is the honest default for an idempotent phase.
run_module() {
  local name="$1" fn="$2" index="$3" total="$4"
  if (( ${SKIP_MODULES[(Ie)$name]} )); then
    print -r -- "$(module_label "$name" "$index" "$total")skipped (SKIP_MODULES in ${DOTFILES_LOCAL_CONFIG:t})" >&3
    print -r -- "════ $name — skipped (SKIP_MODULES)"
    return 0
  fi

  MODULE_CHANGES=()
  MODULE_UNCHANGED=0
  MODULE_RESULT=""
  LABEL_PENDING="$(module_label "$name" "$index" "$total")"
  LABEL_INTERRUPTED=""
  print -r -- "" ; print -r -- "════ $name"
  label_partial "$LABEL_PENDING"

  local start=$SECONDS
  "$fn"
  local elapsed=$(( SECONDS - start ))

  local line
  if [[ -n "$MODULE_RESULT" ]]; then
    line="$MODULE_RESULT"
  elif (( ${#MODULE_CHANGES[@]} )); then
    line="${(j:, :)MODULE_CHANGES}"
  else
    line="up to date"
  fi
  # Timing only when it's news. Every line carrying "(0s)" would be the same
  # noise this output exists to remove.
  (( elapsed > 5 )) && line+=" (${elapsed}s)"

  [[ -n "$LABEL_INTERRUPTED" ]] && label_partial "$LABEL_PENDING"
  print -r -- "$line" >&3
  print -r -- "──> $line"
  LABEL_PENDING=""
  LABEL_INTERRUPTED=""
}

# "[ 3/15] ghostty ........ " — dot leader to a fixed column so results align.
module_label() {
  local name="$1" index="$2" total="$3" dots=""
  repeat $(( MODULE_LABEL_WIDTH - ${#name} )) dots+="."
  printf '[%2d/%d] %s %s ' "$index" "$total" "$name" "$dots"
}

# Append the commented knob blocks to a local config that predates them. Each
# block carries its own grep guard, so a machine whose config was written
# before a knob existed still gains that knob's block on the next run, while
# re-runs stay quiet and saved answers are never touched. The embedded module
# and slug lists are kept current by refresh_local_config_knob_lists.
append_local_config_knobs() {
  if ! grep -q "SKIP_MODULES" "$DOTFILES_LOCAL_CONFIG" 2>/dev/null; then
    cat >> "$DOTFILES_LOCAL_CONFIG" <<EOF

# Python provider: uv (default) or system. Use system on locked-down machines
# that kill Astral's standalone binaries (see setup_mise in install.sh).
#PYTHON_PROVIDER=system

# Skip whole install phases. Available modules:
#   ${(j: :)${(@)MODULES%%:*}}
#SKIP_MODULES=(omarchy pi)

# Skip individual entries from COMMON_PACKAGES / the name column of GUI_APPS.
#SKIP_PACKAGES=(lazygit)
#SKIP_APPS=(AltTab Raycast)

# Claude Code plugins installed only on this machine. The manifest sync
# uninstalls plugins missing from claude-code/plugins.txt unless listed here.
#KEEP_PLUGINS=(some-plugin@some-marketplace)
EOF
    note "Added the skip-list template to ${DOTFILES_LOCAL_CONFIG:t} — edit it to skip modules, packages, or apps."
  fi
  if ! grep -q "SKIP_RULES" "$DOTFILES_LOCAL_CONFIG" 2>/dev/null; then
    cat >> "$DOTFILES_LOCAL_CONFIG" <<EOF

# Exclude global-rules sections from this machine's generated ~/CLAUDE.md.
# Slugs come from claude-code/rules.d/ filenames. Available:
#   ${(j: :)${(f)"$(rule_section_slugs)"}}
#SKIP_RULES=(worker-cost)
EOF
    note "Added the SKIP_RULES knob to ${DOTFILES_LOCAL_CONFIG:t} — edit it to exclude global-rules sections."
  fi
  if ! grep -q "SKIP_SKILLS" "$DOTFILES_LOCAL_CONFIG" 2>/dev/null; then
    cat >> "$DOTFILES_LOCAL_CONFIG" <<EOF

# Global skills not linked into this machine's ~/.claude. Names come from
# claude-code/skills/ directories. Available:
#   ${(j: :)${(f)"$(global_skill_names)"}}
#SKIP_SKILLS=(gog)
EOF
    note "Added the SKIP_SKILLS knob to ${DOTFILES_LOCAL_CONFIG:t} — edit it to exclude global skills."
  fi
}

# The knob blocks are appended once, so their embedded "Available:" lists go
# stale as MODULES, rules.d/, and skills/ evolve. Rewrite just those snapshot
# lines on every run: for each knob, the snapshot is the "#   ..." line
# nearest above the knob's (commented or live) assignment — true of every
# template version shipped. Prose and saved answers are never touched.
refresh_local_config_knob_lists() {
  [[ -f "$DOTFILES_LOCAL_CONFIG" ]] || return 0
  local -a rule_slugs=($(rule_section_slugs)) skill_names=($(global_skill_names))
  local -A fresh_list=(
    SKIP_MODULES "${(j: :)${(@)MODULES%%:*}}"
    SKIP_RULES   "${(j: :)rule_slugs}"
    SKIP_SKILLS  "${(j: :)skill_names}"
  )
  local knob tmp refreshed=0
  for knob in ${(k)fresh_list}; do
    tmp="$(mktemp)"
    awk -v knob="$knob" -v fresh="#   ${fresh_list[$knob]}" '
      { lines[NR] = $0 }
      /^#   / { pending = NR }
      $0 ~ ("^#?" knob "=") { if (pending) { lines[pending] = fresh; pending = 0 } }
      END { for (i = 1; i <= NR; i++) print lines[i] }
    ' "$DOTFILES_LOCAL_CONFIG" > "$tmp"
    if ! cmp -s "$tmp" "$DOTFILES_LOCAL_CONFIG"; then
      cat "$tmp" > "$DOTFILES_LOCAL_CONFIG"
      refreshed=1
    fi
    rm -f "$tmp"
  done
  (( refreshed )) && note "Refreshed the knob lists in ${DOTFILES_LOCAL_CONFIG:t} — the module/rule/skill sets changed since they were written."
  return 0
}

# Load this machine's profile from the gitignored local config. First run asks
# only the work-computer question; the commented knob template is appended to
# fresh AND pre-existing configs, so configuring a restricted machine is
# "uncomment a line", not answering a prompt per module.
resolve_local_config() {
  if [[ ! -f "$DOTFILES_LOCAL_CONFIG" ]]; then
    local response
    ask response "  Is this a work computer? (skips personal zshrc symlink) [y/N] "
    [[ "$response" =~ ^[Yy]$ ]] && IS_WORK_COMPUTER=true || IS_WORK_COMPUTER=false
    cat > "$DOTFILES_LOCAL_CONFIG" <<EOF
# dotfiles machine-local config — gitignored, never committed.
# Delete this file to be prompted again on the next install.
IS_WORK_COMPUTER=$IS_WORK_COMPUTER
EOF
    emit "  Saved machine config to ${DOTFILES_LOCAL_CONFIG:t}."
  fi
  append_local_config_knobs
  refresh_local_config_knob_lists
  source "$DOTFILES_LOCAL_CONFIG"
}

# Catch typos at the top of the run: a skip entry that matches nothing is
# otherwise silently ignored and the item installs anyway. KEEP_PLUGINS isn't
# validated — its valid values depend on what's installed on this machine.
validate_skip_lists() {
  local entry module_names=("${(@)MODULES%%:*}") app_names=("${(@)GUI_APPS%%|*}")
  for entry in "${SKIP_MODULES[@]}"; do
    (( ${module_names[(Ie)$entry]} )) || warn "SKIP_MODULES: unknown module '$entry' (ignored)."
  done
  for entry in "${SKIP_PACKAGES[@]}"; do
    (( ${COMMON_PACKAGES[(Ie)$entry]} )) || warn "SKIP_PACKAGES: unknown package '$entry' (ignored)."
  done
  for entry in "${SKIP_APPS[@]}"; do
    (( ${app_names[(Ie)$entry]} )) || warn "SKIP_APPS: unknown app '$entry' (ignored)."
  done
  local rule_slugs=($(rule_section_slugs))
  for entry in "${SKIP_RULES[@]}"; do
    (( ${rule_slugs[(Ie)$entry]} )) || warn "SKIP_RULES: unknown rules section '$entry' (ignored)."
  done
  local skill_names=($(global_skill_names))
  for entry in "${SKIP_SKILLS[@]}"; do
    (( ${skill_names[(Ie)$entry]} )) || warn "SKIP_SKILLS: unknown skill '$entry' (ignored)."
  done
  for entry in "${OUTPUT_STYLE_RULES[@]}"; do
    (( ${rule_slugs[(Ie)$entry]} )) || warn "OUTPUT_STYLE_RULES: unknown rules section '$entry' (ignored)."
  done
}

# Symlink src → dst, backing up whatever was there first. The single backup
# primitive for the whole installer — handles files, directories, and symlinks:
#   - already linked to src      → no-op (idempotent re-runs stay quiet)
#   - real file/dir OR foreign    → moved to dst.bak before linking
#     symlink (points elsewhere)
# Uses `ln -sfn` so an existing dst directory is replaced, not linked into.
#
# Returns 0 when it linked something and 1 when the link was already correct,
# so a caller can register a note that only applies to first-time setup.
backup_and_link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "  $(basename "$dst") already linked."
    (( MODULE_UNCHANGED++ ))
    return 1
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    echo "  Backing up existing $(basename "$dst")..."
    mv "$dst" "$dst.bak"
  fi
  ln -sfn "$src" "$dst"
  echo "  Linked $(basename "$dst")."
  changed "linked $(basename "$dst")"
  return 0
}

# Remove symlinks in dst_dir that point into src_root but are no longer in
# the desired set (source deleted from the repo, or skipped on this machine),
# so a link farm converges instead of accumulating. Only repo-pointing
# symlinks are candidates: hand-made files, copied-in external skills, and
# foreign links are never touched.
prune_stale_links() {
  local dst_dir="$1" src_root="$2"; shift 2
  local -a desired=("$@")
  local link name
  for link in "$dst_dir"/*(N@); do
    [[ "$(readlink "$link")" == "$src_root"/* ]] || continue
    name="${link:t}"
    (( ${desired[(Ie)$name]} )) && continue
    rm "$link"
    echo "  Pruned stale link $name."
    changed "pruned $name"
  done
}

# Deep-merge a tracked JSON file into a machine-local one, repo values winning
# on conflicting keys (jq's `*` recurses into nested objects). Used instead of a
# symlink when the tool rewrites the file at runtime (e.g. Claude Code's
# settings.json): dst stays a real file the tool owns, and only the keys the repo
# declares get re-asserted each install. Machine-only keys survive. Plain-copies
# when dst is absent; refuses to touch an existing dst if jq is missing rather
# than clobber it.
merge_json() {
  local src="$1" dst="$2"
  if [[ ! -f "$dst" ]]; then
    ensure_dir "$(dirname "$dst")"
    cp "$src" "$dst"
    changed "created $(basename "$dst")"
    return
  fi
  if ! command_exists jq; then
    warn "jq not found — left $(basename "$dst") untouched. Merge $src by hand."
    FAILURES+=("merge $(basename "$dst")")
    return
  fi
  local tmp
  tmp="$(mktemp)"
  if jq -s '.[0] * .[1]' "$dst" "$src" > "$tmp" && [[ -s "$tmp" ]]; then
    # A merge that changes nothing is the steady state, so compare before
    # claiming it: only a real difference is worth a line in the result.
    if cmp -s "$tmp" "$dst"; then
      rm -f "$tmp"
      echo "  $(basename "$dst") already carries the repo settings."
      (( MODULE_UNCHANGED++ ))
    else
      mv "$tmp" "$dst"
      echo "  Merged repo settings into $(basename "$dst")."
      changed "merged $(basename "$dst")"
    fi
  else
    rm -f "$tmp"
    warn "Failed to merge $(basename "$dst") — left unchanged."
    FAILURES+=("merge $(basename "$dst")")
  fi
}

# ──────────────────────────────────────────────
#  PHASE 1 — OS packages
# ──────────────────────────────────────────────

# brew update prints every outdated formula and cask — 26 lines of package
# names on this machine. The count is the part worth knowing; the names are a
# `brew outdated` away. Only macOS: pacman -Syu upgrades as it updates, and
# apt-get update reports its own drift.
report_brew_drift() {
  [[ "$OS" == "macos" ]] || return 0
  local formulae casks
  formulae=$(brew outdated --formula --quiet | wc -l | tr -d ' ')
  casks=$(brew outdated --cask --quiet | wc -l | tr -d ' ')
  (( formulae + casks )) || return 0
  note "$formulae outdated brew formulae, $casks casks — run brew upgrade"
}

install_packages() {
  echo "==> Installing packages..."

  if [[ "$OS" == "unknown" ]]; then
    die "Unsupported OS. This script supports macOS, Arch Linux, and Ubuntu/Debian."
  fi

  # Ensure the package manager itself is available. On macOS we bootstrap
  # Homebrew when missing, then load it into this run's PATH so the package
  # installs below can see it (Apple Silicon and Intel use different prefixes).
  if [[ "$OS" == "macos" ]] && ! command_exists brew; then
    track "install Homebrew" /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      [[ -x "$brew_bin" ]] && eval "$("$brew_bin" shellenv)" && break
    done
    command_exists brew || die "Homebrew installation failed. Install it manually: https://brew.sh/"
    changed "installed Homebrew"
  fi
  if [[ "$OS" != "macos" ]] && ! command_exists sudo; then
    die "sudo is required to install packages on Linux."
  fi

  # mise has no package in Ubuntu's repos; add its official apt repo so the
  # normal install loop below installs it and `apt upgrade` keeps it current.
  if [[ "$OS" == "ubuntu" ]] && ! command_exists mise; then
    echo "  Adding the mise apt repository..."
    track "apt update" sudo apt-get update
    track "install curl gpg" sudo apt-get install -y curl gpg
    sudo install -dm 755 /etc/apt/keyrings
    track "mise apt key" sh -c \
      "curl -fsSL https://mise.jdx.dev/gpg-key.pub | sudo gpg --yes --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg"
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" \
      | sudo tee /etc/apt/sources.list.d/mise.list >/dev/null
  fi

  echo "  Updating $PKG_MANAGER..."
  track "update $PKG_MANAGER" "$PKG_UPDATE[@]"
  report_brew_drift

  local -a mise_tools=() installed=() skipped=()
  local current=0
  for package in "${COMMON_PACKAGES[@]}"; do
    if (( ${SKIP_PACKAGES[(Ie)$package]} )); then
      echo "  $package skipped (SKIP_PACKAGES)."
      skipped+=("$package")
      continue
    fi
    if [[ "$OS" == "ubuntu" ]]; then
      if (( ${UBUNTU_DROP_PACKAGES[(Ie)$package]} )); then
        echo "  $package skipped (no headless use on Ubuntu)."
        skipped+=("$package")
        continue
      fi
      if (( ${+UBUNTU_MISE_PACKAGES[$package]} )); then
        mise_tools+=("${UBUNTU_MISE_PACKAGES[$package]}")
        echo "  $package routed to mise."
        continue
      fi
    fi
    if "$PKG_QUERY[@]" "$package" >/dev/null 2>&1; then
      echo "  $package is already installed."
      (( current++ ))
    else
      echo "  Installing $package..."
      track "install $package" "$PKG_INSTALL[@]" "$package" && installed+=("$package")
    fi
  done

  local -a bits=()
  (( ${#installed[@]} ))  && bits+=("installed ${(j:, :)installed}")
  (( ${#mise_tools[@]} )) && bits+=("${#mise_tools[@]} routed to mise")
  (( ${#skipped[@]} ))    && bits+=("${#skipped[@]} skipped")
  (( current ))           && bits+=("$current up to date")
  result "${(j:, :)bits}"

  # The mise-routed tools land in a conf.d overlay (like the Python one in
  # setup_mise) rather than the machine-local config.toml, so the dotfiles-
  # managed list re-asserts on every run without touching per-machine edits.
  # setup_mise's `mise install` realizes it right after this phase.
  if [[ "$OS" == "ubuntu" ]]; then
    local mise_confd="${XDG_CONFIG_HOME:-$HOME/.config}/mise/conf.d"
    ensure_dir "$mise_confd"
    {
      echo "# Generated by dotfiles install.sh — tools apt lacks or ships too old"
      echo "# (see UBUNTU_MISE_PACKAGES in install.sh). Edits here get overwritten."
      echo "[tools]"
      local tool
      for tool in "${mise_tools[@]}"; do
        echo "$tool = \"latest\""
      done
    } > "$mise_confd/dotfiles-apt-gaps.toml"
    echo "  Declared ${#mise_tools[@]} mise-routed tool(s) in conf.d/dotfiles-apt-gaps.toml."
  fi
  echo ""
}

# ──────────────────────────────────────────────
#  PHASE 1b — mise global runtimes
# ──────────────────────────────────────────────

# Python toolchain version. No true Python LTS exists; 3.12 is the broad-compat
# stable line. Used by both providers (uv pin / mise tool version).
MISE_PYTHON_VERSION="3.12"

# Seed a machine-local runtime config (node/go/bun) on a fresh machine and
# realize it. config.toml is untracked, so per-machine tool additions stay out
# of the shared repo. Without global node/go, nvim's Mason can't build the
# servers it auto-installs (gopls needs Go; ts_ls and pyright need Node); bun
# provides bunx for the external-skills replay in setup_claude_code_skills.
#
# Python is machine-local. PYTHON_PROVIDER in .dotfiles-local picks the strategy:
#   uv     (default) — mise installs uv; uv owns Python (install + global pin).
#   system           — OS package manager installs Python (brew/pacman). For
#                      locked-down machines whose security policy SIGKILLs
#                      Astral's standalone binaries — that's both the uv binary
#                      AND mise's own Python (mise uses python-build-standalone),
#                      so on those machines neither uv nor mise-managed Python
#                      can run; the notarized Homebrew/pacman build does.
# The uv provider writes a conf.d/ overlay that mise merges on top of the
# machine-local config, keeping the seeded baseline machine-agnostic. `mise exec` resolves
# uv without depending on mise shims being on PATH here. pyright/ts_ls/gopls are
# Node/Go-based, so nvim's LSP works under either provider.
setup_mise() {
  echo "==> mise global runtimes..."
  local mise_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
  ensure_dir "$mise_dir"
  # A dangling config.toml symlink is a leftover from when this repo tracked
  # mise config (the target left the repo when config went machine-local).
  # Clear it so the seed below writes a real file instead of failing through
  # the dead link.
  if [[ -L "$mise_dir/config.toml" && ! -e "$mise_dir/config.toml" ]]; then
    rm "$mise_dir/config.toml"
    echo "  Removed dangling config.toml symlink."
  fi
  # config.toml is machine-local (untracked). Seed a node/go/bun baseline on a
  # fresh machine; never clobber an existing one so per-machine edits stick.
  if [[ ! -e "$mise_dir/config.toml" ]]; then
    cat > "$mise_dir/config.toml" <<'TOML'
# Machine-local mise runtimes (not tracked by dotfiles). Edit freely.
[tools]
node = "lts"
go = "latest"
bun = "latest"
TOML
  fi

  # PYTHON_PROVIDER comes from the local config, sourced once in
  # resolve_local_config before any module runs.
  local python_provider="${PYTHON_PROVIDER:-uv}"
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
    warn "mise not found — skipping global runtime install."
    result "skipped — mise not found"
    return
  fi

  [[ "$python_provider" == "uv" ]] && echo "  Installing mise tools (node, go, bun, uv)..." \
                                   || echo "  Installing mise tools (node, go, bun)..."
  track "mise install" mise install

  # Put mise-managed tool bins on this run's PATH: later phases check and use
  # them (setup_nvim's nvim check, npm for the apps table). Interactive shells
  # get this from `mise activate zsh` in zshrc; this script never sources that.
  eval "$(mise env -s zsh 2>/dev/null)"

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
      run_if_os "ubuntu" track "apt python3" sudo apt-get install -y python3
      ;;
  esac

  # mise install and uv both no-op silently when everything is present, so
  # there's nothing to count — say what this machine is configured for instead.
  result "runtimes current; Python $MISE_PYTHON_VERSION via $python_provider"
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
    if track "clone tpm" git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"; then
      changed "cloned tpm"
      note "To install tmux plugins, start tmux and press prefix + I (Ctrl+b, then I)."
    fi
  fi
}

# ──────────────────────────────────────────────
#  PHASE 3 — Shell & terminal symlinks
# ──────────────────────────────────────────────

setup_zshrc() {
  echo "==> zshrc..."
  if [[ "$IS_WORK_COMPUTER" == true ]]; then
    echo "  Work computer detected — skipping zshrc symlink."
    result "skipped — work computer"
  elif backup_and_link "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"; then
    note "Zsh plugins install automatically the first time you open zsh."
  fi

  # SSH logins must land in zsh for any of this config to run. macOS and
  # Omarchy default to zsh already; Ubuntu defaults to bash.
  if [[ "$OS" == "ubuntu" ]]; then
    local login_shell
    login_shell="$(getent passwd "$CURRENT_USER" | cut -d: -f7)"
    if [[ "$login_shell" != *zsh ]]; then
      echo "  Setting login shell to zsh..."
      track "chsh to zsh" sudo chsh -s "$(command -v zsh)" "$CURRENT_USER" \
        && changed "login shell → zsh"
    else
      echo "  Login shell is already zsh."
      (( MODULE_UNCHANGED++ ))
    fi
  fi
}

setup_tmux() {
  echo "==> tmux.conf..."
  local tmux_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
  ensure_dir "$tmux_dir"
  backup_and_link "$DOTFILES_DIR/tmux.conf" "$tmux_dir/tmux.conf"
}

setup_nvim() {
  echo "==> Neovim configuration..."
  local nvim_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

  # Safety net: ensure nvim is installed (normally handled by install_packages)
  if ! command_exists nvim; then
    echo "  Neovim not found. Installing..."
    run_if_os "macos" track "install neovim" brew install neovim
    run_if_os "arch" track "install neovim" sudo pacman -S --noconfirm neovim
    # Ubuntu's neovim comes from mise (declared in conf.d/dotfiles-apt-gaps.toml).
    run_if_os "ubuntu" track "install neovim" mise install neovim
    changed "installed neovim"
  else
    echo "  Neovim is already installed."
    (( MODULE_UNCHANGED++ ))
  fi

  if [[ -L "$nvim_dir" && "$(readlink "$nvim_dir")" == "$DOTFILES_DIR/nvim" ]]; then
    echo "  Neovim configuration is already linked to dotfiles."
    (( MODULE_UNCHANGED++ ))
    return
  fi

  local response=y
  if [[ -d "$nvim_dir" || -e "$nvim_dir" ]]; then
    warn "Existing Neovim configuration found at $nvim_dir"
    ask response "  Backup existing config and replace with symlink? [y/N] "
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      result "skipped — kept the existing config"
      return
    fi
    local backup_dir="$DOTFILES_DIR/nvim-bak.$(date +%Y%m%d-%H%M%S)"
    echo "  Backing up to $backup_dir..."
    mv "$nvim_dir" "$backup_dir"
  fi

  echo "  Creating symlink for Neovim configuration..."
  ln -sf "$DOTFILES_DIR/nvim" "$nvim_dir"
  changed "linked nvim config"
  note "Neovim: open nvim and wait for vim.pack to install plugins, then run :checkhealth."
}

setup_ghostty() {
  echo "==> Ghostty configuration..."
  # Ghostty reads its config from the macOS-native path but only scans the XDG
  # path for user themes, so on macOS the two land in different directories.
  local xdg_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
  local ghostty_dir
  case "$OS" in
    macos)
      ghostty_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
      ;;
    *)
      ghostty_dir="$xdg_dir"
      ;;
  esac
  ensure_dir "$ghostty_dir"
  ensure_dir "$xdg_dir"
  backup_and_link "$DOTFILES_DIR/ghostty/config" "$ghostty_dir/config" \
    && note "Ghostty config landed at $ghostty_dir — restart Ghostty to pick it up."
  backup_and_link "$DOTFILES_DIR/ghostty/themes" "$xdg_dir/themes"
}

# ──────────────────────────────────────────────
#  PHASE 4 — Omarchy (Arch Linux only)
# ──────────────────────────────────────────────

setup_omarchy() {
  echo "==> Omarchy Hyprland overrides..."
  if command_exists omarchy-update; then
    local hypr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
    ensure_dir "$hypr_dir"

    local override
    for override in bindings-override input-override; do
      backup_and_link "$DOTFILES_DIR/omarchy/hypr/$override.lua" "$hypr_dir/$override.lua"

      if ! grep -q "require(\"hypr.$override\")" "$hypr_dir/hyprland.lua" 2>/dev/null; then
        {
          echo ""
          echo "require(\"hypr.$override\")"
        } >> "$hypr_dir/hyprland.lua"
        echo "  Added require for $override to hyprland.lua."
        changed "required $override"
      else
        echo "  hyprland.lua already requires $override."
        (( MODULE_UNCHANGED++ ))
      fi
    done
  else
    echo "  omarchy-update not found — skipping Omarchy setup."
    result "skipped — omarchy-update not found"
  fi
}

# ──────────────────────────────────────────────
#  PHASE 5 — OpenCode
# ──────────────────────────────────────────────

setup_opencode() {
  echo "==> OpenCode configuration..."
  local opencode_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
  ensure_dir "$opencode_dir"

  backup_and_link "$DOTFILES_DIR/opencode/opencode.json" "$opencode_dir/opencode.json"

  # Credential files (service account keys, tokens) referenced by opencode.json.
  ensure_dir "$DOTFILES_DIR/opencode/env"
  # A machine that provisioned keys at the target before env/ was repo-managed
  # keeps them: adopt into the repo dir instead of stranding them in env.bak.
  if [[ -d "$opencode_dir/env" && ! -L "$opencode_dir/env" ]]; then
    local existing_keys=("$opencode_dir/env/"*(ND))
    (( ${#existing_keys} )) && mv -n "${existing_keys[@]}" "$DOTFILES_DIR/opencode/env/"
  fi
  backup_and_link "$DOTFILES_DIR/opencode/env" "$opencode_dir/env"
}

# ──────────────────────────────────────────────
#  PHASE 6 — Pi coding agent
# ──────────────────────────────────────────────

setup_pi() {
  echo "==> Pi coding agent configuration..."
  local pi_agent_dir="$HOME/.pi/agent"

  # -- Themes ---------------------------------------------------------------
  local -a desired=()
  ensure_dir "$pi_agent_dir/themes"
  # (N) = nullglob: an empty match skips the loop; zsh's default aborts the
  # whole script on a glob with no matches.
  for theme_file in "$DOTFILES_DIR/pi/themes/"*.json(N); do
    [[ -f "$theme_file" ]] || continue
    desired+=("$(basename "$theme_file")")
    backup_and_link "$theme_file" "$pi_agent_dir/themes/$(basename "$theme_file")"
  done
  prune_stale_links "$pi_agent_dir/themes" "$DOTFILES_DIR/pi/themes" "${desired[@]}"

  # -- Skills ---------------------------------------------------------------
  desired=()
  ensure_dir "$pi_agent_dir/skills"
  for skill_dir in "$DOTFILES_DIR/pi/skills/"*/(N); do
    [[ -d "$skill_dir" ]] || continue
    desired+=("$(basename "$skill_dir")")
    backup_and_link "${skill_dir%/}" "$pi_agent_dir/skills/$(basename "$skill_dir")"
  done
  prune_stale_links "$pi_agent_dir/skills" "$DOTFILES_DIR/pi/skills" "${desired[@]}"

  # -- Extensions ------------------------------------------------------------
  desired=()
  ensure_dir "$pi_agent_dir/extensions"
  for ext_file in "$DOTFILES_DIR/pi/extensions/"*.ts(N); do
    [[ -f "$ext_file" ]] || continue
    desired+=("$(basename "$ext_file")")
    backup_and_link "$ext_file" "$pi_agent_dir/extensions/$(basename "$ext_file")"
  done
  prune_stale_links "$pi_agent_dir/extensions" "$DOTFILES_DIR/pi/extensions" "${desired[@]}"

  # -- Global settings ------------------------------------------------------
  # Lives at the global scope (~/.pi/agent/settings.json) so the theme and
  # other preferences apply in every project, not just the dotfiles repo.
  ensure_dir "$pi_agent_dir"
  backup_and_link "$DOTFILES_DIR/pi/settings.json" "$pi_agent_dir/settings.json" \
    && note "Pi theme is linked. Select it in pi via /settings or edit settings.json."

  # -- Pi packages ----------------------------------------------------------
  local pkg_source
  if command_exists pi; then
    local pkg_count=0
    while IFS= read -r pkg_source; do
      echo "  Installing pi package: $pkg_source"
      # Show real errors (no 2>/dev/null) and record genuine failures rather
      # than assuming every failure means "already installed."
      track "pi package $pkg_source" pi install "$pkg_source" && (( pkg_count++ ))
    done < <(manifest_lines "$DOTFILES_DIR/pi/packages.txt")
    # pi install is idempotent and says nothing useful when the package is
    # already there, so the honest report is the count it kept current.
    (( MODULE_UNCHANGED += pkg_count ))
  else
    warn "pi CLI not found. Install pi first: https://pi.dev"
    result "skipped — pi CLI not found"
    while IFS= read -r pkg_source; do
      note "Install by hand once pi is available: pi install $pkg_source"
    done < <(manifest_lines "$DOTFILES_DIR/pi/packages.txt")
  fi
}

# ──────────────────────────────────────────────
#  PHASE 6b — Herdr
# ──────────────────────────────────────────────

setup_herdr() {
  echo "==> Herdr configuration..."
  local herdr_dir="${XDG_CONFIG_HOME:-$HOME/.config}/herdr"
  ensure_dir "$herdr_dir"

  backup_and_link "$DOTFILES_DIR/herdr/config.toml" "$herdr_dir/config.toml"
}

# ──────────────────────────────────────────────
#  PHASE 6c — Agent skills & commands
# ──────────────────────────────────────────────

# Build the global rules file from the rules.d/ fragments, in filename order,
# dropping fragments whose slug is in the machine's SKIP_RULES (per-machine,
# .dotfiles-local). Generated instead of symlinked because per-machine section
# exclusion needs a per-machine artifact — a symlink is all-or-nothing.
# 99-local.md (gitignored) rides along for machine-only rules. Quiet when the
# output is already current.
assemble_global_rules() {
  local dst="$1"
  local fragment slug tmp
  tmp="$(mktemp)"
  {
    echo "<!-- Generated by dotfiles install.sh from claude-code/rules.d/; edit the"
    echo "     fragments there and re-run install.sh; direct edits here get overwritten. -->"
    for fragment in "$DOTFILES_DIR/claude-code/rules.d/"*.md(N); do
      slug="${${${fragment:t}%.md}#*-}"
      (( ${SKIP_RULES[(Ie)$slug]} )) && continue
      echo ""
      cat "$fragment"
    done
  } > "$tmp"
  local lines
  lines=$(wc -l < "$tmp")
  install_generated_file "$tmp" "$dst"
  (( lines >= 300 )) && warn "$(basename "$dst") is $lines lines (budget: under 300) — distill fragments or push detail into a skill."
}

# Move an assembled tmp file into place, quiet when dst is already current.
# A symlinked dst is the old layout (link to global-rules.md) — remove the
# link rather than writing through it into the repo. A real file that isn't
# one of our generated ones gets backed up like backup_and_link would.
install_generated_file() {
  local tmp="$1" dst="$2"
  if [[ -f "$dst" && ! -L "$dst" ]] && cmp -s "$tmp" "$dst"; then
    rm -f "$tmp"
    echo "  $(basename "$dst") already up to date."
    (( MODULE_UNCHANGED++ ))
    return
  fi
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]] && ! grep -q "Generated by dotfiles install.sh" "$dst" 2>/dev/null; then
    mv "$dst" "$dst.bak"
    echo "  Backed up existing $(basename "$dst")."
  fi
  mv "$tmp" "$dst"
  chmod 644 "$dst"   # mktemp creates 0600; match the old symlink target's visibility
  echo "  Generated $(basename "$dst")."
  changed "generated $(basename "$dst")"
}

# Build the Claude Code output style from the OUTPUT_STYLE_RULES fragments:
# the same content as their CLAUDE.md sections, wrapped in the frontmatter
# output styles require. keep-coding-instructions: true keeps Claude Code's
# built-in software-engineering prompt — the default (false) strips it, and
# this style changes voice only.
assemble_output_style() {
  local dst="$1"
  local fragment slug tmp
  tmp="$(mktemp)"
  {
    cat <<'EOF'
---
name: Justin
description: "Justin's voice: concise, verdict-first; explains changes behavior-first"
keep-coding-instructions: true
---
<!-- Generated by dotfiles install.sh from claude-code/rules.d/; edit the
     fragments there and re-run install.sh; direct edits here get overwritten. -->
EOF
    for fragment in "$DOTFILES_DIR/claude-code/rules.d/"*.md(N); do
      slug="${${${fragment:t}%.md}#*-}"
      (( ${OUTPUT_STYLE_RULES[(Ie)$slug]} )) || continue
      (( ${SKIP_RULES[(Ie)$slug]} )) && continue
      echo ""
      cat "$fragment"
    done
  } > "$tmp"
  install_generated_file "$tmp" "$dst"
}

# The claude-code module: everything Claude Code reads, in two halves —
# skills/commands/rules/output style (setup_claude_code_skills) and
# settings/statusline/plugins (setup_claude_plugins). Other harnesses get
# their own modules with harness-native config (see setup_pi, setup_opencode)
# if and when needed.
setup_claude_code() {
  setup_claude_code_skills
  setup_claude_plugins
}

setup_claude_code_skills() {
  echo "==> Claude Code skills & commands..."
  local module_dir="$DOTFILES_DIR/claude-code"
  local skipped

  for skipped in "${SKIP_SKILLS[@]}"; do
    echo "  $skipped skipped (SKIP_SKILLS)."
  done

  local -a desired=()
  local commands_dir="$HOME/.claude/commands"
  ensure_dir "$commands_dir"
  for cmd_file in "$module_dir/commands/"*.md(N); do
    [[ -f "$cmd_file" ]] || continue
    desired+=("$(basename "$cmd_file")")
    backup_and_link "$cmd_file" "$commands_dir/$(basename "$cmd_file")"
  done
  prune_stale_links "$commands_dir" "$module_dir/commands" "${desired[@]}"

  desired=()
  local skills_dir="$HOME/.claude/skills"
  ensure_dir "$skills_dir"
  for skill_dir in "$module_dir/skills/"*/(N); do
    [[ -d "$skill_dir" ]] || continue
    (( ${SKIP_SKILLS[(Ie)$(basename "$skill_dir")]} )) && continue
    desired+=("$(basename "$skill_dir")")
    backup_and_link "${skill_dir%/}" "$skills_dir/$(basename "$skill_dir")"
  done
  prune_stale_links "$skills_dir" "$module_dir/skills" "${desired[@]}"

  # External skills (claude-code/external-skills.txt) come from other people's
  # repos, so they install via the skills CLI instead of symlinks: the CLI
  # copies them into ~/.claude/skills, and replaying the add is what keeps
  # them current (re-adding overwrites, picking up upstream updates).
  local manifest="$DOTFILES_DIR/claude-code/external-skills.txt"
  if ! command_exists bunx; then
    warn "bunx not found — skipping external skills."
    note "External skills are declared in claude-code/external-skills.txt; add bun = \"latest\" to ~/.config/mise/config.toml, run mise install, and re-run."
  else
    local line source skill
    local -a ext_skills new_skills
    while IFS= read -r line; do
      source="${line%%[[:space:]]*}"
      ext_skills=() new_skills=()
      for skill in ${=line#$source}; do
        (( ${SKIP_SKILLS[(Ie)$skill]} )) && continue
        ext_skills+=("$skill")
        [[ -e "$skills_dir/$skill" ]] || new_skills+=("$skill")
      done
      (( ${#ext_skills[@]} )) || continue
      echo "  Installing external skills from $source: ${(j:, :)ext_skills}"
      if track "skills add $source" bunx skills add "$source" --skill "${ext_skills[@]}" -g -y -a claude-code; then
        for skill in "${new_skills[@]}"; do changed "installed $skill"; done
        (( MODULE_UNCHANGED += ${#ext_skills[@]} - ${#new_skills[@]} ))
      fi
    done < <(manifest_lines "$manifest")
  fi

  assemble_global_rules "$HOME/CLAUDE.md"

  ensure_dir "$HOME/.claude/output-styles"
  assemble_output_style "$HOME/.claude/output-styles/justin.md"
}

# ──────────────────────────────────────────────
#  PHASE 6d — Claude Code config
# ──────────────────────────────────────────────

# settings.json links like any other config. Plugins can't be linked — their
# on-disk state carries machine-specific paths and pinned commit SHAs — so we
# replay the marketplace+install commands from the manifest; both no-op cleanly
# when the plugin is already present.
setup_claude_plugins() {
  echo "==> Claude Code config..."

  # settings.json stays a real machine-local file because Claude Code rewrites it
  # at runtime (theme, model, /fast). Deep-merge the repo's tracked keys in, repo
  # winning on conflicts, so shared settings propagate without clobbering
  # machine-only keys. Then merge claude-code/settings.local.json (gitignored,
  # per-machine) on top, so a machine can override a repo-declared key and the
  # override survives re-runs.
  merge_json "$DOTFILES_DIR/claude-code/settings.json" "$HOME/.claude/settings.json"
  if [[ -f "$DOTFILES_DIR/claude-code/settings.local.json" ]]; then
    merge_json "$DOTFILES_DIR/claude-code/settings.local.json" "$HOME/.claude/settings.json"
  fi
  backup_and_link "$DOTFILES_DIR/claude-code/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
  backup_and_link "$DOTFILES_DIR/claude-code/herdr-session-hook.sh" "$HOME/.claude/herdr-session-hook.sh"

  local manifest="$DOTFILES_DIR/claude-code/plugins.txt"

  if ! command_exists claude; then
    warn "claude CLI not found — skipping. Install Claude Code and re-run."
    note "Claude Code plugins are declared in claude-code/plugins.txt and none were installed."
    return
  fi

  # Collect wanted plugins from manifest.
  local -a wanted_plugins=()
  local line repo plugin
  while IFS= read -r line; do
    repo="${line%%[[:space:]]*}"
    for plugin in ${=line#$repo}; do
      wanted_plugins+=("$plugin")
    done
  done < <(manifest_lines "$manifest")

  # Uninstall plugins present on this machine but removed from the manifest.
  # KEEP_PLUGINS (machine-local config) exempts plugins this machine installed
  # by hand, so the shared manifest doesn't have to list every machine's extras.
  local installed
  while IFS= read -r installed; do
    [[ -z "$installed" ]] && continue
    if (( ${KEEP_PLUGINS[(Ie)$installed]} )); then
      echo "  Keeping machine-local plugin: $installed"
    elif (( ! ${wanted_plugins[(Ie)$installed]} )); then
      echo "  Uninstalling removed plugin: $installed"
      track "claude plugins uninstall $installed" claude plugins uninstall "$installed" \
        && changed "uninstalled $installed"
    fi
  done < <(claude plugins list 2>/dev/null | awk '/❯/{print $NF}')

  # Install/no-op wanted plugins.
  while IFS= read -r line; do
    repo="${line%%[[:space:]]*}"          # first token: the marketplace repo
    echo "  Adding marketplace: $repo"
    track "claude marketplace $repo" claude plugin marketplace add "$repo"
    for plugin in ${=line#$repo}; do      # remaining tokens: plugin@marketplace
      echo "  Installing plugin: $plugin"
      # The CLI is idempotent here and reports "already installed" itself, so
      # there's no new state to name — count it as held current.
      track "claude plugin $plugin" claude plugin install "$plugin" \
        && (( MODULE_UNCHANGED++ ))
    done
  done < <(manifest_lines "$manifest")
}

# ──────────────────────────────────────────────
#  PHASE 7 — Global gitignore
# ──────────────────────────────────────────────

setup_gitignore() {
  echo "==> Global gitignore..."
  local git_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/git"
  ensure_dir "$git_config_dir"
  backup_and_link "$DOTFILES_DIR/gitignore/ignore" "$git_config_dir/ignore"
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
    ask primary_email "  Primary git email: "
    cat > "$git_config" <<EOF
[user]
	name = Justin Lui
	email = $primary_email

[includeIf "gitdir:~/src/personal/"]
	path = ~/.config/git/config-personal
EOF
    echo "  Created $git_config."
    changed "created config"
  else
    echo "  $git_config already exists — skipping."
    (( MODULE_UNCHANGED++ ))
  fi

  if [[ ! -f "$git_config_personal" ]]; then
    local personal_email
    ask personal_email "  Personal git email (for ~/src/personal/): "
    printf '[user]\n\temail = %s\n' "$personal_email" > "$git_config_personal"
    echo "  Created config-personal."
    changed "created config-personal"
  else
    echo "  config-personal already exists — skipping."
    (( MODULE_UNCHANGED++ ))
  fi
}

# ──────────────────────────────────────────────
#  PHASE 8 — GUI / extra apps (declarative table)
# ──────────────────────────────────────────────

setup_apps() {
  echo "==> GUI apps..."
  # Declared once, outside the loop: zsh's `local` on an already-local name
  # prints its value, so re-declaring per iteration spams the output.
  local row name check macos_cmd arch_cmd ubuntu_cmd cmd
  local -a installed=() skipped=()
  local current=0
  for row in "${GUI_APPS[@]}"; do
    IFS='|' read -r name check macos_cmd arch_cmd ubuntu_cmd <<< "$row"
    case "$OS" in
      macos)  cmd="$macos_cmd" ;;
      arch)   cmd="$arch_cmd" ;;
      ubuntu) cmd="$ubuntu_cmd" ;;
      *)      cmd="" ;;
    esac
    [[ -z "$cmd" ]] && continue          # not available on this OS
    if (( ${SKIP_APPS[(Ie)$name]} )); then
      echo "  $name skipped (SKIP_APPS)."
      skipped+=("$name")
      continue
    fi
    if eval "$check" >/dev/null 2>&1; then
      echo "  $name already installed."
      (( current++ ))
    else
      echo "  Installing $name..."
      track "install $name" eval "$cmd" && installed+=("$name")
    fi
  done

  local -a bits=()
  (( ${#installed[@]} )) && bits+=("installed ${(j:, :)installed}")
  (( ${#skipped[@]} ))   && bits+=("${#skipped[@]} skipped")
  (( current ))          && bits+=("$current up to date")
  result "${(j:, :)bits}"
}

# ──────────────────────────────────────────────
#  PHASE 9 — macOS defaults
# ──────────────────────────────────────────────

# apply_default domain key type desired current-normalized
# `defaults read` prints booleans as 1/0 and floats as written, so the
# desired value is passed in its read form for comparison. On a write it sets
# dock_changed — the caller's local, reached through zsh's dynamic scoping.
apply_default() {
  local domain="$1" key="$2" type="$3" desired="$4" read_form="$5"
  local current
  current=$(defaults read "$domain" "$key" 2>/dev/null) || current=""
  if [[ "$current" != "$read_form" ]]; then
    defaults write "$domain" "$key" "-$type" "$desired"
    changed "$key → $desired"
    dock_changed=1
  else
    (( MODULE_UNCHANGED++ ))
  fi
}

setup_macos_defaults() {
  echo "==> macOS defaults..."

  local dock_changed=0

  apply_default com.apple.dock autohide bool true 1
  apply_default com.apple.dock autohide-time-modifier float 0.2 "0.2"

  (( dock_changed )) && killall Dock 2>/dev/null || true
}

# ──────────────────────────────────────────────
#  MAIN
# ──────────────────────────────────────────────

maybe_relocate_dotfiles() {
  local desired="$HOME/src/personal/dotfiles"
  [[ "$DOTFILES_DIR" == "$desired" ]] && return

  emit "  Dotfiles at $DOTFILES_DIR, expected $desired. Relocating..."

  if [[ -e "$desired" ]]; then
    die "$desired already exists. Move or remove it, then re-run."
  fi

  ensure_dir "$HOME/src/personal"
  mv "$DOTFILES_DIR" "$desired"
  emit "  Moved to $desired."

  local old="$DOTFILES_DIR"
  find "$HOME" -maxdepth 6 -type l 2>/dev/null | while read -r link; do
    local target
    target=$(readlink "$link")
    if [[ "$target" == "$old"* ]]; then
      ln -sfn "${target/$old/$desired}" "$link"
      echo "  Relinked: $link"
    fi
  done

  emit "  Re-executing from new location..."
  exec "$desired/install.sh" "${SCRIPT_ARGS[@]}"
}

main() {
  open_log
  emit "───────────────────────────────────────"
  emit "  dotfiles — $OS ($CURRENT_USER)"
  emit "───────────────────────────────────────"
  emit ""

  maybe_relocate_dotfiles
  resolve_local_config
  log_run_header
  validate_skip_lists

  # Modules that don't apply to this OS are not part of this machine's install,
  # so they're filtered out before numbering rather than printing an empty slot.
  local entry
  local -a applicable=()
  for entry in "${MODULES[@]}"; do
    module_applies "$entry" && applicable+=("$entry")
  done

  local index=0
  for entry in "${applicable[@]}"; do
    (( index++ ))
    run_module "${${(s.:.)entry}[1]}" "${${(s.:.)entry}[2]}" "$index" "${#applicable[@]}"
  done

  emit ""
  if (( ${#FAILURES[@]} )); then
    emit "⚠️  Finished with ${#FAILURES[@]} issue(s):"
    local f
    for f in "${FAILURES[@]}"; do
      emit "   - $f"
    done
  else
    emit "✅ Dotfiles installation complete."
  fi
  emit "   Log: $INSTALL_LOG"

  if (( ${#NOTES[@]} )); then
    emit ""
    emit "Notes:"
    local n
    for n in "${NOTES[@]}"; do
      emit "- $n"
    done
  fi

  # Non-zero exit if anything failed, so callers/CI can detect a partial install.
  (( ${#FAILURES[@]} == 0 ))
}

main "$@"
