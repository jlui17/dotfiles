---
name: t3
description: Use when changing how the T3 Code server is updated or supervised on sfx or the VPS — the nightly channel, the daily update timer, the update_t3 script, or the systemd units behind t3code.service. Also for debugging a t3 server that won't start or is stuck on an old version.
---

The T3 Code server runs as a systemd **user** service (`t3code.service`) on sfx and on the VPS under the `openclaw` user. Both track the npm `nightly` dist-tag and update daily at 8am Pacific.

## How updating works

`t3 service update` npm-installs the version of the CLI running the command into `~/.t3/runtime/versions/<version>/`, writes a `.install-complete` sentinel, and repoints `t3code.service` at the launcher. It is a no-op when the installed runtime already matches, which is what makes it safe on a timer: an unchanged day never restarts the server.

`update_t3` (this module's script, on PATH via `~/.local/bin`) resolves `nightly` to an exact version first, because npx can serve a dist-tag from its cache but never an exact version. The timer and a manual run execute the same script, so the two paths can't drift.

```
update_t3                                    # update now
systemctl --user list-timers t3code-update   # when it next fires
journalctl --user -u t3code-update -n 50     # what the last run did
```

Bad nightlies are handled by the launcher, not by us: it trial-boots the new version against a database snapshot and rolls back to the previous one if the boot fails.

## The unit is regenerated, so config goes in a drop-in

`renderBootServiceUnit` in the CLI is a pure renderer over a fixed template — it emits `T3CODE_HOME` and the launcher's own env var and nothing else, and every `service update` rewrites the whole file. **Anything you add to `t3code.service` is erased by the next update.** Put it in `~/.config/systemd/user/t3code.service.d/override.conf` instead.

That is why the VPS gets a drop-in: it binds the server to its Tailscale address rather than the loopback default. `T3CODE_HOST` and `T3CODE_PORT` are the env equivalents of the `--host`/`--port` flags, and the launcher passes its whole environment to the server child, so they reach it. `install.sh` writes that file on Ubuntu with the address from `tailscale ip -4`; it also restores the `tailscaled.service` ordering the template drops, since binding a Tailscale address before tailscaled is up fails.

The full env vocabulary (`T3CODE_MODE`, `T3CODE_PORT`, and the rest) is the config schema in the CLI bundle — grep `dist/bin.mjs` for `T3CODE_` under the installed version dir.

## Where things live

`~/.t3` is `T3CODE_HOME`: `runtime/` holds the launcher, the pinned version dirs and `service-state.json` (which names `activeVersion`); `userdata/` holds `state.sqlite`, settings, secrets and `logs/boot-service.log`.

State lives in `userdata/`, so re-running `t3 service install` against the same `T3CODE_HOME` keeps every project and session.
