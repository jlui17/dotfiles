#!/bin/bash
# SessionStart hook: inject whether this session runs inside a herdr pane, so
# the agent knows without checking. Herdr exports HERDR_PANE_ID (and tab/space/
# session vars) into every pane shell, and the hook inherits the pane's env
# through claude. Silent on machines without herdr.

if [ -n "$HERDR_PANE_ID" ]; then
  # A space nobody named carries the auto label (its directory basename) or an
  # empty string; the API has no user-set flag, so that's the unnamed heuristic.
  space_note=""
  space_label=$(herdr workspace get "$HERDR_WORKSPACE_ID" 2>/dev/null | jq -r '.result.workspace.label // ""' 2>/dev/null)
  if [ -z "$space_label" ] || [ "$space_label" = "$(basename "$PWD")" ]; then
    space_note=" The space's current label ('$space_label') is the unnamed default: when you label the tab, also name the space unless the user has named it since (herdr workspace rename $HERDR_WORKSPACE_ID '<1-3 word area>')."
  fi
  ctx="This session runs inside herdr pane $HERDR_PANE_ID (tab $HERDR_TAB_ID, space $HERDR_WORKSPACE_ID, session ${HERDR_SESSION:-default}). Once you know what this session is working on, label the tab by running: herdr tab rename $HERDR_TAB_ID '<3-5 word task>'; re-run it if the task materially changes.$space_note New herdr sessions are the user's opt-in: start one only on an explicit ask, and use your own subagents for delegation within this task; the herdr-agents skill has the recipes."
elif command -v herdr >/dev/null 2>&1; then
  ctx="This session is not inside a herdr pane. When the user explicitly asks for a new agent session in the terminal, run it through herdr (not tmux or ad-hoc background processes); otherwise delegate within this session via your own subagents. The herdr-agents skill has the recipes."
else
  exit 0
fi

jq -cn --arg ctx "$ctx" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
