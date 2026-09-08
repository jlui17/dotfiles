---
name: dev-machines
description: Use when Justin asks to configure, run, deploy, or inspect something on one of his machines over the tailnet — "on sfx", "on srv", "on my server", "on the VPS", "on the scorecard mac" — when checking openclaw or puzzlewithme, when a task needs an always-on Linux box (offloading a long build, hosting something), or when dotfiles changes need rolling out to the fleet or a session needs to know which of his machines it is running on.
---

# Dev machines

Run `dev-machines whoami` before anything else and read the answer: an agent may be on any registered machine or on the laptop, and the ssh targets and cautions that apply depend on which. `dev-machines list` is the registry (name, tailnet host, ssh target, os, role, online or offline); this skill does not restate hosts, users, or ssh targets. `dev-machines sync` rolls dotfiles changes out to the other machines, and `dev-machines herdr-add` saves them in this machine's herdr client for a fleet view. The laptop is deliberately unregistered and stays unreachable from the others.

What follows is only what the registry cannot say: why each machine is treated the way it is, and its gotchas.

## Auth

The Linux boxes use Tailscale SSH: identity comes from the tailnet, no keys or passwords, and `-o BatchMode=yes` works for scripted use. Each host permits only the ssh user in the registry; the tailnet ACL rejects the rest. scorecard-mac uses ordinary public-key auth: each machine that reaches it has its own key in its `authorized_keys` and a `Host scm` alias in `~/.ssh/config` (the laptop's key is `~/.ssh/ssh-to-scm`).

## sfx

An interactive desktop Justin may be sitting at, possibly with a game running. Always on (idle locks the screen, never suspends). Build, test, and read freely; leave the display stack and user services running, and ask before starting GPU-heavy work. Runs t3code (`t3code.service`) and herdr (`herdr.service`) as systemd user services.

## srv

Production. Reading state is always fine; restarts, deploys, and config changes wait for Justin's approval. The dotfiles are installed under the `openclaw` user, so its `~/CLAUDE.md` and `~/.codex/AGENTS.md` are generated rules, not hand-written notes. What runs there:

- openclaw gateway, as the `openclaw` user (`/home/openclaw`), port 18789.
- t3code (`t3code.service`, bound to the Tailscale address) and herdr (`herdr.service`), systemd user services of the same user.
- puzzlewithme, a docker compose stack (`puzzlewithme-web`, `puzzlewithme-server`, `puzzlewithme-cloudflared`) behind a Cloudflare tunnel, nothing on host ports. Docker is root-owned, so `docker ps` needs root.

Root is not in the registry: `ssh root@<host>` (host from `dev-machines list`) only when root is genuinely needed, such as docker or system services.

## scorecard-mac

The one thing an ssh shell cannot do there is reach a private GitHub repo: an ssh login is its own macOS security session, and the login keychain (where gh keeps its token) is locked in it; public repos fetch fine. Run such a command in a herdr pane instead: the herdr server is a LaunchAgent in the desktop session, so a pane it spawns has the keychain unlocked.

```
herdr --session default tab create --workspace <ws> --cwd <dir> --label <task> --no-focus   # → pane_id, tab_id
herdr --session default pane run <pane_id> "<command> > <outfile> 2>&1"
herdr --session default tab close <tab_id>                                                 # when done
```

Read results from the outfile; `pane read` comes back empty for a short-lived command. The herdr-agents skill has the rest of the CLI. A machine-local `~/.zshenv` puts `/opt/homebrew/bin` on PATH for non-interactive shells (ssh commands, `herdr machine add`), which zsh's login files alone don't.
