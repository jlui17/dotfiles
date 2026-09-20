# The isolated preview script supplies development auth and local storage.
# A fresh worktree needs dependencies, not production environment files.
wt_setup() {
  bun install --frozen-lockfile
}
