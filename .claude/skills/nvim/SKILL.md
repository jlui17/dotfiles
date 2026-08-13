---
name: nvim
description: Use when adding or configuring a Neovim plugin, LSP server, formatter, or theme; when editing init.lua; or when debugging a plugin or Mason install failure.
---

Uses [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) as a starting point. Plugin management via Neovim 0.11+ built-in `vim.pack`. LSP/formatter installs via Mason.

**Structure:** everything lives in `init.lua`; grep `SECTION` to jump. `kickstart.plugins.gitsigns` is the one required kickstart extra.

**Install flow** (install.sh): symlinks entire `nvim/` → `~/.config/nvim`. Warns if dir exists and isn't our symlink. Post-install: open nvim and wait for vim.pack to fetch plugins, then `:checkhealth`.

Mason builds the active servers from runtimes that must be on PATH first — `gopls` from Go, `ts_ls`/`pyright` from Node. Those global runtimes are provisioned by the [[mise]] module, so on a fresh machine run install.sh before the first nvim launch.

**Design decisions:** the treesitter setup is deliberate (archived nvim-treesitter kept for parser `install()` only); rationale is commented inline at Section 8 in init.lua.

**Tasks:**
- Update plugins: `:lua vim.pack.update()`
- Check plugin state (offline): `:lua vim.pack.update(nil, { offline = true })`
- Health check: `:checkhealth`
