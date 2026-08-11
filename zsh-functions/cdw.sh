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
    local p
    for p in $paths; do
      [[ ${p:t} == $1 ]] && { cd "$p"; return }
    done
    echo "cdw: worktree '$1' not found in \`git worktree list\`" >&2
    return 1
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

  local -a targets
  if (( $# == 0 )); then
    if (( ${#paths} == 0 )); then
      echo "cdwrm: no linked worktrees in this repository" >&2
      return 1
    fi
    targets=("${(@f)$(printf '%s\n' "${paths[@]:t}" | fzf --prompt="rm worktree> " --height=~10 --tac -m)}")
    [[ -z $targets ]] && return 0
  else
    targets=("$@")
  fi

  local name p found moved
  for name in $targets; do
    found=""
    for p in $paths; do
      [[ ${p:t} == $name ]] && { found=$p; break }
    done
    if [[ -z $found ]]; then
      echo "cdwrm: worktree '$name' not found in \`git worktree list\`" >&2
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
