#!/bin/zsh

alias hd='hunk diff --exclude-untracked'
alias hdu='hunk diff'

# origin/main, not main: a stale local main shows everything merged since the
# last pull as phantom branch changes.
function hdm() {
    git fetch origin main >/dev/null 2>&1
    hunk diff "origin/main...$1"
}

function _hdm() {
    local branches
    branches=(${(f)"$(git branch --format='%(refname:short)' 2>/dev/null)"})
    compadd -a branches
}
compdef _hdm hdm
