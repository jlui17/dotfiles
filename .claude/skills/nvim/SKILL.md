---
name: nvim
description: Neovim config using kickstart.nvim with native vim.pack plugin management.
---

Uses [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) as a starting point. Plugin management via Neovim 0.11+ built-in `vim.pack`. Theme is [github-nvim-theme](https://github.com/projekt0n/github-nvim-theme) (github_dark_default). LSP/formatter installs via Mason.

**Structure:**
- `init.lua` — Main entry point. Single file with 9 sections:
  1. Foundation — options, keymaps, autocmds
  2. Plugin manager intro — vim.pack build hooks
  3. UI / Core UX — guess-indent, gitsigns (with `kickstart.plugins.gitsigns` keymaps active), which-key, github-nvim-theme, todo-comments, mini.nvim (ai, surround, statusline), render-markdown
  4. Search & Navigation — Telescope
  5. LSP — lspconfig, Mason, fidget (active servers: stylua, lua_ls, gopls, ts_ls, pyright)
  6. Formatting — conform.nvim
  7. Autocomplete & Snippets — blink.cmp, LuaSnip
  8. Treesitter — parser management via nvim-treesitter (archived, still used for `install()`) + native auto-attach highlighting
  9. Optional examples — kickstart.plugins.*, custom.plugins
- `lua/kickstart/health.lua` — Health check
- `lua/kickstart/plugins/*.lua` — Optional plugin configs (debug, indent_line, lint, autopairs, neo-tree, gitsigns)
- `lua/custom/plugins/init.lua` — User custom plugins entry point
- `doc/` — Help docs

**Install flow** (install.sh): symlinks entire `nvim/` → `~/.config/nvim`. Warns if dir exists and isn't our symlink. Post-install: open nvim and wait for vim.pack to fetch plugins, then `:checkhealth`.

**Design decisions:**
- **Treesitter (2026-05-16):** `nvim-treesitter` plugin is archived but still kept for parser `install()` rather than fully manual parser management. Neovim 0.10+ handles highlighting auto-attach natively — no need for the plugin's old attach logic. `nvim-treesitter` also provides the `indentexpr()` function and is expected by `render-markdown.nvim`. Documented inline in Section 8.

**Tasks:**
- Add plugin: add `vim.pack.add { gh 'user/repo' }` to relevant `init.lua` section, then `require('plugin').setup {}`
- Change theme: swap the `vim.pack.add` line for the colorscheme plugin and `vim.cmd.colorscheme` call in Section 3
- Add LSP server: add to the `servers` table in Section 5
- Add formatter: add filetype→formatter mapping in the `conform` setup block in Section 6
- Update plugins: `:lua vim.pack.update()`
- Check plugin state (offline): `:lua vim.pack.update(nil, { offline = true })`
- Health check: `:checkhealth`
