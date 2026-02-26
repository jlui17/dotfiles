#!/bin/zsh

tmuxfix() {
  local pids=($(pgrep -x tmux))

  if [[ ${#pids[@]} -eq 0 ]]; then
    echo "No tmux server process found."
    return 1
  fi

  for pid in "${pids[@]}"; do
    echo "Sending USR1 to tmux server (PID $pid)"
    kill -USR1 "$pid"
    sleep 0.2
    if tmux ls &>/dev/null; then
      echo "Server recovered."
      return 0
    fi
  done

  echo "Server still not responding."
  return 1
}

_get_session_list() {
  tmux ls 2>/dev/null | while read line; do
    session_name=$(echo "$line" | cut -d: -f1)
    session_info=$(echo "$line" | cut -d: -f2-)
    printf "%-20s:%s\n" "$session_name" "$session_info"
  done
}

tmuxn() {
  if [[ -n $TMUX ]]; then
    echo "Already in a tmux session"
    return 1
  fi

  if [[ $# -eq 0 ]]; then
    # Interactive mode
    local sessions_output=$(_get_session_list)
    local selection

    if [[ -n "$sessions_output" ]]; then
      # Add "Create new session" option at the top
      local menu_options="[NEW SESSION]         Create a new tmux session
$sessions_output"

      selection=$(echo "$menu_options" | fzf \
        --height=40% \
        --reverse \
        --border \
        --header="Select tmux session (Enter to attach, Ctrl-C to cancel)")
    else
      # No existing sessions, just create new
      selection="[NEW SESSION]"
    fi

    if [[ -n "$selection" ]]; then
      if [[ "$selection" =~ "^\[NEW SESSION\]" ]]; then
        # Prompt for new session name
        echo -n "Enter new session name: "
        read session_name
        if [[ -n "$session_name" ]]; then
          tmux new -A -s "$session_name"
        else
          echo "No session name provided"
          return 1
        fi
      else
        # Extract session name (first column)
        local session_name=$(echo "$selection" | cut -d: -f1 | sed 's/ *$//')
        tmux new -A -s "$session_name"
      fi
    else
      echo "No selection made"
      return 1
    fi
  else
    # Direct mode with session name provided
    tmux new -A -s "$1"
  fi
}

tmuxk() {
  if [[ $# -eq 0 ]]; then
    # Interactive mode
    local sessions_output=$(_get_session_list)

    if [[ -z "$sessions_output" ]]; then
      echo "No tmux sessions found"
      return 1
    fi

    local selections=$(echo "$sessions_output" | fzf \
      --multi \
      --height=40% \
      --reverse \
      --border \
      --header="Select sessions to kill (Tab to multi-select, Enter to confirm)")

    if [[ -n "$selections" ]]; then
      echo "$selections" | while IFS= read -r selection; do
        if [[ -n "$selection" ]]; then
          local session_name=$(echo "$selection" | cut -d: -f1 | sed 's/ *$//')
          echo "Killing session: $session_name"
          tmux kill-session -t "$session_name"
        fi
      done
    else
      echo "No sessions selected"
      return 1
    fi
  else
    # Direct mode with session names provided
    for session in "$@"; do
      if tmux has-session -t "$session" 2>/dev/null; then
        echo "Killing session: $session"
        tmux kill-session -t "$session"
      else
        echo "Session not found: $session"
      fi
    done
  fi
}

# Zsh completion function for tmuxn
_tmuxn() {
  local context state line
  local sessions

  # Only complete for the first argument
  if [[ ${#words[@]} -gt 2 ]]; then
    return 0
  fi

  # Get available tmux sessions
  sessions=($(tmux ls 2>/dev/null | cut -d: -f1))

  if [[ ${#sessions[@]} -gt 0 ]]; then
    _describe 'tmux sessions' sessions
  else
    _message 'no tmux sessions found - will create new session'
  fi
}

# Zsh completion function for tmuxk
_tmuxk() {
  local context state line
  local sessions available_sessions

  # Get all tmux sessions
  sessions=($(tmux ls 2>/dev/null | cut -d: -f1))

  if [[ ${#sessions[@]} -eq 0 ]]; then
    _message 'no tmux sessions found'
    return 0
  fi

  # Don't allow more completions than available sessions
  if [[ ${#words[@]} -gt $((${#sessions[@]} + 1)) ]]; then
    return 0
  fi

  # Filter out sessions already specified in previous arguments
  available_sessions=()
  for session in "${sessions[@]}"; do
    if [[ ! " ${words[2,-1]} " =~ " $session " ]]; then
      available_sessions+=("$session")
    fi
  done

  if [[ ${#available_sessions[@]} -gt 0 ]]; then
    _describe 'tmux sessions to kill' available_sessions
  fi
}

# Register completions if in zsh
if [[ -n "$ZSH_VERSION" ]]; then
  compdef _tmuxn tmuxn
  compdef _tmuxk tmuxk
fi