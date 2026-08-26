---
name: dev-machines
description: Use when Justin asks to configure, run, deploy, or inspect something on one of his machines over the tailnet — "on sfx", "on srv", "on my server", "on the VPS" — when checking openclaw or puzzlewithme, or when a task needs an always-on Linux box (offloading a long build, hosting something).
---

Justin's machines mesh over Tailscale; the two SSH-reachable dev machines are `sfx` and `srv1445290`. Auth is Tailscale SSH (identity comes from the tailnet — no keys, no passwords): plain `ssh` works from any machine logged into the tailnet, and `-o BatchMode=yes` is fine for scripted use. `tailscale status` lists what's currently online. Each host only permits the SSH users named below; the tailnet ACL rejects everything else.

## sfx — home workhorse (Arch/Omarchy desktop)

```
ssh jlui17@sfx
```

Always on: idle only locks the screen, it never suspends. Games, side projects, and work all happen here, and it runs a t3code server as a systemd user service (`t3code.service`, published at https://sfx.tail71603e.ts.net/).

It is an interactive desktop Justin may be sitting at: fine to build, test, and read anything, but don't restart the display stack or user services, and don't start GPU-heavy work without asking — a game may be running.

## srv — Hostinger VPS (Ubuntu, production)

```
ssh ubuntu@srv1445290        # general work
ssh root@srv1445290          # only when root is genuinely needed (docker, system services)
```

This box runs production services, so treat restarts, deploys, and config changes as approval-gated; reading state is always fine.

- **openclaw gateway** — runs as its own `openclaw` user (`/home/openclaw`, gateway on port 18789). That home carries its own AGENTS.md/CLAUDE.md; read them before working in it.
- **puzzlewithme** — docker compose stack (`puzzlewithme-web`, `puzzlewithme-server`, `puzzlewithme-cloudflared`), exposed via the Cloudflare tunnel, nothing on host ports. Docker is root-owned: `docker ps` needs root.
