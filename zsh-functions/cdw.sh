#!/bin/zsh

# cdw — navigate git worktrees
#
# cdw          fzf over all worktree locations under the project root
# cdw <name>   cd directly to a worktree by name
# cdw -        cd to the project root (the main worktree)

# Directories to search for worktrees, relative to the project root.
# To add a location: append to this array before sourcing, or extend it here.
typeset -ga _CDW_DIRS
_CDW_DIRS=(.worktrees)

_cdw_find_root() {
  local d=$PWD dir
  while [[ $d != / ]]; do
    for dir in $_CDW_DIRS; do
      [[ -d $d/$dir ]] && { echo $d; return }
    done
    if [[ -f $d/.git ]]; then
      local parent=${d:h}
      for dir in $_CDW_DIRS; do
        [[ -d $parent/$dir ]] && { echo $parent; return }
      done
    fi
    d=${d:h}
  done
}

cdw() {
  local root=$(_cdw_find_root)

  if [[ -z $root ]]; then
    echo "cdw: no worktree directories found in any parent" >&2
    return 1
  fi

  if [[ $# -eq 0 ]]; then
    local -a entries dir
    for dir in $_CDW_DIRS; do
      entries+=("$root/$dir"/*(N/:t))
    done
    entries+=("[root]")
    local target
    target=$(printf '%s\n' "${entries[@]}" | fzf --prompt="worktree> " --height=~10 --tac)
    [[ -z $target ]] && return 0
    if [[ $target == "[root]" ]]; then
      cd "$root"
      return
    fi
    for dir in $_CDW_DIRS; do
      [[ -d $root/$dir/$target ]] && { cd "$root/$dir/$target"; return }
    done
  elif [[ $1 == - ]]; then
    cd "$root"
  else
    local dir dest
    for dir in $_CDW_DIRS; do
      dest="$root/$dir/$1"
      [[ -d $dest ]] && { cd "$dest"; return }
    done
    echo "cdw: worktree '$1' not found under ${(j:, :)_CDW_DIRS}" >&2
    return 1
  fi
}

_cdw() {
  local root=$(_cdw_find_root)
  [[ -z $root ]] && return
  local -a entries dir
  for dir in $_CDW_DIRS; do
    entries+=("$root/$dir"/*(N/:t))
  done
  compadd "${entries[@]}" -
}

compdef _cdw cdw
