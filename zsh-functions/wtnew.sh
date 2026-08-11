#!/bin/zsh

# wtnew <name> [summary...] — start a task: worktree + per-repo setup + herdr space
#
# Creates <repo>/.worktrees/<name> on a new branch <name>, runs the repo's
# setup from worktree-setups/<repo>.sh, then opens a herdr space labeled
# "[<name>] <summary>" bound to the worktree (or cd's there outside herdr).
# Refuses to run on a repo with no setup file, so an unknown repo can never
# produce a silently half-set-up worktree.
#
# A setup file defines exactly one of two hooks:
#   wt_setup()  — post-create: wtnew does `git worktree add -b` itself, then
#                 runs this inside the fresh worktree.
#   wt_create() — owns creation: the repo has its own worktree tooling and
#                 this delegates to it (e.g. colony's scripts/worktree.sh new).
#                 Runs from the repo root; must leave a worktree at
#                 $WORKTREE_PATH on branch $BRANCH.
# Both run in a subshell with REPO_ROOT, WORKTREE_PATH, and BRANCH set.

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
  unfunction wt_setup wt_create 2>/dev/null
  source "$setup_file" || { echo "wtnew: failed to source $setup_file" >&2; return 1 }
  local has_setup=0 has_create=0
  typeset -f wt_setup >/dev/null && has_setup=1
  typeset -f wt_create >/dev/null && has_create=1
  if (( has_setup + has_create != 1 )); then
    echo "wtnew: $setup_file must define exactly one of wt_setup() or wt_create()" >&2
    unfunction wt_setup wt_create 2>/dev/null
    return 1
  fi

  local wt_path="$repo_root/${wt_dir:-.worktrees}/$name"
  local setup_rc=0
  if (( has_create )); then
    # The repo's own tooling owns creation end to end; wtnew only binds the
    # space afterward. Subshell so its cd/env never touch the interactive shell.
    ( cd "$repo_root" && REPO_ROOT="$repo_root" WORKTREE_PATH="$wt_path" BRANCH="$name" wt_create )
    setup_rc=$?
    unfunction wt_create
    unset wt_dir
    if (( setup_rc != 0 )); then
      echo "wtnew: wt_create failed (exit $setup_rc)" >&2
      return 1
    fi
    if [[ ! -d $wt_path ]]; then
      echo "wtnew: wt_create succeeded but left no worktree at $wt_path" >&2
      return 1
    fi
  else
    if ! git -C "$repo_root" worktree add "$wt_path" -b "$name"; then
      unfunction wt_setup
      unset wt_dir
      return 1
    fi

    # Subshell so wt_setup's cd/env never touch the interactive shell.
    ( cd "$wt_path" && REPO_ROOT="$repo_root" WORKTREE_PATH="$wt_path" BRANCH="$name" wt_setup )
    setup_rc=$?
    unfunction wt_setup
    unset wt_dir
    if (( setup_rc != 0 )); then
      echo "wtnew: wt_setup failed (exit $setup_rc); worktree left at $wt_path for inspection" >&2
      return 1
    fi
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
