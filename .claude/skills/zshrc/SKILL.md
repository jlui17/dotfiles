---
name: zshrc
description: Zsh config using Zinit plugin manager with custom functions in zsh-functions/. Use when adding zsh plugins, aliases, functions, or prompt/p10k tweaks.
---

Single zshrc with Zinit as the sole plugin manager. zsh-functions/ is a "drop-in" dir — any .sh file there is auto-sourced at shell startup (NULL_GLOB glob in zshrc). No symlink for zsh-functions/, it's resolved at runtime relative to zshrc's location.

Machine-specific tweaks that must not be committed go in `~/.zshrc.local` (outside the repo, sourced **last** in zshrc so it overrides everything above). It must come after `~/.p10k.zsh`, which on load wipes every `POWERLEVEL9K_*` var (`unset -m '(POWERLEVEL9K_*|...)'`) — any p10k override set earlier is erased. Example: a Mac with a broken `gitstatusd` sets `POWERLEVEL9K_DISABLE_GITSTATUS=true` there to make p10k fall back to plain git; pair it with deleting the stale `~/.cache/p10k-dump-*` so p10k re-inits and stops launching the daemon.

For prompt tweaks that p10k drives through `vcs_info` zstyles (e.g. branch-only, no dirty `!` marker via `check-for-changes false` + clearing the git hooks): p10k hardcodes `check-for-changes true` inside `_p9k_vcs_info_init`, which runs during init *before the first prompt*. A plain assignment is overwritten, and `p10k-on-init` runs too late (the first render still shows the marker). Wrap `_p9k_vcs_info_init` in `~/.zshrc.local` (it's defined when p10k loads, before init) and re-apply the zstyles after calling the original — then it holds from prompt #1.

**Install flow** (install.sh): symlinks zshrc → ~/.zshrc. Skips on work computers — determined by a one-time prompt persisted to the gitignored `.dotfiles-local` (`IS_WORK_COMPUTER`); delete that file to be re-prompted. Zinit auto-clones + installs plugins on first shell launch.

**Tasks:**
- Add plugin: add `zinit light user/repo` to zshrc, source ~/.zshrc
- Change prompt: `p10k configure` or edit ~/.p10k.zsh
- Add a new shell shortcut: decide alias vs. function first. A static command or `&&`-chain with no arguments, conditionals, or variables is an alias — add it to zshrc's Aliases section. Only use a zsh-functions/ file when the task needs parameters, branching, or logic beyond a simple chain (e.g. `cdotfiles`/`budgeting`, which `cd` then launch `claude`).
- Add function: drop .sh file in zsh-functions/ — auto-sourced. Register completions with compdef inside the file if needed.
