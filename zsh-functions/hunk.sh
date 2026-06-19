#!/bin/zsh

alias hd='hunk diff --exclude-untracked'
alias hdu='hunk diff'

function hdm() {
    hunk diff "main...$1"
}

function _hdm() {
    local branches
    branches=(${(f)"$(git branch --format='%(refname:short)' 2>/dev/null)"})
    compadd -a branches
}
compdef _hdm hdm
