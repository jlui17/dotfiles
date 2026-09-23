# Terminal output shared by install.sh and update_pkgs.
#
# The terminal is the exception, not the default. open_log points stdout and
# stderr at the log for the whole run and keeps the terminal on fd 3, so the
# only route to the screen is the output API below (emit/result/warn/note/ask).
# A module that ignores the API can't leak: its output lands in the log, which
# costs a summary line and nothing else. See agents/skills/dotfiles/resources/installer.md.
#
# The caller owns OUTPUT_LOG (the log's path), FAILURES, NOTES and SKIP_MODULES.

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

# Park the terminal on fd 3 and give the log stdout and stderr for the rest of
# the run. Overwrites the log, so it always describes the run you just did.
#
# maybe_relocate_dotfiles re-execs install.sh; DOTFILES_LOG_OPEN travels with
# it so the second pass appends rather than truncating, and doesn't re-derive
# fd 3 from a stdout that now points at the log.
open_log() {
  if [[ -n "$DOTFILES_LOG_OPEN" ]]; then
    exec >>"$OUTPUT_LOG" 2>&1
    return
  fi
  exec 3>&1
  export DOTFILES_LOG_OPEN=1
  : > "$OUTPUT_LOG"
  exec >>"$OUTPUT_LOG" 2>&1
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
  [[ -n "$LABEL_PENDING" && -z "$LABEL_INTERRUPTED" ]] || return 0
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
  emit "  Log: $OUTPUT_LOG"
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
  start_line=$(wc -l < "$OUTPUT_LOG")
  # `&&` (not `if`) so $? still holds the command's real exit code on failure —
  # an `if` with no `else` resets $? to 0 when the condition is false.
  "$@" && return 0
  local rc=$?
  # Read the tail before warning: warn writes to the log too, and would
  # otherwise be the last thing the tail picks up.
  local tail_text
  tail_text=$(tail -n +$((start_line + 1)) "$OUTPUT_LOG" | tail -n 15 | sed 's/^/      /')
  warn "$label failed (exit $rc):"
  # Terminal only — this text is already in the log, a few lines up.
  print -r -- "$tail_text" >&3
  FAILURES+=("$label")
  return $rc
}

# Column the result lines align to. "macos-defaults" is the longest module name.
MODULE_LABEL_WIDTH=16

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
  local -i elapsed=$(( SECONDS - start ))

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

# Close the run: the failures or $1 (the caller's success line), the log path,
# the notes.
closing_summary() {
  emit ""
  if (( ${#FAILURES[@]} )); then
    emit "⚠️  Finished with ${#FAILURES[@]} issue(s):"
    local f
    for f in "${FAILURES[@]}"; do
      emit "   - $f"
    done
  else
    emit "$1"
  fi
  emit "   Log: $OUTPUT_LOG"

  if (( ${#NOTES[@]} )); then
    emit ""
    emit "Notes:"
    local n
    for n in "${NOTES[@]}"; do
      emit "- $n"
    done
  fi

  # Non-zero if anything failed, so callers/CI can detect a partial run.
  (( ${#FAILURES[@]} == 0 ))
}
