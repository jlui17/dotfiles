---
name: dev-machines
description: Use when Justin asks to configure, run, deploy, or inspect something on one of his machines over the tailnet — "on sfx", "on srv", "on my server", "on the VPS", "on the scorecard mac" — when checking openclaw or puzzlewithme, or when a task needs an always-on Linux box (offloading a long build, hosting something).
---

Justin's machines mesh over Tailscale; the SSH-reachable dev machines are `sfx`, `srv1445290`, and `scorecard-mac`. On the two Linux boxes auth is Tailscale SSH (identity comes from the tailnet — no keys, no passwords): plain `ssh` works from any machine logged into the tailnet, and `-o BatchMode=yes` is fine for scripted use. `tailscale status` lists what's currently online. Each host only permits the SSH users named below; the tailnet ACL rejects everything else.

## sfx — home workhorse (Arch/Omarchy desktop)

```
ssh jlui17@sfx
```

Always on: idle only locks the screen, it never suspends. Games, side projects, and work all happen here, and it runs a t3code server as a systemd user service (`t3code.service`, published at https://sfx.tail71603e.ts.net/).

It is an interactive desktop Justin may be sitting at: fine to build, test, and read anything, but don't restart the display stack or user services, and don't start GPU-heavy work without asking — a game may be running.

## scorecard-mac — Mac mini (macOS)

```
ssh scm                      # alias in ~/.ssh/config: justinlui@scorecard-mac with a per-machine key
```

Unlike the Linux boxes, this host uses ordinary public-key auth: each machine that reaches it has its own key in the mini's `authorized_keys` (the laptop's is `~/.ssh/ssh-to-scm`, sfx uses its `id_ed25519`). Two things a headless session can't do there: reach GitHub, because git signs with the 1Password agent and that agent only answers an unlocked desktop session (fast-forward from sfx instead: `git pull --ff-only jlui17@sfx:src/personal/dotfiles main`), and find Homebrew, because a non-login shell lacks `/opt/homebrew/bin` (run install.sh under `zsh -lc`).

## srv — Hostinger VPS (Ubuntu, production)

```
ssh ubuntu@srv1445290        # general work
ssh root@srv1445290          # only when root is genuinely needed (docker, system services)
```

This box runs production services, so treat restarts, deploys, and config changes as approval-gated; reading state is always fine.

- **openclaw gateway** — runs as its own `openclaw` user (`/home/openclaw`, gateway on port 18789). That user is also the one the dotfiles are installed under on this box (`ssh openclaw@srv1445290`), so its `~/CLAUDE.md` and `~/.codex/AGENTS.md` are the generated global rules, not hand-written notes. The same user runs a t3code server as a systemd user service (`t3code.service`), bound to the Tailscale address.
- **puzzlewithme** — docker compose stack (`puzzlewithme-web`, `puzzlewithme-server`, `puzzlewithme-cloudflared`), exposed via the Cloudflare tunnel, nothing on host ports. Docker is root-owned: `docker ps` needs root.
