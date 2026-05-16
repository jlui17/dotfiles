---
name: gitignore
description: Global gitignore configuration — XDG path under ~/.config/git/ignore, symlinked from dotfiles.
---

Global gitignore sits at `~/.config/git/ignore`, symlinked from `gitignore/ignore` in the repo. Git reads it automatically per XDG spec — no `git config` needed.

**Install flow** (install.sh): symlinks `gitignore/ignore` → `~/.config/git/ignore`. Backs up existing non-symlink.

**Tasks:**
- Add global ignore: edit `gitignore/ignore` in the repo; re-run install.sh to re-link
- List current ignores: `git config --global core.excludesfile` or check `~/.config/git/ignore`
- Per-repo ignore: use `.gitignore` in the repo root (not this file)
