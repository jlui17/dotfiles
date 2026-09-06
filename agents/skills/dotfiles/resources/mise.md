# mise

Owns global language runtimes via [mise](https://mise.jdx.dev). No repo directory: `setup_mise` in install.sh is the whole module.

`~/.config/mise/config.toml` is machine-local and untracked. `setup_mise` seeds a node/go/bun baseline only when the file is missing, so per-machine edits survive every run. That also means an existing machine is never re-seeded: a tool added to the baseline heredoc reaches new machines only, and existing ones need it added by hand.

The baseline exists for nvim's Mason servers, which build from these runtimes (`resources/nvim.md`), and bun is in it for the external-skills replay (`resources/agents.md`).

Python is machine-local, not in the shared baseline. `PYTHON_PROVIDER` in `.dotfiles-local` picks `uv` (default) or `system`. `system` is the escape hatch for locked-down machines whose security policy kills Astral's standalone binaries, which takes out both uv and mise-managed Python. The overlay mechanics and full rationale are in the comment block above `setup_mise`.

Two files under `~/.config/mise/conf.d/` are generated and overwritten on every run, so never hand-edit them:

- `dotfiles-python.toml`, written by `setup_mise` for the uv provider.
- `dotfiles-apt-gaps.toml`, written by `install_packages` on Ubuntu only. It carries the tools apt lacks or ships too old; the list and per-tool reasons live at `UBUNTU_MISE_PACKAGES` in install.sh. mise itself comes from its official apt repo, added in `install_packages`.

Interactive shells get mise from `mise activate zsh` in `zshrc`. install.sh never sources that; `setup_mise` puts mise-managed bins on the run's PATH with `mise env` so later modules (nvim's binary check, npm for the apps table) can find them.

Tasks:

- Add or bump a tool on this machine: edit `~/.config/mise/config.toml`, then `mise install`.
- Change the baseline new machines get: edit the seed heredoc in `setup_mise`.
- Bump Python: edit `MISE_PYTHON_VERSION` in install.sh, then rerun `./install.sh`.
- Debug a Mason server that fails on a fresh machine: check `mise ls` shows node and go, then `mise doctor`.
