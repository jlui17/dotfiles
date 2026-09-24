#!/bin/zsh

# update_pkgs reports like install.sh (lib/output.zsh): one result line per
# step, raw output in /tmp/update-pkgs.log. A failed step does not stop the run.
#
# A subshell, so the log redirect, DOTFILES_LOG_OPEN and the output API's
# function names never reach the shell that called it. The lib is sourced here
# and not at startup, which is latency-budgeted.
function update_pkgs() (
  local os
  local -a steps
  if command -v brew &>/dev/null; then
    os=macos steps=(brew mise)
  elif command -v pacman &>/dev/null; then
    os=arch steps=(omarchy)
  elif command -v apt-get &>/dev/null; then
    os=ubuntu steps=(apt mise codex)
    # Before the first progress label, so the password prompt gets its own line.
    sudo -v
  fi
  steps+=(skills mdnote zinit zsh-eval-cache t3)

  OUTPUT_LOG=/tmp/update-pkgs.log FAILURES=() NOTES=() SKIP_MODULES=()
  source "$DOTFILES_DIR/lib/output.zsh"
  open_log
  emit "update_pkgs ($os)"
  open_checklist $steps

  local step
  for step in $steps; do
    run_module "$step" "_update_pkgs_$step"
  done

  closing_summary "✅ Packages updated."
)

# track, with a result line that says so: the synthesized "up to date" would be
# a false claim after a failure. "done" is the same story for a step that
# cannot tell what it changed.
_update_pkgs_try() {
  track "$@" || { result "failed"; return 1 }
}

_update_pkgs_brew() {
  _update_pkgs_try "brew update" brew update || return
  local -a outdated=(${(f)"$(brew outdated --quiet)"})
  _update_pkgs_try "brew upgrade" brew upgrade || return
  local -a still_outdated=(${(f)"$(brew outdated --quiet)"})
  local -a upgraded=(${outdated:|still_outdated})
  (( ${#upgraded} )) && result "${#upgraded} upgraded: ${(j:, :)upgraded}"
}

# omarchy update wraps pacman, AUR and mise up, and adds the snapshot and the
# migrations that ship with new packages. -y skips its opening confirmation and
# makes a package conflict fail rather than ask. The orphan and reboot
# questions still get asked when they apply, and sudo may want a password, so
# this one step runs on the terminal. A yes to the reboot question reboots
# within seconds, and the steps after this one never run.
#
# The result counts pacman's own log, which covers AUR builds too. mise tools
# and migrations are not in it.
_update_pkgs_omarchy() {
  step_owns_terminal
  local -i pacman_log_start=$(wc -l < /var/log/pacman.log)
  _update_pkgs_try "omarchy update" _update_pkgs_on_terminal omarchy update -y || return
  local -i upgraded=$(tail -n +$((pacman_log_start + 1)) /var/log/pacman.log | grep -c '\[ALPM\] upgraded ')
  result "$upgraded upgraded (pacman and AUR)"
}

# The pipe is safe because omarchy update re-execs itself under script(1): its
# tools get a pty of their own and the prompts read the keyboard through it.
# tee shows the run live. sed gives the log what the screen ended up showing:
# escape sequences (CSI, OSC, charset) dropped, and only the last state of a
# line redrawn with \r. LC_ALL=C makes the ranges byte ranges: en_US.UTF-8
# collates ? before 0, and GNU sed then rejects [0-?] and takes tee down with it.
_update_pkgs_on_terminal() {
  "$@" 2>&1 | tee /dev/fd/3 | LC_ALL=C sed -E 's/\x1b(\[[0-?]*[ -\/]*[@-~]|\][^\x1b]*\x1b\\|\(B)//g; s/\r$//; s/.*\r//'
  return $pipestatus[1]
}

# -y, because a Y/n prompt hidden in the log would look like a hang.
_update_pkgs_apt() {
  _update_pkgs_try "apt update" sudo apt-get update \
    && _update_pkgs_try "apt upgrade" sudo apt-get upgrade -y \
    && result "done"
}

_update_pkgs_mise() {
  local -a outdated=(${${(f)"$(mise outdated --no-header)"}%% *})
  _update_pkgs_try "mise up" mise up || return
  local -a still_outdated=(${${(f)"$(mise outdated --no-header)"}%% *})
  local -a upgraded=(${outdated:|still_outdated})
  (( ${#upgraded} )) && result "${#upgraded} upgraded: ${(j:, :)upgraded}"
}

# Codex is npm-global on srv rather than mise-managed, so update it explicitly.
_update_pkgs_codex() {
  _update_pkgs_try "npm install codex" npm install -g @openai/codex && result "done"
}

_update_pkgs_skills() {
  _update_pkgs_try "skills update" bunx skills update -g && result "done"
}

_update_pkgs_mdnote() {
  local old="$(update_mdnote --installed-commit)"
  _update_pkgs_try "update mdnote" update_mdnote || return
  local new="$(update_mdnote --installed-commit)"
  # The same test update_mdnote skips on.
  if [[ -L "${BUN_INSTALL:-$HOME/.bun}/install/global/node_modules/mdnote" ]]; then
    result "skipped (linked checkout)"
  elif [[ "$new" != "$old" ]]; then
    result "${old:-none} → $new"
  fi
}

_update_pkgs_zinit() {
  _update_pkgs_try "zinit update" zinit update \
    && _update_pkgs_try "zinit cclear" zinit cclear \
    && result "done"
}

# _cached_eval's mtime check can't see upgrades of mise-shimmed tools (the shim
# never changes) and can miss Homebrew bottles whose build predates the cache.
_update_pkgs_zsh-eval-cache() {
  _update_pkgs_try "clear zsh-eval cache" rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/zsh-eval" \
    && result "cleared"
}

_update_pkgs_t3() {
  _update_pkgs_try "update t3" update_t3 && result "done"
}
