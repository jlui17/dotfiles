#!/bin/zsh

# add covers a machine without mdnote, update moves an existing install: bun's
# global lockfile pins the commit, so a repeated add never re-resolves. stop,
# because a running server keeps the frontend it bundled at startup.
function update_mdnote() {
    local installed="${BUN_INSTALL:-$HOME/.bun}/install/global/node_modules/mdnote"
    # A bun link is a dev checkout; the install would replace it.
    if [[ -L "$installed" ]]; then
        echo "mdnote: linked to $(readlink "$installed"), skipped"
        return
    fi
    bun add -g github:jlui17/mdnote && bun update -g mdnote && mdnote stop
}
