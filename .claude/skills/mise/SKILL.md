---
name: mise
description: Global language runtimes (node, go) managed by mise + a machine-local Python provider (uv or system). Manifest symlinked to ~/.config/mise/config.toml.
---

[mise](https://mise.jdx.dev) manages global language runtime versions. The shared manifest `mise/config.toml` (node, go) is symlinked to `~/.config/mise/config.toml`. `install.sh` runs `mise install` to realize it.

**Why this exists:** nvim's Mason auto-installs language servers on first launch, and several are built from a runtime that must already be on PATH — `gopls` needs Go, `ts_ls` and `pyright` need Node. Without global versions set, those installs fail. Pinning runtimes here makes a fresh machine's first `nvim` launch succeed. See [[nvim]].

**Python is machine-local, not in the shared manifest.** `PYTHON_PROVIDER` in `.dotfiles-local` (gitignored) picks the strategy; `setup_mise` acts on it. Default is `uv`.
- `uv` — `setup_mise` writes a `~/.config/mise/conf.d/dotfiles-python.toml` overlay adding `uv`, then `uv python install` + `uv python pin --global` the version in `MISE_PYTHON_VERSION` (3.12; Python has no real LTS). Python lands under uv, used by `uv run`/`uv venv`.
- `system` — for locked-down machines whose security policy **SIGKILLs Astral's standalone binaries**. That kills both the `uv` binary *and* mise-managed Python (mise downloads python-build-standalone, also Astral), so neither works there. `setup_mise` removes the overlay and installs Python via the OS package manager instead (`brew install python@3.12` / `pacman -S python`), which is notarized and allowed.

Either way pyright/ts_ls/gopls are Node/Go-based, so nvim's LSP is unaffected by the Python choice.

**conf.d overlays:** mise merges every `~/.config/mise/conf.d/*.toml` on top of the global config. The overlay is generated per-machine and never committed, keeping the shared manifest machine-agnostic.

**Install flow** (install.sh, PHASE 1b): symlink `mise/config.toml`, resolve `PYTHON_PROVIDER`, write/remove the overlay, `mise install`, then the provider-specific Python step. Runs after `install_packages` (installs the `mise` binary). zsh activates mise via `eval "$(mise activate zsh)"` in `zshrc`.

**Tasks:**
- Switch a machine off uv: set `PYTHON_PROVIDER=system` in `.dotfiles-local`, re-run install.sh
- Add/bump a shared runtime: edit `mise/config.toml`, re-run install.sh (or `mise install`)
- Bump Python: edit `MISE_PYTHON_VERSION` in `install.sh`
- List installed versions: `mise ls` · what's active here: `mise current`
- Project-local override: `mise use node@22` in the project dir (writes a local `mise.toml`, not the shared file)
