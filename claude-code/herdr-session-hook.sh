#!/bin/bash
# SessionStart hook: tell a session that runs inside a herdr pane so, and how
# its tab and space are labeled. Silent everywhere else. Herdr exports
# HERDR_PANE_ID (and tab/space/session vars) into every pane shell, and the
# hook inherits the pane's env through claude.

# The env alone is not trusted: a GUI app or any other process started from a
# pane shell passes stale HERDR_* to its children, and herdr has no caller
# validation (herdr issue #2012). So confirm the pane's shell is our ancestor.
inside_herdr_pane() {
  [ -n "$HERDR_PANE_ID" ] || return 1
  local shell_pid pid=$$
  shell_pid=$(herdr pane process-info --pane "$HERDR_PANE_ID" 2>/dev/null | jq -r '.result.process_info.shell_pid // empty' 2>/dev/null)
  [ -n "$shell_pid" ] || return 1
  while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
    [ "$pid" = "$shell_pid" ] && return 0
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done
  return 1
}

# An SDK host such as T3 Code started from a live pane shell is a descendant
# of that shell, so ancestry cannot exclude it.
[ "$CLAUDE_CODE_ENTRYPOINT" = cli ] || exit 0
inside_herdr_pane || exit 0

# Herdr stores a label only when someone sets one, but the API returns a
# resolved display label with no set-vs-computed flag: an unset tab shows
# its 1-based position among the workspace's tabs (not its `number`, a
# creation ordinal), an unset space shows the basename of a tab-1 pane cwd
# (live; verified against herdr 0.8.0). So reconstruct what the default
# would be right now and treat a label equal to it as unset. A label
# deliberately set to its own default reads as unset; that's unresolvable
# from the API. The space label format mirrors the herdr-agents skill,
# which is canonical.
tabs=$(herdr tab list --workspace "$HERDR_WORKSPACE_ID" 2>/dev/null)
tab_label=$(jq -r --arg id "$HERDR_TAB_ID" '.result.tabs[] | select(.tab_id == $id) | .label // ""' <<<"$tabs" 2>/dev/null)
tab_position=$(jq -r --arg id "$HERDR_TAB_ID" '.result.tabs | sort_by(.number) | to_entries[] | select(.value.tab_id == $id) | .key + 1' <<<"$tabs" 2>/dev/null)
space_label=$(herdr workspace get "$HERDR_WORKSPACE_ID" 2>/dev/null | jq -r '.result.workspace.label // ""' 2>/dev/null)
first_tab=$(jq -r '[.result.tabs[]] | min_by(.number) | .tab_id // ""' <<<"$tabs" 2>/dev/null)
space_defaults=$(herdr pane list --workspace "$HERDR_WORKSPACE_ID" 2>/dev/null |
  jq -r --arg t "$first_tab" '[.result.panes[] | select(.tab_id == $t) | .cwd, .foreground_cwd] | map(select(. != null) | split("/") | last) | unique | .[]' 2>/dev/null)

tab_unnamed=""
if [ -z "$tab_label" ] || [ "$tab_label" = "$tab_position" ]; then tab_unnamed=1; fi
space_unnamed=""
if [ -z "$space_label" ] || grep -qxF -- "$space_label" <<<"$space_defaults"; then space_unnamed=1; fi

if [ -n "$tab_unnamed" ] && [ -n "$space_unnamed" ]; then
  label_note=" Tab and space labels are both still herdr defaults; once you know what this session is working on, set both in one command: herdr tab rename $HERDR_TAB_ID '<3-5 word task>' && herdr workspace rename $HERDR_WORKSPACE_ID '[<task-id>] <summary>' (a space without a task ID gets a short plain name instead, never the repo or directory name). Re-run the tab rename if the task materially changes."
elif [ -n "$tab_unnamed" ]; then
  label_note=" Once you know what this session is working on, label the tab: herdr tab rename $HERDR_TAB_ID '<3-5 word task>'; re-run it if the task materially changes."
elif [ -n "$space_unnamed" ]; then
  label_note=" The tab label is '$tab_label'. A label carries over from the tab's last task, or is the first words of the kickoff prompt, so judge it: unless it already names this session's task in 3-5 words, rename it now with herdr tab rename $HERDR_TAB_ID '<3-5 word task>', and re-run that if the task materially changes. The space label is still the herdr default; name it after the task: herdr workspace rename $HERDR_WORKSPACE_ID '[<task-id>] <summary>' (a space without a task ID gets a short plain name instead, never the repo or directory name)."
else
  label_note=" The tab label is '$tab_label'. A label carries over from the tab's last task, or is the first words of the kickoff prompt, so judge it: unless it already names this session's task in 3-5 words, rename it now with herdr tab rename $HERDR_TAB_ID '<3-5 word task>', and re-run that if the task materially changes. The space label is '$space_label' and spans tasks; leave it."
fi
ctx="This session runs inside herdr pane $HERDR_PANE_ID (tab $HERDR_TAB_ID, space $HERDR_WORKSPACE_ID, session ${HERDR_SESSION:-default}).$label_note New herdr sessions are the user's opt-in: start one only on an explicit ask (\"kickoff X\" or \"start a new session that…\" is that ask: a new herdr session Justin steers directly, never a subagent), and use your own subagents for delegation within this task. Name every session you start: the task number if one exists plus a 1-5 word summary, e.g. [colony-562] flow viewer. The herdr-agents skill has the recipes, and herdr --skill prints herdr's own."

jq -cn --arg ctx "$ctx" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
