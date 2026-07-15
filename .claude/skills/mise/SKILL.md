---
name: mise
description: Global language runtimes (node, go) managed by mise, plus a machine-local Python provider (uv or system). Use when changing runtime or Python versions, switching the Python provider, editing mise config, or debugging Mason/LSP server install failures on a fresh machine.
---

[mise](https://mise.jdx.dev) manages global language runtime versions. `~/.config/mise/config.toml` (node, go) is machine-local and untracked: `install.sh` seeds a node/go baseline on a fresh machine (never clobbering an existing one), so per-machine tools stay out of the shared repo. `install.sh` then runs `mise install` to realize it.

**Why this exists:** nvim's Mason auto-installs language servers on first launch, and several are built from a runtime that must already be on PATH — `gopls` needs Go, `ts_ls` and `pyright` need Node. Without global versions set, those installs fail. Pinning runtimes here makes a fresh machine's first `nvim` launch succeed. See [[nvim]].

**Python is machine-local, not in the shared manifest.** `PYTHON_PROVIDER` in `.dotfiles-local` (gitignored) picks `uv` (default; Python lands under uv, used by `uv run`/`uv venv`) or `system` (for locked-down machines whose security policy SIGKILLs Astral's standalone binaries; that kills both uv and mise-managed Python, so the OS package manager installs it instead). Full rationale, overlay mechanics, and the version pin live at `setup_mise` in install.sh. Either way nvim's LSP servers are Node/Go-based, so they're unaffected by the Python choice.

**Install flow** (install.sh, PHASE 1b, `setup_mise`): seed the baseline if absent, write/remove the Python overlay per `PYTHON_PROVIDER`, `mise install`, then the provider-specific Python step. zsh activates mise via `eval "$(mise activate zsh)"` in `zshrc`.

**Tasks:**
- Switch a machine off uv: set `PYTHON_PROVIDER=system` in `.dotfiles-local`, re-run install.sh
- Add/bump a tool on this machine: edit `~/.config/mise/config.toml`, then `mise install`
- Change the baseline new machines get: edit the seed heredoc in `setup_mise` (`install.sh`)
- Bump Python: edit `MISE_PYTHON_VERSION` in `install.sh`
- List installed versions: `mise ls` · what's active here: `mise current`
- Project-local override: `mise use node@22` in the project dir (writes a local `mise.toml`, not the shared file)
