#!/bin/bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
effort=$(echo "$input" | jq -r '.effort.level // empty')
worktree=$(echo "$input" | jq -r '.worktree.name // .workspace.git_worktree // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

left="\033[2m$model\033[0m"
[ -n "$effort" ] && left="$left \033[2m[$effort]\033[0m"

segments=()
if [ -n "$used" ]; then
  pct=$(printf "%.0f" "$used")
  if [ "$pct" -lt 50 ]; then
    color="\033[32m"   # green
  elif [ "$pct" -lt 80 ]; then
    color="\033[33m"   # yellow
  else
    color="\033[31m"   # red
  fi
  segments+=("${color}ctx: ${pct}%% used\033[0m")
fi
[ -n "$worktree" ] && segments+=("\033[2mwt: $worktree\033[0m")

out="$left"
for seg in "${segments[@]}"; do
  out="$out | $seg"
done

printf "$out"
