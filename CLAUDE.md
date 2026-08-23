# Dotfiles

Canonical config source. Single setup across macOS (Homebrew), Arch Linux (Pacman), and Ubuntu servers (apt + mise). All coding/terminal config changes go here.

## Principles

- **Canonical**: This repo is the source of truth. Every config change lands here first, then propagates via install.sh.
- **Cross-platform**: Single `install.sh` detects OS → picks right package manager.
- **Symlinks**: Configs symlinked from repo → standard paths. No copies.
- **Declarative**: Package lists and manifests over imperative scripts.
- **Minimal friction**: Plugin managers auto-install. One command setup.
- **Fast startup**: interactive startup paths are latency-budgeted. Work that forks or is slow (subprocess `eval`s, plugin loads, compinit) gets deferred past the first prompt or cached, never added synchronously; when touching a startup path, measure before/after (`/usr/bin/time zsh -i -c exit`). The zsh mechanics (turbo ordering, `_cached_eval`) live in the zshrc skill.
- **Durable docs**: Docs capture intent, patterns, and design decisions — not file trees or config values that agents can read directly.

## Colorblind-safe visuals

Justin is red-green color impaired (deuteranopia/protanopia family). Any palette or visual shipped by this repo (themes, terminal palettes, status colors, prompt colors) never uses a red-vs-green distinction to carry meaning: put opposed meanings on the blue-yellow or blue-orange axis instead, keep a luminance gap between them, and back color with a second channel (shape, label, position) where the medium allows. The verification recipe for terminal palettes (Vienot simulation, ΔE76 and contrast thresholds) lives in the terminal skill.

## Design

- `install.sh` — OS detection → packages → symlinks → plugin managers. Each section idempotent.
- Ubuntu = headless — an Ubuntu machine is an SSH-only VPS (desktop Linux is the Arch/Omarchy machine): GUI apps and Ghostty are skipped, and tools apt lacks or ships stale install through mise (`UBUNTU_MISE_PACKAGES` in install.sh).
- Machine profile — `.dotfiles-local` (gitignored) holds this machine's divergence from the shared setup: skip lists (`SKIP_MODULES`, `SKIP_PACKAGES`, `SKIP_APPS`, `SKIP_RULES`, `SKIP_SKILLS`), `KEEP_PLUGINS`, work-computer flag, Python provider. Opt-out, not opt-in, so a new module reaches every machine unless a machine says otherwise. install.sh appends a commented template listing every knob to fresh and pre-existing configs. The profile subtracts from the shared set; machine-only additions live in `KEEP_PLUGINS` and the machine-local mise config, deliberately, so the shared lists stay the only install source.
- Module dirs — Each subsystem owns a directory at repo root. Single-file configs (`zshrc`, `tmux.conf`) live at root.
- Agent conventions — `AGENTS.md → CLAUDE.md` and `.agents → .claude` are symlinks: `.claude/` and CLAUDE.md are canonical, the links serve tools that read the AGENTS convention. Edit the canonical side only.
- Agent skills — Most modules have a maintenance skill under `.agents/skills/<name>/SKILL.md` with structure, install flow, and common tasks; the dir matches the module name unless that collides with a skill the tool ships itself (herdr's is `herdr-config`, omarchy's `omarchy-config`). Agents discover them automatically; no need to list them here.

## Rules

- Fresh Ubuntu VPS: `sudo apt-get update && sudo apt-get install -y git zsh` first — install.sh runs under zsh and the repo arrives by git, so neither can bootstrap itself. Then clone and `./install.sh` (it switches the login shell to zsh).
- New module: create dir at repo root, add symlink + deps to `install.sh`.
- Names: lowercase, hyphens, no spaces.
- Symlinks: use XDG paths (`~/.config/`). Backup existing files before replacing.
- Test: new shell for zsh, new tmux session for tmux, manual for other tools.
- Run `./install.sh` to bootstrap or update.
