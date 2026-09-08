# dev-machines

Owns `dev-machines/dev-machines`, the registry of Justin's dev machines and the fleet commands that run against it: `whoami` (which registered machine a session is on, and its herdr server state), `list`, `sync` (pull and `./install.sh` on every other machine), and `herdr-add` (save every other machine in this machine's herdr). `setup_dev_machines` links it to `~/.local/bin/dev-machines`. Verify with `dev-machines list` (three rows, online state from tailscale) and `dev-machines whoami`. How to work on those machines once you know which one you are on is the `dev-machines` skill, not this file.

## The registry is the script

The machines are a zsh array at the top of the script, one pipe-delimited row each. One file, no parser, and `list` is the readable view, so a machine is added or retired by editing that array; the `sync` and `herdr-add` defaults follow from it. Identity comes from the tailnet host column, matched against `tailscale status --self`, because hostnames are unreliable (scorecard-mac's `hostname -s` is `mac`).

## What is deliberately not there

The laptop is absent on purpose: the registry is what every machine may reach, and nothing should reach the laptop. `whoami` on it reports "not a dev machine", and `sync` from it targets all three.

scorecard-mac's ssh target is the alias `scm` rather than `user@host` because that Mac uses per-machine SSH keys, and each machine that reaches it carries its own `Host scm` entry in `~/.ssh/config`. The other two use Tailscale SSH, where `user@host` is enough. The comment on the registry says the same, so the two stay in step.
