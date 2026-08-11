#!/bin/zsh

# cdw / cdwrm — navigate and remove git worktrees
#
# cdw          fzf over the repo's linked worktrees (from `git worktree list`)
# cdw <name>   cd directly to a worktree by name (path basename)
# cdw -        cd to the main worktree
#
# cdwrm             fzf multi-select over the repo's linked worktrees
# cdwrm <name>...   remove worktrees by name
# cdwrm -f ...      force removal (passes --force to `git worktree remove`)

# Prints the main worktree's path; empty outside a git repository.
_cdw_root() {
  git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print substr($0, 10); exit}'
}

# Prints linked worktree paths, one per line (skips the main checkout, which
# porcelain output always lists first). Location-agnostic: sees worktrees
# wherever they were created (.worktrees/, .claude/worktrees/, herdr's dir).
_cdw_worktree_paths() {
  git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print substr($0, 10)}' | tail -n +2
}

cdw() {
  emulate -L zsh
  local root=$(_cdw_root)
  if [[ -z $root ]]; then
    echo "cdw: not inside a git repository" >&2
    return 1
  fi

  local -a paths
  paths=(${(f)"$(_cdw_worktree_paths)"})

  if (( $# == 0 )); then
    local -a entries
    local p
    for p in $paths; do
      entries+=("${p:t}"$'\t'"$p")
    done
    entries+=("[root]"$'\t'"$root")
    local target
    target=$(printf '%s\n' "${entries[@]}" |
      fzf --prompt="worktree> " --height=~10 --tac --delimiter=$'\t' --with-nth=1)
    [[ -z $target ]] && return 0
    cd "${target#*$'\t'}"
  elif [[ $1 == - ]]; then
    cd "$root"
  else
    local -a matches
    local p
    for p in $paths; do
      [[ ${p:t} == $1 ]] && matches+=("$p")
    done
    if (( ${#matches} == 0 )); then
      echo "cdw: worktree '$1' not found in \`git worktree list\`" >&2
      return 1
    elif (( ${#matches} > 1 )); then
      printf 'cdw: %s is ambiguous:\n' "$1" >&2
      printf '  %s\n' "${matches[@]}" >&2
      return 1
    fi
    cd "${matches[1]}"
  fi
}

cdwrm() {
  emulate -L zsh
  local root=$(_cdw_root)
  if [[ -z $root ]]; then
    echo "cdwrm: not inside a git repository" >&2
    return 1
  fi

  local -a force_args
  if [[ $1 == -f || $1 == --force ]]; then
    force_args=(--force)
    shift
  fi

  local -a paths
  paths=(${(f)"$(_cdw_worktree_paths)"})

  local -a target_paths
  if (( $# == 0 )); then
    if (( ${#paths} == 0 )); then
      echo "cdwrm: no linked worktrees in this repository" >&2
      return 1
    fi
    # name\tpath entries so duplicate basenames stay distinguishable rows.
    local -a entries selected
    local p
    for p in $paths; do
      entries+=("${p:t}"$'\t'"$p")
    done
    selected=("${(@f)$(printf '%s\n' "${entries[@]}" |
      fzf --prompt="rm worktree> " --height=~10 --tac -m --delimiter=$'\t' --with-nth=1)}")
    [[ -z $selected ]] && return 0
    target_paths=("${selected[@]#*$'\t'}")
  else
    local name p
    local -a matches
    for name in "$@"; do
      matches=()
      for p in $paths; do
        [[ ${p:t} == $name ]] && matches+=("$p")
      done
      if (( ${#matches} == 0 )); then
        echo "cdwrm: worktree '$name' not found in \`git worktree list\`" >&2
        return 1
      elif (( ${#matches} > 1 )); then
        printf 'cdwrm: %s is ambiguous:\n' "$name" >&2
        printf '  %s\n' "${matches[@]}" >&2
        return 1
      fi
      target_paths+=("${matches[1]}")
    done
  fi

  # Step out before removing so the shell is never left in a deleted
  # directory, but step back if the removal fails (e.g. dirty worktree
  # without -f) so a failed remove leaves the shell where it was.
  local found came_from failed=0
  for found in $target_paths; do
    came_from=""
    if [[ $PWD == $found || $PWD == $found/* ]]; then
      came_from=$PWD
      cd "$root"
    fi
    if git -C "$root" worktree remove "${force_args[@]}" "$found"; then
      echo "cdwrm: removed $found"
      [[ -n $came_from ]] && echo "cdwrm: moved to $root (was inside the removed worktree)"
    else
      failed=1
      [[ -n $came_from ]] && cd "$came_from"
    fi
  done
  return $failed
}

_cdw() {
  local -a paths
  paths=(${(f)"$(_cdw_worktree_paths)"})
  compadd "${paths[@]:t}" -
}

_cdwrm() {
  local -a paths
  paths=(${(f)"$(_cdw_worktree_paths)"})
  compadd "${paths[@]:t}"
}

compdef _cdw cdw
compdef _cdwrm cdwrm
