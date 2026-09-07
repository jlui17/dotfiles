---
name: dotfiles
description: Use for Justin's dotfiles: a change to his machine setup (shell, terminal, editor, runtimes, desktop) or to the global context his agents read (skills, CLAUDE.md, AGENTS.md, rules, plugins, settings, Codex config); a new machine to set up or an edit to install.sh; or a deployed config, skill, or rule that reverts after install.sh runs.
---

# Justin's dotfiles

`~/src/personal/dotfiles` is the canonical source for every machine Justin uses: macOS laptops, the Arch/Omarchy desktop (`sfx`), and the Ubuntu VPS (`srv`, headless). `install.sh` deploys it. Configuration is changed in the repo and never in the deployed files. For operating those machines over the tailnet (SSH users, what runs where), use the `dev-machines` skill; this skill is about the setup itself.

## The loop

1. Edit the source in the repo, in the module that owns it (table below).
2. Run `./install.sh` from `~/src/personal/dotfiles`. Symlinked files are live the moment they are edited. The run matters for a new or deleted file (its link is created or pruned) and for what is generated, merged, or replayed (the global rules files, settings.json, plugins, external skills, the Codex block). It is idempotent and prints one result line per module; the full log is `/tmp/dotfiles-install.log`.
3. Verify with the module's own check (each resource names it), then commit. Changes reach other machines when they pull and run `./install.sh`.

Deployed files that look editable are not: `~/CLAUDE.md` and `~/.codex/AGENTS.md` are generated and overwritten on every run, `~/.claude/settings.json` has its repo-declared keys re-asserted, `~/.codex/config.toml` has a managed block that is rewritten. Trace a file back to its module before editing it; `readlink` on a symlink names the source.

## Invariants

- **The repo is the source; the machine is a target.** A change that lands only on a machine is lost on the next run or the next machine.
- **Symlinks over copies, manifests over scripts.** A config is linked to its XDG path. Packages, apps, plugins, and external skills are lists that install.sh replays.
- **The machine profile is opt-out.** `.dotfiles-local` (gitignored, in the repo root) holds a machine's divergence; the template install.sh appends to it lists every knob. A new module reaches every machine unless a machine says otherwise. The profile only subtracts; machine-only additions live in `KEEP_PLUGINS`, `agents/rules.d/99-local.md`, `claude-code/settings.local.json`, `~/.zshrc.local`, and the machine-local mise config, so the shared lists stay the only install source.
- **Ubuntu is headless.** GUI apps and Ghostty are skipped there, and tools apt lacks or ships stale come through mise (`UBUNTU_MISE_PACKAGES`).
- **Startup is latency-budgeted.** Nothing slow joins the interactive shell's pre-prompt path. Measure with `/usr/bin/time zsh -i -c exit` before and after; that covers the rc chain only, and the startup telemetry log covers the deferred plugin loads. Mechanics in `resources/zshrc.md`.
- **Palettes are colorblind-safe.** The rule is in the global `~/CLAUDE.md`; the verification recipe for a palette is in `resources/terminal.md` and applies to every theme this repo ships (Ghostty, herdr, Omarchy).
- **Code says what, docs say why.** Deterministic behavior is read from install.sh and the configs, not from prose. A resource points at the function or file and carries only what the code cannot say.

## install.sh

Every module is a `name:function[:os,os]` entry in the `MODULES` registry; main filters by OS and runs each through `run_module`, which honors `SKIP_MODULES`. Shared helpers do the work and the reporting: `backup_and_link` (symlink with backup, records what changed), `prune_stale_links` (removes repo-pointing links no longer wanted), `merge_json`, `install_generated_file`, `track` (a fallible command, logged, failure recorded). The terminal is the exception and the log is the default: a module reaches the screen only through the output API in `resources/installer.md`, and a bare `echo` lands in the log. The full contract, the traps, adding a module, and how to verify an output change are there too. Read it before editing install.sh.

Run install.sh from the main checkout only; `resources/installer.md` says why a worktree run dies.

## Where a change lands

| Ask | Module | Read |
| --- | --- | --- |
| Global skill (add, edit, remove, hide on one machine), external skill, global CLAUDE.md, AGENTS.md, shared rules | `agents/` | `resources/agents.md` |
| Claude-only rule fragment, output style, slash command, Claude Code settings or plugins | `claude-code/` | `resources/claude-code.md` |
| Codex config, MCP servers | `codex/` | `resources/codex.md` |
| zsh alias, function, plugin, prompt, startup time | `zshrc`, `zsh-functions/` | `resources/zshrc.md` |
| tmux, Ghostty, terminal theme | `tmux.conf`, `ghostty/` | `resources/terminal.md` |
| Neovim plugin, LSP, formatter | `nvim/` | `resources/nvim.md` |
| Language runtime, Python version | machine-local mise config, `setup_mise` | `resources/mise.md` |
| Hyprland binding, Omarchy theme, shell rendering on NVIDIA | `omarchy/` | `resources/omarchy.md` |
| herdr keybinding, theme, sidebar | `herdr/` | `resources/herdr.md` |
| OpenCode MCP server, credentials | `opencode/` | `resources/opencode.md` |
| t3 server update or supervision on sfx or the VPS | `t3/` | `resources/t3.md` |
| install.sh itself, a new module, installer output | `install.sh` | `resources/installer.md` |
| Global gitignore pattern | `gitignore/ignore` | live on edit (symlinked to `~/.config/git/ignore`); `git check-ignore -v <path>` shows which rule matched, and a set `core.excludesfile` overrides the XDG path |
| CLI package or GUI app | `COMMON_PACKAGES`, `GUI_APPS`, `UBUNTU_MISE_PACKAGES` in install.sh | `GUI_APPS` and `UBUNTU_MISE_PACKAGES` comment their row format; `COMMON_PACKAGES` is a flat list |
| Git identity, macOS defaults | `setup_git_config`, `setup_macos_defaults` | the functions are the documentation |

Where the tool has a repo-level twin (a repo's own `.claude/` or `AGENTS.md`), that is not this skill's territory: this skill covers the global layer that reaches every session.
