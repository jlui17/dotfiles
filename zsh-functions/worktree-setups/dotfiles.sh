# Contract (this file doubles as the template for new repos): define exactly
# one of wt_setup (runs inside the fresh worktree after wtnew's own `git
# worktree add`) or wt_create (owns creation, for a repo with its own worktree
# tooling — see colony.sh). Both run with REPO_ROOT, WORKTREE_PATH, and BRANCH
# set; an optional wt_dir=<repo-relative dir> overrides the .worktrees default.
wt_setup() {
  :  # dotfiles needs no per-worktree setup
}
