function gswf() {
    git switch $(git branch | cut -c 3- | fzf -1 -q "$1");
}