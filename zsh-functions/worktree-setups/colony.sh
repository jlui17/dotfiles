# colony owns worktree creation in scripts/worktree.sh: latest-origin-tip
# guard, stack-index registry, .env copy, per-stack port scheme. Delegate
# wholesale; a "local main is behind" refusal is the repo's own guard — pull
# main and re-run rather than bypassing it.
wt_create() {
  "$REPO_ROOT/scripts/worktree.sh" new "$BRANCH"
}
