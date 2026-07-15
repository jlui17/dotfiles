#!/bin/zsh

# cdwrm — remove git worktrees
#
# cdwrm             fzf multi-select over worktree locations under the project root
# cdwrm <name>...   remove worktrees by name
# cdwrm -f ...      force removal (passes --force to `git worktree remove`)

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

  local -a targets dir entries
  if [[ $# -eq 0 ]]; then
    for dir in $_CDW_DIRS; do
      entries+=("$root/$dir"/*(N/:t))
    done
    if [[ ${#entries} -eq 0 ]]; then
      echo "cdwrm: no worktrees found under ${(j:, :)_CDW_DIRS}" >&2
      return 1
    fi
    targets=("${(@f)$(printf '%s\n' "${entries[@]}" | fzf --prompt="rm worktree> " --height=~10 --tac -m)}")
    [[ -z $targets ]] && return 0
  else
    targets=("$@")
  fi

  local name candidate found moved
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

_cdwrm() {
  local root=$(_cdw_find_root)
  [[ -z $root ]] && return
  local -a entries dir
  for dir in $_CDW_DIRS; do
    entries+=("$root/$dir"/*(N/:t))
  done
  compadd "${entries[@]}"
}

compdef _cdwrm cdwrm
