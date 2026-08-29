# Omarchy quirks and decisions log

Omarchy is a moving target: it ships opinionated defaults, restructures them between
releases, and expects you to layer on top. This log is the timeline of that layering —
what Omarchy changed under us, what quirk cost us time, and what we decided in response.

Read it when a config change behaves in a way the docs don't explain, or when deciding
whether something is ours to own.

Scope: dated findings and decisions only. Durable "how it works today" belongs in
`SKILL.md`; entries here point at it rather than restating it. Newest first.

## What's ours vs. Omarchy's

Ours (this repo, symlinked into `~/.config/`):

- `omarchy/hypr/{bindings,input,windows}-override.lua` — loaded last, after Omarchy's
  defaults, so they win. Every Hyprland override we make lands in one of these three.
- `omarchy/themes/{fleet,rainynight}/` — fleet is built here; rainynight is vendored
  with local edits.
- `omarchy/bin/quickshell` — a PATH shim at `/usr/local/bin`, the only root-owning
  thing in the repo.

Omarchy's (upgraded out from under us by `omarchy-update`, never edited in place):

- `~/.local/share/omarchy/default/hypr/**` — defaults, including `bindings/*.lua`.
- `~/.config/hypr/{hyprland,bindings,input,looknfeel,autostart,monitors}.lua` — seeded
  by Omarchy, then owned by the machine. We append `require()` lines to `hyprland.lua`;
  we don't otherwise edit these.

Anything else in `~/.config/hypr/` is machine-local, unmanaged, and fair game to be stale.

---

## 2026-08-27 — Third-party installers still write to the dead `.conf` config

**Whose:** interaction between Omarchy's Lua migration and third-party setup scripts.

`hyprwhspr setup` appended its keybinding to `~/.config/hypr/bindings.conf` and reported
success. Hyprland never registered it: since the Lua migration, `hyprland.lua` is the
live config and nothing in the tree reads `hyprland.conf` or the `.conf` files it sources.
No config error, no log line — the bind silently did not exist.

The trap when debugging this: `hyprctl binds` *did* show entries matching lines in
`bindings.conf` (Tmux on SUPER+ALT+RETURN, Docker on SUPER+SHIFT+D), which makes the file
look live. Those come from `default/hypr/bindings/applications.lua` and happen to use the
same keys. **The tell is `dispatcher`: every live bind reads `__lua`.** A bind sourced
from a `.conf` would name a real dispatcher. If nothing in `hyprctl binds` has a
non-`__lua` dispatcher, no `.conf` is being read.

**Decision:** any third-party tool's Hyprland binding gets re-declared in our
`bindings-override.lua` rather than left where its installer put it. That survives the
tool's next `setup` run and reaches the machine through `install.sh`. First case:
`SUPER+CTRL+SPACE` for hyprwhspr speech-to-text.

**Follow-on, same day:** the legacy `.conf` chain was deleted rather than left in place —
see the entry below.

## 2026-08-27 — Deleted the dead `.conf` chain, and found what it had been hiding

**Whose:** ours, cleaning up after Omarchy's Lua migration.

Removed `hyprland.conf`, `bindings.conf`, `input.conf`, `looknfeel.conf`, `monitors.conf`,
`autostart.conf`, `envs.conf` from `~/.config/hypr/`. `hyprctl systeminfo` reports
`configProvider: lua`, which is the definitive check that none of them were being read.

**Not deleted, and not part of the chain:** `hypridle.conf`, `hyprlock.conf`,
`hyprsunset.conf`, `xdph.conf`. Those configure separate daemons, not Hyprland, and are
live. A `.conf` under `~/.config/hypr/` is not automatically dead — check who reads it.

**The real finding:** the Quattro migration silently dropped settings, and the dead files
were the only record of them. Omarchy's defaults had since claimed the same keys, so
nothing looked broken — the keys just did something else:

| Was (in `.conf`) | Became (Omarchy default) | Disposition |
|---|---|---|
| `SUPER+SHIFT+M` Gmail | Music / Spotify | restored in `bindings-override.lua` |
| `SUPER+SHIFT+N` Notion | Editor | restored in `bindings-override.lua` |
| `SUPER+SHIFT+A` chat.zhao.io | ChatGPT | accepted the default |
| `input.repeat_delay = 600` | `250` | accepted the default |
| `GDK_SCALE = 1` | `2` | accepted the default |

**The lesson:** a config migration that leaves the old files in place converts *lost
settings* into *silent drift*. Nothing errors, and the old file keeps reading as if it
were still in force. Before deleting a superseded config, diff it against live state
(`hyprctl getoption`, `hyprctl binds`) rather than against its successor file — the
successor is mostly commented-out template and will look falsely equivalent.

**Decision:** personalizations that must survive the next migration live in this repo's
`*-override.lua`, never in the Omarchy-seeded `~/.config/hypr/*.lua`, which is machine-local
and gets restructured. Backup files (`*.bak*`) were left in place; they're the next sweep.

## 2026-08-23 → 08-27 — Software-rendering the shell took three tries

**Whose:** an NVIDIA driver bug, worked around here.

A game filling VRAM starves Quickshell of EGL surfaces and the bar stops drawing. The
arc: ship an NVIDIA profile (didn't help) → software-render via an autostart hook →
discover the hook fires too rarely → move to a PATH shim.

**The lesson that generalizes:** Omarchy re-execs its own components on events we don't
control, so anything that must hold for *every* launch belongs at a chokepoint every
launch passes through, not in a startup hook. Assume any Omarchy-managed process can be
restarted behind our back, and check that the hook we're reaching for actually fires then.

Mechanism, why the hook missed, profiling numbers, and the reproduction: `SKILL.md`,
"Software-rendered shell".

## 2026-08-14 — Omarchy Quattro moved Hyprland config to Lua

**Whose:** Omarchy.

Quattro replaced the `.conf` config with Lua: `hyprland.lua` is the entrypoint, overrides
are `require()`d modules, and bindings are declared with `o.bind("SUPER + X", "Label", ...)`
against helpers (`hl.unbind`, `hl.dsp.*`). The old `.conf` files were left in place rather
than removed, so a machine upgraded through Quattro carries both — one live, one inert.

**Decision:** migrate our three override files to `.lua`, and have `install.sh` append
`require("hypr.<override>")` to `hyprland.lua` instead of `source =` to `hyprland.conf`.

**Still-live consequence:** stale `.conf` files are the default state on this machine, not
an anomaly. Anything that reads or writes `~/.config/hypr/*.conf` is working on dead files.
