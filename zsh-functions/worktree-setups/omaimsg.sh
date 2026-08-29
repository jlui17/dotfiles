# Omaimsg has no worktree tooling of its own; a fresh checkout just needs
# deps (README "Contributing"). The repo is a bun workspace: `npm install`
# writes a package-lock.json the repo does not track.
wt_setup() {
  bun install
}
