---
name: mise
description: Global language runtimes (node, go) managed by mise, plus a machine-local Python provider (uv or system). Use when changing runtime or Python versions, switching the Python provider, editing mise config, or debugging Mason/LSP server install failures on a fresh machine.
---

[mise](https://mise.jdx.dev) manages global language runtime versions. `~/.config/mise/config.toml` (node, go) is machine-local and untracked; `install.sh` seeds a node/go baseline on a fresh machine (never clobbering an existing one) and runs `mise install` to realize it.

**Why this exists:** nvim's Mason auto-installs language servers on first launch, and several are built from a runtime that must already be on PATH — `gopls` needs Go, `ts_ls` and `pyright` need Node. Without global versions set, those installs fail. Pinning runtimes here makes a fresh machine's first `nvim` launch succeed. See [[nvim]].

**Python is machine-local, not in the shared manifest.** `PYTHON_PROVIDER` in `.dotfiles-local` (gitignored) picks `uv` (default) or `system`, the escape hatch for locked-down machines whose security policy SIGKILLs Astral's standalone binaries (that kills both uv and mise-managed Python). Full rationale, overlay mechanics, and the version pin live at `setup_mise` in install.sh.

**Install flow**: `setup_mise` in install.sh (PHASE 1b). zsh activates mise via `eval "$(mise activate zsh)"` in `zshrc`.

**Ubuntu servers lean harder on mise.** Tools apt lacks or ships stale are routed to `conf.d/dotfiles-apt-gaps.toml` (regenerated every run) and realized by the same `mise install`; the list and per-tool reasons live at `UBUNTU_MISE_PACKAGES` in install.sh. mise itself installs from its official apt repo.

**Tasks:**
- Add/bump a tool on this machine: edit `~/.config/mise/config.toml`, then `mise install`
- Change the baseline new machines get: edit the seed heredoc in `setup_mise` (`install.sh`)
- Bump Python: edit `MISE_PYTHON_VERSION` in `install.sh`
