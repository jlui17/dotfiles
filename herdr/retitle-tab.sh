#!/bin/sh
# Herdr keybinding target (prefix+t in config.toml): ask the focused tab's
# agent to re-derive the tab label from its thread's current state and rename
# the tab itself. The agent is the only party that reliably knows the task id
# and phase — pane scrollback is just the visible screen for alternate-screen
# TUIs, and transcripts aren't reachable from outside the session.
set -u
PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
# Keep HERDR_SOCKET_PATH (targets the session); drop pane-caller context so
# `pane current` resolves the UI-focused pane, not whoever ran this script.
unset HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID

notify() {
  herdr notification show "Tab retitle" --body "$1" >/dev/null 2>&1
}

pane_arg=${1:-}
if [ -n "$pane_arg" ]; then
  cur=$(herdr pane current --pane "$pane_arg" 2>&1) || { notify "pane lookup failed: $pane_arg"; exit 1; }
else
  cur=$(herdr pane current 2>&1) || { notify "no focused pane"; exit 1; }
fi

pane_id=$(printf '%s' "$cur" | jq -r '.result.pane.pane_id')
tab_id=$(printf '%s' "$cur" | jq -r '.result.pane.tab_id')
agent=$(printf '%s' "$cur" | jq -r '.result.pane.agent // empty')
status=$(printf '%s' "$cur" | jq -r '.result.pane.agent_status // empty')

if [ -z "$agent" ]; then
  # Focused pane may be a plain shell split next to the agent; fall back to
  # the tab's sole agent.
  tab_agents=$(herdr agent list | jq -c --arg tab "$tab_id" '[.result.agents[] | select(.tab_id == $tab)]')
  if [ "$(printf '%s' "$tab_agents" | jq 'length')" -eq 1 ]; then
    pane_id=$(printf '%s' "$tab_agents" | jq -r '.[0].pane_id')
    agent=$(printf '%s' "$tab_agents" | jq -r '.[0].agent')
    status=$(printf '%s' "$tab_agents" | jq -r '.[0].agent_status')
  else
    notify "no agent in $tab_id"
    exit 0
  fi
fi

# Never type into a blocked agent: the text could answer its pending dialog.
if [ "$status" = "blocked" ]; then
  notify "$agent is blocked on a prompt; answer it first"
  exit 0
fi

prompt="[herdr prefix+t] Re-derive this tab's label from what this thread is doing right now, then run: herdr tab rename $tab_id '<label>' — label is '[<task-id>] <3-6 word summary>' when the work has a task id, else just the summary. Do only the rename, then continue what you were doing; no reply needed."

if ! err=$(herdr agent prompt "$pane_id" "$prompt" 2>&1 >/dev/null); then
  # agent_prompt_stalled right after startup is usually a race; retry once.
  sleep 1
  if ! err=$(herdr agent prompt "$pane_id" "$prompt" 2>&1 >/dev/null); then
    notify "prompt to $agent failed: $err"
    exit 1
  fi
fi
notify "asked $agent to relabel $tab_id"
