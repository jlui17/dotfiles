---
name: nvim
description: Neovim config using kickstart.nvim with native vim.pack plugin management. Use when adding or configuring plugins, LSP servers, formatters, or the theme, or when debugging plugin/Mason install failures.
---

Uses [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) as a starting point. Plugin management via Neovim 0.11+ built-in `vim.pack`. LSP/formatter installs via Mason.

**Structure:** everything lives in `init.lua`, one file split by `-- SECTION N:` headers: 1 foundation (options, keymaps, autocmds), 2 plugin manager, 3 UI/core UX, 4 search & navigation (Telescope), 5 LSP (Mason + `servers` table), 6 formatting (conform), 7 completion (blink.cmp + LuaSnip), 8 treesitter, 9 optional kickstart/custom extras. Grep `SECTION` to jump; plugin and server inventories are the `vim.pack.add` calls and `servers` table in the file. Optional kickstart plugin files live in `lua/kickstart/plugins/`; `kickstart.plugins.gitsigns` is the one actually required (it adds the recommended gitsigns keymaps).

**Install flow** (install.sh): symlinks entire `nvim/` → `~/.config/nvim`. Warns if dir exists and isn't our symlink. Post-install: open nvim and wait for vim.pack to fetch plugins, then `:checkhealth`.

Mason builds the active servers from runtimes that must be on PATH first — `gopls` from Go, `ts_ls`/`pyright` from Node. Those global runtimes are provisioned by the [[mise]] module, so on a fresh machine run install.sh before the first nvim launch.

**Design decisions:** the treesitter setup is deliberate (archived nvim-treesitter kept for parser `install()` only); rationale is commented inline at Section 8 in init.lua.

**Tasks:**
- Add plugin: add `vim.pack.add { gh 'user/repo' }` to relevant `init.lua` section, then `require('plugin').setup {}`
- Change theme: swap the `vim.pack.add` line for the colorscheme plugin and `vim.cmd.colorscheme` call in Section 3
- Add LSP server: add to the `servers` table in Section 5
- Add formatter: add filetype→formatter mapping in the `conform` setup block in Section 6
- Update plugins: `:lua vim.pack.update()`
- Check plugin state (offline): `:lua vim.pack.update(nil, { offline = true })`
- Health check: `:checkhealth`
