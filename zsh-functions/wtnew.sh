#!/bin/zsh

# wtnew <name> [summary...] — start a task: worktree + per-repo setup + herdr space
#
# Creates <repo>/.worktrees/<name> on a new branch <name>, runs the repo's
# setup from worktree-setups/<repo>.sh, then opens a herdr space labeled
# "[<name>] <summary>" bound to the worktree (or cd's there outside herdr).
# Refuses to run on a repo with no setup file, so an unknown repo can never
# produce a silently half-set-up worktree.

typeset -g _WT_SETUPS_DIR="${${(%):-%x}:A:h}/worktree-setups"

wtnew() {
  emulate -L zsh
  if (( $# < 1 )); then
    echo "usage: wtnew <name> [summary...]" >&2
    return 2
  fi
  local name=$1
  shift
  local summary="$*"

  # First porcelain entry is always the main worktree, even when called from
  # inside a linked one.
  local repo_root
  repo_root=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{print substr($0, 10); exit}')
  if [[ -z $repo_root ]]; then
    echo "wtnew: not inside a git repository" >&2
    return 1
  fi

  local repo=${repo_root:t}
  local setup_file="$_WT_SETUPS_DIR/$repo.sh"
  if [[ ! -f $setup_file ]]; then
    echo "wtnew: no setup defined for '$repo'" >&2
    echo "wtnew: add $setup_file defining wt_setup() (empty body if no setup is needed)" >&2
    return 1
  fi

  unset wt_dir
  unfunction wt_setup 2>/dev/null
  source "$setup_file" || { echo "wtnew: failed to source $setup_file" >&2; return 1 }
  if ! typeset -f wt_setup >/dev/null; then
    echo "wtnew: $setup_file does not define wt_setup()" >&2
    return 1
  fi

  local wt_path="$repo_root/${wt_dir:-.worktrees}/$name"
  if ! git -C "$repo_root" worktree add "$wt_path" -b "$name"; then
    unfunction wt_setup
    unset wt_dir
    return 1
  fi

  # Subshell so wt_setup's cd/env never touch the interactive shell.
  ( cd "$wt_path" && REPO_ROOT="$repo_root" WORKTREE_PATH="$wt_path" BRANCH="$name" wt_setup )
  local setup_rc=$?
  unfunction wt_setup
  unset wt_dir
  if (( setup_rc != 0 )); then
    echo "wtnew: wt_setup failed (exit $setup_rc); worktree left at $wt_path for inspection" >&2
    return 1
  fi

  local label="[$name]"
  [[ -n $summary ]] && label="[$name] $summary"

  if [[ ${HERDR_ENV:-} == 1 ]]; then
    # --cwd anchors repo resolution; the default is the UI-focused workspace,
    # which may be a different repo entirely.
    herdr worktree open --cwd "$repo_root" --path "$wt_path" --label "$label" --focus
  else
    cd "$wt_path"
    echo "wtnew: $label ready at $wt_path"
  fi
}
