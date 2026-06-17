---
name: mise
description: Global language runtimes (node, go, python) managed by mise — manifest symlinked to ~/.config/mise/config.toml.
---

[mise](https://mise.jdx.dev) manages global language runtime versions. The manifest `mise/config.toml` is symlinked to `~/.config/mise/config.toml` (mise's global config). `install.sh` runs `mise install` to realize it.

**Why this exists:** nvim's Mason auto-installs language servers on first launch, and several are built from a runtime that must already be on PATH — `gopls` needs Go, `ts_ls` and `pyright` need Node. Without global versions set, those installs fail. Pinning runtimes here makes a fresh machine's first `nvim` launch succeed. See [[nvim]].

**Install flow** (install.sh, PHASE 1b): symlinks `mise/config.toml` → `~/.config/mise/config.toml`, then `mise install`. Runs after `install_packages` (which installs the `mise` binary) so the runtimes are ready before nvim is ever opened. zsh activates mise via `eval "$(mise activate zsh)"` in `zshrc`.

**Tasks:**
- Add/bump a global runtime: edit `mise/config.toml`, re-run install.sh (or `mise install`)
- List installed versions: `mise ls`
- See what's active here: `mise current`
- Project-local override: `mise use node@22` in the project dir (writes a local `mise.toml`, not this file)
