#!/bin/bash
# SessionStart hook: inject whether this session runs inside a herdr pane, so
# the agent knows without checking. Herdr exports HERDR_PANE_ID (and tab/space/
# session vars) into every pane shell, and the hook inherits the pane's env
# through claude. Silent on machines without herdr.

if [ -n "$HERDR_PANE_ID" ]; then
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
    label_note=" The tab is already labeled, but the space label is still the herdr default; name it after the task: herdr workspace rename $HERDR_WORKSPACE_ID '[<task-id>] <summary>' (a space without a task ID gets a short plain name instead, never the repo or directory name)."
  else
    label_note=" Tab and space are already labeled; re-run herdr tab rename $HERDR_TAB_ID '<3-5 word task>' if the task materially changes."
  fi
  ctx="This session runs inside herdr pane $HERDR_PANE_ID (tab $HERDR_TAB_ID, space $HERDR_WORKSPACE_ID, session ${HERDR_SESSION:-default}).$label_note New herdr sessions are the user's opt-in: start one only on an explicit ask, and use your own subagents for delegation within this task; the herdr-agents skill has the recipes."
elif command -v herdr >/dev/null 2>&1; then
  ctx="This session is not inside a herdr pane. When the user explicitly asks for a new agent session in the terminal, run it through herdr (not tmux or ad-hoc background processes); otherwise delegate within this session via your own subagents. The herdr-agents skill has the recipes."
else
  exit 0
fi

jq -cn --arg ctx "$ctx" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
