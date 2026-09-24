# Terminal output shared by install.sh and update_pkgs.
#
# The terminal is the exception, not the default. open_log points stdout and
# stderr at the log for the whole run and keeps the terminal on fd 3, so the
# only route to the screen is the output API below (emit/result/warn/note/ask).
# A module that ignores the API can't leak: its output lands in the log, which
# costs a summary line and nothing else. See agents/skills/dotfiles/resources/installer.md.
#
# On a terminal the steps are a live checklist: finished lines stay put, and
# under them a block (the running step, its latest log line, the pending steps,
# a progress bar) is redrawn in place. Anywhere else (a file, a pipe) each step
# is one static line. lib/output-demo.zsh shows both.
#
# The caller owns OUTPUT_LOG (the log's path), FAILURES, NOTES and SKIP_MODULES.

# The steps open_checklist was given, how many have finished (skipped and failed
# ones count), and when it opened.
CHECKLIST_STEPS=()
CHECKLIST_DONE=0
CHECKLIST_START=0
# Set when fd 3 is a terminal. Empty means static lines.
CHECKLIST_LIVE=""

# The live block. LIVE_STEP names the running step while it has a block, on
# screen or hidden for a moment; step_owns_terminal clears it. The main shell
# draws the block and then leaves fd 3 alone until it has stopped the renderer,
# the background subshell behind RENDERER_PID that redraws the block.
#
# Assumes the output API is called from the main shell, as every module does
# today. A warn inside $( ) or a pipeline would restart the renderer in a
# subshell, and RENDERER_PID here would never learn the new PID.
LIVE_STEP=""
LIVE_STEP_START=0
LIVE_COLUMNS=0
LIVE_BLOCK_HEIGHT=0
RENDERER_PID=""

# Where in the log (a line count) each half of the running step's display starts
# reading. The phase reads from where the step began. The detail reads from
# where the log stood when the block was last drawn, so it never repeats the
# warning or prompt that was just printed above the block.
LIVE_PHASE_LOG_START=0
LIVE_DETAIL_LOG_START=0

# The mark's shape carries the meaning and color only backs it. Blue and yellow,
# never red against green: the reader is red-green colorblind.
COLOR_RUNNING=$'\e[34m'
COLOR_FAILED=$'\e[33m'
COLOR_DIM=$'\e[2m'
COLOR_RESET=$'\e[0m'

# Static lines only. LABEL_PENDING holds the open (newline-less) progress label;
# LABEL_INTERRUPTED records that a warning broke that line, so the result knows
# to re-print the label.
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

# Stop the renderer and erase the live block, so a permanent line can print
# where the block was. The cursor rests on the block's first row between frames
# and a frame is one write, so the kill can't leave it anywhere else.
#
# Every way out of a live block comes through here, which is what gives the
# cursor and the echo back. A SIGKILL can't, and leaves both off: `stty sane`
# or `reset` recovers.
hide_live_block() {
  [[ -n "$RENDERER_PID" ]] || return 0
  kill "$RENDERER_PID" 2>/dev/null
  wait "$RENDERER_PID" 2>/dev/null
  RENDERER_PID=""
  print -rn -- $'\r\e[J\e[?25h' >&3
  stty echo <&3
}

# Draw the live block under whatever printed last and hand fd 3 to the renderer.
# The block has to fit the terminal, or moving back up to its first row would
# stop short: the pending list gives way, down to a "+N more" line. One row is
# left for the line above the block.
show_live_block() {
  [[ -n "$LIVE_STEP" ]] || return 0
  local -a size=($(stty size <&3)) pending=("${(@)CHECKLIST_STEPS[CHECKLIST_DONE + 2, -1]}")
  LIVE_COLUMNS=$size[2]
  local -i room=$(( size[1] - 5 ))
  if (( ${#pending} > room )); then
    pending=("${(@)pending[1, room - 1]}" "+$(( ${#pending} - room + 1 )) more")
  fi

  # The running line, its detail line and the bar are the renderer's to fill.
  local block=$'\n' name
  for name in "${pending[@]}"; do
    block+=$'\n'"$COLOR_DIM · $name$COLOR_RESET"
  done
  block+=$'\n\n'
  LIVE_BLOCK_HEIGHT=$(( ${#pending} + 4 ))
  LIVE_DETAIL_LOG_START=$(wc -l < "$OUTPUT_LOG")
  # No echo while the block is live: a typed Enter would move the cursor off
  # the block's first row.
  stty -echo <&3
  print -rn -- $'\e[?25l'"$block"$'\e['$(( LIVE_BLOCK_HEIGHT - 1 ))$'A\r' >&3

  render_live_block >/dev/null 2>&1 &
  RENDERER_PID=$!
}

# The renderer's loop, four frames a second. The log is its only source: the
# phase is the label of the last "--- label: cmd" line track wrote since the
# step began, the detail is the last line of output since the block was drawn.
#
# A frame holds no newline: stdio would flush there, and a kill between the two
# writes would strand the cursor a row down.
render_live_block() {
  setopt local_options extended_glob
  local -a spinner=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏) log_lines
  local -i tick=0 i cells filled
  local phase detail running bar
  while :; do
    log_lines=("${(@f)$(tail -n +$(( LIVE_PHASE_LOG_START + 1 )) "$OUTPUT_LOG")}")
    phase="${${log_lines[(R)--- *]#--- }%%: *}"
    detail=""
    for (( i = ${#log_lines}; i > LIVE_DETAIL_LOG_START - LIVE_PHASE_LOG_START && ! ${#detail}; i-- )); do
      [[ "$log_lines[i]" == (---|════|──\>)* ]] && continue
      # What the screen would have ended up showing: escape sequences (CSI,
      # OSC, charset) dropped, only the last state of a line redrawn with \r.
      detail="${log_lines[i]//$'\e'(\[[0-?]#[ -\/]#[@-~]|\][^$'\e\a']#($'\a'|$'\e'\\)|\(B)/}"
      detail="${${detail%$'\r'}##*$'\r'}"
      detail="${${detail//[[:cntrl:]]/ }##[[:space:]]#}"
    done

    running="$(checklist_line "${spinner[tick % ${#spinner} + 1]}" "$LIVE_STEP" "$phase" "$(format_elapsed $(( SECONDS - LIVE_STEP_START )))" cut)"
    running[2]="$COLOR_RUNNING$running[2]$COLOR_RESET"
    detail="$COLOR_DIM${(mr:$(( LIVE_COLUMNS - 1 )):):-   └ $detail}$COLOR_RESET"

    # Steps finished out of steps, not a time estimate: the bar only moves when
    # a step ends. Narrower than 32 cells when the terminal is.
    bar="  $CHECKLIST_DONE/${#CHECKLIST_STEPS} · $(format_elapsed $(( SECONDS - CHECKLIST_START )))"
    cells=$(( LIVE_COLUMNS - 2 - ${#bar} ))
    (( cells > 32 )) && cells=32
    filled=$(( cells * CHECKLIST_DONE / ${#CHECKLIST_STEPS} ))
    bar=" $COLOR_RUNNING${(l:$filled::━:):-}╸$COLOR_RESET$COLOR_DIM${(l:$(( cells - filled - 1 ))::─:):-}$COLOR_RESET$bar"

    print -rn -- $'\r'"$running"$'\e[K\e[1B\r'"$detail"$'\e[K\e['$(( LIVE_BLOCK_HEIGHT - 2 ))$'B\r'"$bar"$'\e[K\e['$(( LIVE_BLOCK_HEIGHT - 1 ))$'A\r' >&3
    sleep 0.25
    (( tick++ ))
  done
}

# For a step that needs the real terminal (its tool prompts, or sudo may): the
# live block goes and stays gone until the step's result line, and the step
# streams to fd 3 itself.
step_owns_terminal() {
  hide_live_block
  LIVE_STEP=""
  label_break
}

# A problem worth the user's attention that doesn't stop the install. Failure
# bookkeeping is the caller's (track does it, so do the merge_json paths).
warn() {
  hide_live_block
  label_break
  emit "  ⚠️  $*"
  show_live_block
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
  local var="$1" prompt="$2" typed_ahead
  hide_live_block
  # A key pressed while an earlier step ran must not answer this question.
  # read -k takes the terminal out of line mode, so an unfinished line goes too.
  if [[ -t 0 ]]; then
    while read -t 0 -k 1 -s typed_ahead; do :; done
  fi
  print -rn -- "$prompt" >&3
  print -rn -- "$prompt"
  read -r "$var"
  print -r -- "${(P)var}"
  # A typed answer ends the prompt's row with its own newline. A piped one
  # doesn't, and the live block would be drawn over the prompt.
  [[ -n "$LIVE_STEP" && ! -t 0 ]] && print -r -- "" >&3
  show_live_block
}

# An unrecoverable problem. Says where the log is, since the summary that
# normally prints the path is never reached.
die() {
  # No live block to come back after the warning: this is the way out.
  step_owns_terminal
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
  # warn, spelled out: the tail has to reach fd 3 before the renderer is back.
  hide_live_block
  label_break
  emit "  ⚠️  $label failed (exit $rc):"
  # Terminal only — this text is already in the log, a few lines up.
  print -r -- "$tail_text" >&3
  show_live_block
  FAILURES+=("$label")
  return $rc
}

# Column the result lines align to. "macos-defaults" is the longest module name.
MODULE_LABEL_WIDTH=16

# Name every step of the run, in the order run_module will get them. Call it
# once, after open_log and the header. The live checklist needs a terminal on
# fd 3; without one the steps print as static lines.
open_checklist() {
  CHECKLIST_STEPS=("$@")
  [[ -t 3 ]] || return 0
  CHECKLIST_LIVE=1
  CHECKLIST_START=$SECONDS
  # hide_live_block is also what gives the cursor back. Every other way out
  # (die, closing_summary) is reached with the block already hidden.
  trap 'hide_live_block; exit 130' INT
  trap 'hide_live_block; exit 143' TERM
}

# Run one module: show it as the running step, run it, close it with a result.
# A skipped module prints why (so an install never looks like a phase silently
# vanished) and still succeeds.
#
# The result line is synthesized from what the shared helpers recorded, so a
# module made of symlinks needs no reporting code of its own. Reporting nothing
# means nothing changed, which is the honest default for an idempotent phase.
run_module() {
  local name="$1" fn="$2" skipped="skipped (SKIP_MODULES in ${DOTFILES_LOCAL_CONFIG:t})"
  if (( ${SKIP_MODULES[(Ie)$name]} )); then
    if [[ -n "$CHECKLIST_LIVE" ]]; then
      checklist_line "–" "$name" "$skipped" >&3
    else
      print -r -- "$(module_label "$name")$skipped" >&3
    fi
    print -r -- "════ $name — skipped (SKIP_MODULES)"
    (( CHECKLIST_DONE += 1 ))
    return 0
  fi

  MODULE_CHANGES=()
  MODULE_UNCHANGED=0
  MODULE_RESULT=""
  print -r -- "" ; print -r -- "════ $name"
  if [[ -n "$CHECKLIST_LIVE" ]]; then
    LIVE_STEP="$name"
    LIVE_STEP_START=$SECONDS
    LIVE_PHASE_LOG_START=$(wc -l < "$OUTPUT_LOG")
    show_live_block
  else
    LABEL_PENDING="$(module_label "$name")"
    LABEL_INTERRUPTED=""
    label_partial "$LABEL_PENDING"
  fi

  local -i start=$SECONDS failures_before=${#FAILURES[@]}
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

  if [[ -n "$CHECKLIST_LIVE" ]]; then
    hide_live_block
    LIVE_STEP=""
    local final
    final="$(checklist_line "✓" "$name" "$line" "$( (( elapsed > 5 )) && format_elapsed $elapsed )")"
    (( ${#FAILURES[@]} > failures_before )) && final[2]="$COLOR_FAILED!$COLOR_RESET"
    print -r -- "$final" >&3
  fi

  # Timing only when it's news. Every line carrying "(0s)" would be the same
  # noise this output exists to remove.
  (( elapsed > 5 )) && line+=" (${elapsed}s)"

  if [[ -z "$CHECKLIST_LIVE" ]]; then
    [[ -n "$LABEL_INTERRUPTED" ]] && label_partial "$LABEL_PENDING"
    print -r -- "$line" >&3
  fi
  print -r -- "──> $line"
  LABEL_PENDING=""
  LABEL_INTERRUPTED=""
  (( CHECKLIST_DONE += 1 ))
}

# "[ 3/15] ghostty ........ " — dot leader to a fixed column so results align.
module_label() {
  local name="$1" dots=""
  repeat $(( MODULE_LABEL_WIDTH - ${#name} )) dots+="."
  printf '[%2d/%d] %s %s ' "$(( CHECKLIST_DONE + 1 ))" "${#CHECKLIST_STEPS}" "$name" "$dots"
}

# " ✓ brew ············· 3 upgraded: jq, neovim   41s" — the live checklist's
# line: the same leader, and the time ($4, optional) against the right edge of
# the terminal or of 80 columns, whichever is nearer. A result longer than that
# pushes the time out and wraps, which a line printed once can afford. The
# running line is redrawn in place and can't: $5 cuts it to fit.
checklist_line() {
  local mark="$1" name="$2" text="$3" time="$4" cut="$5" dots=""
  repeat $(( MODULE_LABEL_WIDTH - ${#name} )) dots+="·"
  local -i room=$(( (LIVE_COLUMNS < 80 ? LIVE_COLUMNS : 80) - MODULE_LABEL_WIDTH - 8 - ${#time} ))
  if [[ -n "$time" ]] && { [[ -n "$cut" ]] || (( ${(m)#text} < room )) }; then
    text="${(mr:$room:)text}"
  fi
  print -r -- " $mark $name $dots $text${time:+  $time}"
}

# "41s", "1m 52s"
format_elapsed() {
  (( $1 >= 60 )) && print -rn -- "$(( $1 / 60 ))m "
  print -r -- "$(( $1 % 60 ))s"
}

# Close the run: the failures or $1 (the caller's success line), the log path,
# the notes.
closing_summary() {
  emit ""
  local headline="$1" f
  (( ${#FAILURES[@]} )) && headline="⚠️  Finished with ${#FAILURES[@]} issue(s):"
  if [[ -n "$CHECKLIST_LIVE" ]]; then
    # The live checklist closes on its totals. The log keeps the static headline.
    local mark="✓" issues="${#FAILURES[@]} issues"
    (( ${#FAILURES[@]} )) && mark="$COLOR_FAILED!$COLOR_RESET"
    (( ${#FAILURES[@]} == 1 )) && issues="1 issue"
    print -r -- " $mark ${#CHECKLIST_STEPS} steps · $issues · $(format_elapsed $(( SECONDS - CHECKLIST_START )))" >&3
    print -r -- "$headline"
  else
    emit "$headline"
  fi
  for f in "${FAILURES[@]}"; do
    emit "   - $f"
  done
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
