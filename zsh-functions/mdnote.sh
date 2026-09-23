#!/bin/zsh

# add covers a machine without mdnote, update moves an existing install: bun's
# global lockfile pins the commit, so a repeated add never re-resolves. stop,
# because a running server keeps the frontend it bundled at startup. None of it
# runs when the pinned commit is already the remote head, so a run with nothing
# new leaves a running server alone.
function update_mdnote() {
    local installed="${BUN_INSTALL:-$HOME/.bun}/install/global/node_modules/mdnote"
    # A bun link is a dev checkout; the install would replace it.
    if [[ -L "$installed" ]]; then
        echo "mdnote: linked to $(readlink "$installed"), skipped"
        return
    fi
    local installed_commit remote_commit
    installed_commit="$(mdnote_installed_commit)"
    remote_commit="$(git ls-remote https://github.com/jlui17/mdnote HEAD)" || return
    # By prefix: the lockfile holds a short sha, ls-remote prints the full one.
    if [[ -n "$installed_commit" && "$remote_commit" == "$installed_commit"* ]]; then
        echo "mdnote: already at $installed_commit, skipped"
        return
    fi
    bun add -g github:jlui17/mdnote && bun update -g mdnote && mdnote stop || return
    echo "mdnote: ${installed_commit:-none} → $(mdnote_installed_commit)"
}

# The commit bun's global lockfile pins, read from its entry
# "mdnote@github:jlui17/mdnote#37a68f5". Prints nothing when mdnote is not
# installed from GitHub (no install, or a bun link).
function mdnote_installed_commit() {
    sed -n 's|.*"mdnote@github:jlui17/mdnote#\([0-9a-f]*\)".*|\1|p' \
        "${BUN_INSTALL:-$HOME/.bun}/install/global/bun.lock" 2>/dev/null
}
