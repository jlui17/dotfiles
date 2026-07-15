#!/bin/zsh

# cdw / cdwrm — navigate and remove git worktrees
#
# cdw          fzf over all worktree locations under the project root
# cdw <name>   cd directly to a worktree by name
# cdw -        cd to the project root (the main worktree)
#
# cdwrm             fzf multi-select over worktree locations under the project root
# cdwrm <name>...   remove worktrees by name
# cdwrm -f ...      force removal (passes --force to `git worktree remove`)

# Directories to search for worktrees, relative to the project root.
# To add a location: append to this array before sourcing, or extend it here.
typeset -ga _CDW_DIRS
_CDW_DIRS=(.worktrees .claude/worktrees)

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

# Populates the `reply` array with worktree names found under $1 (the project root).
_cdw_worktree_entries() {
  local root=$1
  local -a dir
  reply=()
  for dir in $_CDW_DIRS; do
    reply+=("$root/$dir"/*(N/:t))
  done
}

cdw() {
  local root=$(_cdw_find_root)

  if [[ -z $root ]]; then
    echo "cdw: no worktree directories found in any parent" >&2
    return 1
  fi

  if [[ $# -eq 0 ]]; then
    local -a entries reply dir
    _cdw_worktree_entries "$root"
    entries=("${reply[@]}" "[root]")
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

cdwrm() {
  local root=$(_cdw_find_root)

  if [[ -z $root ]]; then
    echo "cdwrm: no worktree directories found in any parent" >&2
    return 1
  fi

  local -a force_args
  if [[ $1 == -f || $1 == --force ]]; then
    force_args=(--force)
    shift
  fi

  local -a targets reply
  if [[ $# -eq 0 ]]; then
    _cdw_worktree_entries "$root"
    if [[ ${#reply} -eq 0 ]]; then
      echo "cdwrm: no worktrees found under ${(j:, :)_CDW_DIRS}" >&2
      return 1
    fi
    targets=("${(@f)$(printf '%s\n' "${reply[@]}" | fzf --prompt="rm worktree> " --height=~10 --tac -m)}")
    [[ -z $targets ]] && return 0
  else
    targets=("$@")
  fi

  local name dir candidate found moved
  for name in $targets; do
    found=""
    for dir in $_CDW_DIRS; do
      candidate="$root/$dir/$name"
      [[ -d $candidate ]] && { found=$candidate; break }
    done
    if [[ -z $found ]]; then
      echo "cdwrm: worktree '$name' not found under ${(j:, :)_CDW_DIRS}" >&2
      continue
    fi
    if [[ $PWD == $found || $PWD == $found/* ]]; then
      cd "$root"
      moved=1
    fi
    git -C "$root" worktree remove "${force_args[@]}" "$found" && echo "cdwrm: removed $found"
  done

  [[ -n $moved ]] && echo "cdwrm: moved to $root (was inside a removed worktree)"
}

_cdw() {
  local root=$(_cdw_find_root)
  [[ -z $root ]] && return
  local -a reply
  _cdw_worktree_entries "$root"
  compadd "${reply[@]}" -
}

_cdwrm() {
  local root=$(_cdw_find_root)
  [[ -z $root ]] && return
  local -a reply
  _cdw_worktree_entries "$root"
  compadd "${reply[@]}"
}

compdef _cdw cdw
compdef _cdwrm cdwrm
