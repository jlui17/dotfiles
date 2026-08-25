# slk: plain Go repo; no env files, deps, or codegen. The test tooling
# (tools/go.sh, tools/smoke.sh, tools/run-docker.sh) self-seeds its docker
# image and sandbox volumes on first use, so the hook only front-loads the
# slow one-time pieces and proves the worktree can run tests at all.
wt_setup() {
  if ! command -v docker >/dev/null || ! docker info >/dev/null 2>&1; then
    echo "wt_setup(slk): docker unavailable — test tooling (tools/go.sh) needs it on Santa hosts" >&2
    return 0
  fi
  # Builds the slk-go image on a fresh machine; ~1s warm. A failure here
  # means the worktree can't run tests, which is worth hearing about now.
  tools/go.sh vet ./... >/dev/null || echo "wt_setup(slk): tools/go.sh vet failed; test tooling is broken in this worktree" >&2
}
