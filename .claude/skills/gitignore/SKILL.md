---
name: gitignore
description: Use when adding or changing a global git ignore pattern, or when a file that should be ignored in every repo still shows up in git status.
---

Global gitignore sits at `~/.config/git/ignore`, symlinked from `gitignore/ignore` in the repo. Git reads it automatically per XDG spec — no `git config` needed.

**Install flow** (install.sh): symlinks `gitignore/ignore` → `~/.config/git/ignore`. Backs up existing non-symlink.

**Tasks:**
- Add global ignore: edit `gitignore/ignore` in the repo — it's symlinked, so the edit is live immediately (install.sh only needed if the symlink is missing)
- List current ignores: read `~/.config/git/ignore`; `git check-ignore -v <path>` shows which rule ignores a path. If global ignores don't apply, check `git config --global core.excludesfile` — a set value replaces the XDG path.
- Per-repo ignore: use `.gitignore` in the repo root (not this file)
