#!/bin/zsh

# Fake steps through the real output API, about 16 seconds, so a change to
# lib/output.zsh can be watched by hand:
#
#   lib/output-demo.zsh                          the live checklist
#   lib/output-demo.zsh > /tmp/output-demo.tty   the static fallback
#   print y | lib/output-demo.zsh                unattended (answers the prompt)
#
# Every route to the terminal is here once: a plain result, tracked phases with
# colored and redrawn output, a warning, a failure tail, a skipped step, a
# prompt, and enough steps to overflow a 12-line terminal.

# update_pkgs runs in an interactive shell whose zshrc made SECONDS a float.
typeset -F SECONDS

OUTPUT_LOG="${OUTPUT_LOG:-/tmp/output-demo.log}" FAILURES=() NOTES=()
SKIP_MODULES=(fonts) DOTFILES_LOCAL_CONFIG=.dotfiles-local
source "${0:A:h}/output.zsh"

demo_links() {
  sleep 0.5
  changed "linked ~/.zshrc"
  changed "linked ~/.gitconfig"
}

demo_fetch_index() {
  print "Fetching index..."; sleep 1
  print "  1204 packages"; sleep 1
}

demo_download() {
  print -- $'\e[34m==>\e[0m Downloading node 22.11.0'; sleep 1
  local percent
  for percent in 20 40 60 80 100; do
    print -n -- $'\r'"node 22.11.0  ${percent}%"; sleep 0.4
  done
  print
  # The same redraw done the other way (cursor to column 1, clear), and a box
  # edge after it that says nothing.
  local glyph
  for glyph in ◒ ◐ ◓ ◑; do
    print -n -- "$glyph  Verifying node"$'\e[1G\e[J'; sleep 0.4
  done
  print "◇  Verified node"; print "│"; sleep 1
}

demo_compile() {
  print "Linking node 22.11.0 with a line long enough that a narrow terminal has to truncate it instead of wrapping"; sleep 1.5
  # Ends the way zinit does: a bare carriage return and no newline.
  print -n -- "The build took 1.5 seconds"$'\r'
}

demo_runtimes() {
  track "fetch index" demo_fetch_index
  track "download node" demo_download
  track "compile" demo_compile
  print "Pruning old versions"; sleep 1
  result "1 upgraded: node"
}

demo_editor() {
  track "check config" sleep 1
  warn "Existing config found at ~/.config/editor"
  sleep 1.5
}

demo_build_widget() {
  local i
  for i in {1..20}; do
    print "widget: compiling unit $i"; sleep 0.1
  done
  return 3
}

demo_widget() {
  track "build widget" demo_build_widget || result "failed"
}

demo_shell() {
  local response
  ask response "  Replace the existing shell config? [y/N] "
  result "answered ${response:-nothing}"
  sleep 1
}

demo_quick() { sleep 0.3 }

steps=(
  links:demo_links runtimes:demo_runtimes editor:demo_editor
  widget:demo_widget fonts:demo_quick shell:demo_shell
)
for name in git tmux ghostty nvim mise agents skills macos-defaults; do
  steps+=("$name:demo_quick")
done

open_log
emit "output-demo"
emit ""
open_checklist "${steps[@]%%:*}"

for step in $steps; do
  run_module "${step%%:*}" "${step#*:}"
done

note "This was a demo: nothing on the machine changed."
closing_summary "✅ Demo complete."
