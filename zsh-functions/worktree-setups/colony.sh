# .env is gitignored and compose/service scripts read it from the worktree
# (colony's scripts/worktree.sh cmd_new does the same copy). Docker-stack
# isolation (port offsets, stack registry) stays owned by scripts/worktree.sh;
# a wtnew worktree has no stack index, so use that script for stack work.
wt_setup() {
  [ -f "$REPO_ROOT/.env" ] && cp "$REPO_ROOT/.env" "$WORKTREE_PATH/.env"
  return 0
}
