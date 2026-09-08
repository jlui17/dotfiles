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

## scorecard-mac — Mac (macOS)

```
ssh scm                      # alias in ~/.ssh/config: justinlui@scorecard-mac with a per-machine key
```

Unlike the Linux boxes, this host uses ordinary public-key auth: each machine that reaches it has its own key in the mini's `authorized_keys` (the laptop's is `~/.ssh/ssh-to-scm`, sfx uses its `id_ed25519`). Two things an SSH shell can't do there. It can't reach a private GitHub repo, because an SSH login is its own macOS security session and the login keychain (where gh keeps its token) is locked in it; public repos fetch fine. The way around is to run the command in a herdr pane: the herdr server is a LaunchAgent in the desktop session, so a pane it spawns has the keychain unlocked (verified: `security find-generic-password` and a private `git ls-remote` both succeed there).

```
herdr --session default tab create --workspace <ws> --cwd <dir> --label <task> --no-focus   # → pane_id, tab_id
herdr --session default pane run <pane_id> "<command> > <outfile> 2>&1"
herdr --session default tab close <tab_id>                                                 # when done
```

Read results from the outfile; `pane read` came back empty for a short-lived command. The herdr-agents skill has the rest of the CLI. A machine-local `~/.zshenv` puts `/opt/homebrew/bin` on PATH for non-interactive shells (ssh commands, `herdr machine add`), which zsh's login files alone don't.

## srv — Hostinger VPS (Ubuntu, production)

```
ssh ubuntu@srv1445290        # general work
ssh root@srv1445290          # only when root is genuinely needed (docker, system services)
```

This box runs production services, so treat restarts, deploys, and config changes as approval-gated; reading state is always fine.

- **openclaw gateway** — runs as its own `openclaw` user (`/home/openclaw`, gateway on port 18789). That user is also the one the dotfiles are installed under on this box (`ssh openclaw@srv1445290`), so its `~/CLAUDE.md` and `~/.codex/AGENTS.md` are the generated global rules, not hand-written notes. The same user runs a t3code server as a systemd user service (`t3code.service`), bound to the Tailscale address, and a herdr server (`herdr.service`).
- **puzzlewithme** — docker compose stack (`puzzlewithme-web`, `puzzlewithme-server`, `puzzlewithme-cloudflared`), exposed via the Cloudflare tunnel, nothing on host ports. Docker is root-owned: `docker ps` needs root.
