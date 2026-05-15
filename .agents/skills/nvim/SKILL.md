---
name: nvim
description: Neovim config using NvChad v2.5 as a plugin with lazy.nvim.
---

NvChad is imported as a plugin (stable v2.5 branch). Config overrides live in lua/ — chadrc.lua for UI/theme, plugins/init.lua for plugin specs, configs/ for per-plugin options. This means upstream NvChad improvements come in via lazy.nvim updates.

**Install flow** (install.sh): symlinks entire nvim/ → ~/.config/nvim. Warns if dir exists and isn't our symlink. Post-install: `nvim +'Lazy sync'` + `:MasonInstallAll`.

**Tasks:**
- Add plugin: add spec to lua/plugins/init.lua (lazy.nvim format), `:Lazy lock` to update lazy-lock.json
- Change theme: set M.base46.theme in lua/chadrc.lua; `:Lazy reload base46` or restart
- Add LSP server: add to servers list in lua/configs/lspconfig.lua; install binary via :Mason if needed
- Add formatter: add filetype→formatter mapping in lua/configs/conform.lua
- Change options/keymaps: edit lua/options.lua or lua/mappings.lua
- Sync plugins: `:Lazy` → S, or `nvim +'Lazy sync' +qa`
