# dotfiles

One repo that sets up every machine I use: macOS laptops, an Arch desktop running Omarchy, and a headless Ubuntu VPS. It carries the shell, terminal, editor, and runtime config, plus the global context my coding agents (Claude Code, Codex) read on every machine: skills, rules, plugins, settings.

`install.sh` is the only entry point. Run it on a fresh machine to set everything up, and run it again after pulling to apply changes. It is idempotent: a run that changes nothing on the machine says so.

## How it works

- **The repo is the source of truth.** Every config lives here and is symlinked to its standard path (`~/.config/...`), so editing a file in the repo edits the live config. What cannot be symlinked (the generated `~/CLAUDE.md`, Claude Code's settings and plugins, Codex's config block) is generated, merged, or replayed from manifests in the repo.
- **Machines opt out, never in.** A new module reaches every machine by default. `.dotfiles-local` (gitignored, created on the first run) is where a machine says what it does not want: modules, packages, apps, rules, skills to skip, plugins to keep, whether it is a work computer, which Python provider to use. The template appended to that file lists every knob.
- **Ubuntu means a server.** GUI apps and the terminal emulator are skipped there. Desktop Linux is the Arch machine.
- **Shell startup is fast and stays fast.** Anything slow loads after the first prompt or is cached.
- **Palettes are colorblind-safe.** I am red-green colorblind, so no theme in this repo puts meaning on red versus green.

## Quick start

macOS: install nothing first. The script installs Homebrew if it is missing.

```sh
git clone git@github.com:jlui17/dotfiles.git ~/src/personal/dotfiles
cd ~/src/personal/dotfiles && ./install.sh
```

Arch (Omarchy): same as macOS. Packages come from pacman, AUR apps from yay.

Ubuntu VPS: the script runs under zsh and arrives by git, so install both first. The run switches the login shell to zsh.

```sh
sudo apt-get update && sudo apt-get install -y git zsh
git clone git@github.com:jlui17/dotfiles.git ~/src/personal/dotfiles
cd ~/src/personal/dotfiles && ./install.sh
```

The first run asks whether this is a work computer and writes `.dotfiles-local`. If the repo was cloned somewhere else, the script moves it to `~/src/personal/dotfiles` and continues from there. Each module prints one result line; the full log is at `/tmp/dotfiles-install.log`. Afterwards, open a new shell for zsh, start tmux and press prefix + I (Ctrl+b, then I) to fetch its plugins, and open Neovim once so it fetches its own.

## Layout

Each subsystem owns a directory at the repo root. Single-file configs (`zshrc`, `tmux.conf`) sit at the root.

| Directory | What it holds |
| --- | --- |
| `agents/` | What Claude Code and Codex share: global skills in `skills/`, one directory per skill, the external-skill manifest, and the `rules.d/` fragments that build `~/CLAUDE.md` and Codex's `AGENTS.md`. |
| `claude-code/` | What only Claude Code reads: Claude-only `rules.d/` fragments, output styles, slash commands, settings, the statusline and session-hook scripts, the plugin manifest. |
| `codex/` | The managed block for Codex's config. |
| `zshrc`, `zsh-functions/` | The shell. Functions in `zsh-functions/` are auto-sourced. |
| `tmux.conf`, `ghostty/` | Terminal multiplexer and emulator, with the themes. |
| `nvim/` | Neovim, based on kickstart. |
| `omarchy/` | Hyprland binding overrides, desktop themes, and the software-rendered shell shim for the Arch machine. |
| `herdr/`, `opencode/`, `t3/`, `gitignore/` | One tool each. |
| `install.sh` | The installer: OS detection, packages, then every module in order. |

## Making changes

Edit in the repo, run `./install.sh`, verify, commit. That loop, and the details of each module, are written for agents in `agents/skills/dotfiles/`. It is installed globally by the same run, so on any machine and in any repo an agent asked to change the setup already knows how.
