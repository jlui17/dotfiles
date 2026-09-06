# zshrc

Owns `zshrc` (linked to `~/.zshrc` by `setup_zshrc`) and `zsh-functions/`, the drop-in dir zshrc sources at startup. Zinit is the only plugin manager.

## Machine profile

`IS_WORK_COMPUTER=true` makes `setup_zshrc` skip the symlink entirely. Since `zsh-functions/` is sourced by zshrc, nothing in this module reaches a work machine. On Ubuntu the function also runs `chsh` so SSH logins land in zsh.

Machine-only tweaks go in `~/.zshrc.local`, outside the repo. zshrc sources it after `~/.p10k.zsh` (which wipes every `POWERLEVEL9K_*` var when it loads) and after the function files, so it wins over both. Only the zoxide init and the OpenClaw lines run after it. Two patterns that live there:

- A Mac with a broken `gitstatusd`: set `POWERLEVEL9K_DISABLE_GITSTATUS=true`, then delete `~/.cache/p10k-dump-*` so p10k re-inits and stops launching the daemon.
- Prompt tweaks driven through `vcs_info` zstyles (branch only, no dirty marker via `check-for-changes false` and clearing the git hooks): p10k hardcodes `check-for-changes true` inside `_p9k_vcs_info_init`, which runs during init before the first prompt. A plain zstyle is overwritten, and `p10k-on-init` runs too late for the first render. Wrap `_p9k_vcs_info_init` (defined once p10k loads, before init) and re-apply the zstyles after calling the original.

## Turbo block

Everything except p10k loads in the `zinit wait lucid light-mode for` block after the first prompt, compinit included. A new plugin joins that block; never add a synchronous `zinit light` line. The ordering is load-bearing; the comment above the block states it.

Consequence: `zsh -ic '...'` exits before the first prompt, so turbo-loaded plugins and completions do not exist there. Test in a real interactive shell.

## Startup telemetry

Every interactive shell appends one line to `~/.cache/zsh-startup-log.tsv`: rc, first-prompt and turbo-done milliseconds, load averages, claude process count, terminal context, and the cold-path flags (`full_compinit`, `regen`). Read it before any live measurement when startup feels slow. It separates system load from the two cold paths: the daily full compinit pass and `_cached_eval` regeneration.

## Shell integrations

Every `eval "$(tool init ...)"` goes through `_cached_eval`, defined in zshrc. It sources a cached copy and regenerates in a scrubbed env when the tool binary's mtime moves; the tradeoffs are in the comment at the definition. `update_pkgs` deletes the cache dir because mise shims and Homebrew bottles keep mtimes that do not track upgrades. A newly cached tool that ignores its env config (zoxide's `_ZO_*` vars) is the scrub working as designed.

Cross-module: `UBUNTU_MISE_PACKAGES` in install.sh routes fzf and zoxide through mise because the flags zshrc passes (`fzf --zsh`, `zoxide init --cmd cd`) need versions newer than LTS apt ships. Changing those init lines means re-checking that table.

## Aliases and functions

Decide alias vs. function first. A static command or `&&` chain with no arguments, branching, or variables is an alias in zshrc's Aliases section. A `zsh-functions/*.sh` file is for logic that needs parameters or conditionals.

`zsh-functions/` files are sourced by path resolved from zshrc's real location (`DOTFILES_DIR` in zshrc), so they need no symlink and no install.sh entry. Only top-level `*.sh` files are sourced; `zsh-functions/worktree-setups/` holds per-repo setup hooks read by `wtnew`, owned by the `worktrees` skill.

A function file registers its completion with `compdef` inline. That works before compinit only because zshrc defines a `compdef` stub that queues the call into zinit's replay list. The stub must stay between the turbo block and the sourcing loop; do not reorder them.

After adding a tool with completions, or when a completion is missing, run `update_zcomp` instead of waiting for the daily full compinit pass. It deletes the dump and `exec`s a new shell, because re-running compinit in place would lose the queued compdefs.
