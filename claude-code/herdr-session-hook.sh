#!/bin/bash
# SessionStart hook: inject whether this session runs inside a herdr pane, so
# the agent knows without checking. Herdr exports HERDR_PANE_ID (and tab/space/
# session vars) into every pane shell, and the hook inherits the pane's env
# through claude. Silent on machines without herdr.

if [ -n "$HERDR_PANE_ID" ]; then
  ctx="This session runs inside herdr pane $HERDR_PANE_ID (tab $HERDR_TAB_ID, space $HERDR_WORKSPACE_ID, session ${HERDR_SESSION:-default}). Once you know what this session is working on, label the tab by running: herdr tab rename $HERDR_TAB_ID '<3-5 word task>'; re-run it if the task materially changes. Herdr is the primary way to run and manage coding agents in the terminal; the herdr-agents skill has the recipes."
elif command -v herdr >/dev/null 2>&1; then
  ctx="This session is not inside a herdr pane. Herdr is still the primary way to run and manage coding agents in the terminal (over tmux or ad-hoc background processes); the herdr-agents skill has the recipes."
else
  exit 0
fi

jq -cn --arg ctx "$ctx" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
