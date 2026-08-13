---
name: zshrc
description: Use when adding a zsh plugin, alias, function, or prompt tweak; when shell startup gets slow or a completion or plugin is missing; or when editing zshrc or zsh-functions/.
---

Single zshrc with Zinit as the sole plugin manager. zsh-functions/ is a "drop-in" dir: any .sh file there is auto-sourced at shell startup, resolved at runtime relative to zshrc's location (no symlink).

**Startup is latency-tuned; keep new weight off the pre-prompt path.** Everything but p10k loads via zinit turbo (the `wait lucid for` block) after the first prompt, compinit included. Ordering inside that block is load-bearing: compinit (fzf-tab's atinit) must precede fzf-tab, fzf-tab must precede the widget-wrapping plugins (syntax-highlighting, autosuggestions), and `zicdreplay; zinit cdclear -q` must sit in the LAST entry's atload — zinit captures compdef calls made while sourcing each plugin into a replay list, so replaying earlier drops the later plugins' compdefs. A new plugin joins this block (respecting those constraints), not a sync `zinit light` line. Consequence of turbo: `zsh -ic '...'` never reaches a prompt, so turbo-loaded plugins and completions don't exist there.

**Shell integrations** (`eval "$(tool init ...)"`) go through `_cached_eval`, which sources a cached copy and regenerates in a scrubbed env when the tool's binary mtime moves; `update_pkgs` evicts the cache because shimmed/bottled binaries' mtimes don't track upgrades (the tradeoffs are commented at the definition in zshrc).

Machine-specific tweaks that must not be committed go in `~/.zshrc.local` (outside the repo; sourcing order is commented in zshrc). Example: a Mac with a broken `gitstatusd` sets `POWERLEVEL9K_DISABLE_GITSTATUS=true` there to make p10k fall back to plain git; pair it with deleting the stale `~/.cache/p10k-dump-*` so p10k re-inits and stops launching the daemon.

For prompt tweaks that p10k drives through `vcs_info` zstyles (e.g. branch-only, no dirty `!` marker via `check-for-changes false` + clearing the git hooks): p10k hardcodes `check-for-changes true` inside `_p9k_vcs_info_init`, which runs during init *before the first prompt*. A plain assignment is overwritten, and `p10k-on-init` runs too late (the first render still shows the marker). Wrap `_p9k_vcs_info_init` in `~/.zshrc.local` (it's defined when p10k loads, before init) and re-apply the zstyles after calling the original — then it holds from prompt #1.

**Install flow** (install.sh): symlinks zshrc → ~/.zshrc; skips on work computers (`IS_WORK_COMPUTER` in the gitignored `.dotfiles-local`). Zinit auto-clones + installs plugins on first shell launch. On Ubuntu servers it also runs `chsh` to make zsh the login shell.

**Tasks:**
- Add a new shell shortcut: decide alias vs. function first. A static command or `&&`-chain with no arguments, conditionals, or variables is an alias — add it to zshrc's Aliases section. Only use a zsh-functions/ file when the task needs parameters, branching, or logic beyond a simple chain (e.g. `cdotfiles`/`budgeting`, which `cd` then launch `claude`).
- Add function: drop .sh file in zsh-functions/ — auto-sourced. Register completions with compdef inside the file if needed; that works before compinit only because zshrc defines a stub queueing the call into zinit's replay list, so don't reorder the stub or the sourcing loop around it.
