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
# makes a package conflict fail rather than ask. Its output goes to the log like
# any other step's, so nothing in it may ask a question: a prompt in the log is
# a hang. That rests on how Omarchy 4.0.4 works inside:
#
# - sudo. Left alone, omarchy update re-execs itself under script(1), and sudo
#   tickets are per tty: the one taken here would not count on script's pty.
#   OMARCHY_UPDATE_LOGGED=1 is its own guard against that re-exec. If Omarchy
#   drops the guard, its sudo prompt lands in the log and shows on the └ row.
#   stdin stays the terminal, or its stay-awake asks through pkexec, a GUI prompt.
# - The reboot question is a gum confirm whatever stdout is, and its default is
#   Yes, so a timeout would reboot. omarchy/update-shims/gum answers No and
#   records the question, which becomes a note.
# - The orphan question is skipped when stdout is not a terminal. Omarchy prints
#   a line saying so, which becomes a note.
#
# The result counts pacman's own log, which covers AUR builds too. mise tools
# and migrations are not in it.
_update_pkgs_omarchy() {
  _update_pkgs_try "sudo for omarchy" sudo_check_and_run true || return
  local -i pacman_log_start=$(wc -l < /var/log/pacman.log)
  local omarchy_log=/tmp/omarchy-update.log gum_questions=/tmp/update-pkgs-gum-questions
  : > "$gum_questions"
  _update_pkgs_try "omarchy update" _update_pkgs_omarchy_unattended "$omarchy_log" "$gum_questions"
  local -i rc=$?

  local line
  for line in ${(f)"$(<$gum_questions)"}; do
    note "Omarchy: ${line%. *}. Reboot when ready."
  done
  rm -f "$gum_questions"
  line="$(grep -m 1 'orphaned package(s) found' "$omarchy_log")" && note "Omarchy: $line"
  (( rc )) && return $rc

  local -i upgraded=$(tail -n +$((pacman_log_start + 1)) /var/log/pacman.log | grep -c '\[ALPM\] upgraded ')
  result "$upgraded upgraded (pacman and AUR)"
}

# $1 is where script(1) would have put the raw output: omarchy update greps
# that file for known failures as it finishes, so it has to be this run's.
# sed gives our log what a screen would have ended up showing: escape sequences
# (CSI, OSC, charset) dropped, and only the last state of a line redrawn with
# \r. -u, or sed writes to a file in blocks and the └ row has nothing to show
# for minutes. LC_ALL=C makes the ranges byte ranges: en_US.UTF-8 collates ?
# before 0, and GNU sed then rejects [0-?] and takes tee down with it.
_update_pkgs_omarchy_unattended() {
  # Read here: a background command expands its arguments after the fork, and
  # would get its own PID.
  zmodload zsh/system
  local -i shell_pid=$sysparams[pid]
  _update_pkgs_sudo_keepalive $shell_pid &>/dev/null &
  local keepalive_pid=$!
  PATH="$DOTFILES_DIR/omarchy/update-shims:$PATH" OMARCHY_UPDATE_LOGGED=1 UPDATE_PKGS_GUM_QUESTIONS="$2" \
    omarchy update -y 2>&1 | tee "$1" | LC_ALL=C sed -u -E 's/\x1b(\[[0-?]*[ -\/]*[@-~]|\][^\x1b]*\x1b\\|\(B)//g; s/\r$//; s/.*\r//'
  local -i rc=$pipestatus[1]
  kill $keepalive_pid 2>/dev/null
  wait $keepalive_pid 2>/dev/null
  return $rc
}

# sudo's ticket runs out (5 minutes by default) partway through a long pacman
# run, and the next sudo inside omarchy update would prompt under the live
# block. Ends by itself within a second of the shell it serves ($1) going,
# however that shell went, so no trap has to know about it.
_update_pkgs_sudo_keepalive() {
  local -i tick=0
  while kill -0 $1 2>/dev/null; do
    sleep 1
    (( ++tick % 60 )) || sudo -n -v
  done
}

# -y, because a Y/n prompt hidden in the log would look like a hang.
_update_pkgs_apt() {
  _update_pkgs_try "apt update" sudo_check_and_run apt-get update \
    && _update_pkgs_try "apt upgrade" sudo_check_and_run apt-get upgrade -y \
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
