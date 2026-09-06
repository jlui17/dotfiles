# nvim

Owns `nvim/`, linked whole to `~/.config/nvim` by `setup_nvim`.

The config is a [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) fork. Everything lives in `nvim/init.lua`; grep `SECTION` to jump between its numbered blocks. Of the kickstart extras under `nvim/lua/kickstart/plugins/`, only `gitsigns` is loaded (SECTION 9); the rest stay commented out there.

Plugins are managed by Neovim's built-in `vim.pack` (0.12+), not a plugin manager plugin. Per-plugin build steps (telescope-fzf-native, LuaSnip, nvim-treesitter) hang off the `PackChanged` autocmd in SECTION 2. `nvim/nvim-pack-lock.json` is tracked, so a plugin update changes a committed file: commit the lockfile with the update.

Treesitter (SECTION 8) keeps the archived nvim-treesitter repo only as a parser installer. The rationale is commented inline at that section; read it there before changing the setup.

Mason (SECTION 5) auto-installs every server in the `servers` table on first launch, and several are built from a runtime that must already be on PATH: `gopls` from Go, `ts_ls` and `pyright` from Node. Those runtimes come from the mise module, so on a fresh machine run `./install.sh` before the first `nvim` launch. On Ubuntu, neovim itself also arrives through mise because apt's build predates `vim.pack`. See `resources/mise.md`.

`setup_nvim` prints the first-launch steps as a `note`; end with `:checkhealth`.

Yanks go out as OSC 52 through `nvim/lua/config/remote_clipboard.lua` so they reach the local clipboard across tmux, SSH, and herdr. Inside tmux this depends on the clipboard feature `tmux.conf` enables with `terminal-features ",*:clipboard"`.

Commands:

Update plugins, then commit the lockfile:

```
:lua vim.pack.update()
```

Inspect plugin state and pending updates without fetching:

```
:lua vim.pack.update(nil, { offline = true })
```

Server install status (`g?` for help in the menu), and the health check:

```
:Mason
:checkhealth
```
