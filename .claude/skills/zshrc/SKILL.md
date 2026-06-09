---
name: zshrc
description: Zsh config using Zinit plugin manager with custom functions in zsh-functions/.
---

Single zshrc with Zinit as the sole plugin manager. zsh-functions/ is a "drop-in" dir — any .sh file there is auto-sourced at shell startup (NULL_GLOB glob in zshrc). No symlink for zsh-functions/, it's resolved at runtime relative to zshrc's location.

**Install flow** (install.sh): symlinks zshrc → ~/.zshrc. Skips on work computers — determined by a one-time prompt persisted to the gitignored `.dotfiles-local` (`IS_WORK_COMPUTER`); delete that file to be re-prompted. Zinit auto-clones + installs plugins on first shell launch.

**Tasks:**
- Add plugin: add `zinit light user/repo` to zshrc, source ~/.zshrc
- Change prompt: `p10k configure` or edit ~/.p10k.zsh
- Add alias or env var: edit zshrc, source ~/.zshrc
- Add function: drop .sh file in zsh-functions/ — auto-sourced. Register completions with compdef inside the file if needed.
- Modify function: edit file in zsh-functions/, update compdef lines if completions changed, source ~/.zshrc
