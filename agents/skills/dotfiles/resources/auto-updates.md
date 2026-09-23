# Automatic updates

The `auto-updates` module schedules a small, explicit set of updates that are safe to run unattended. It does not run a package-manager-wide upgrade. Each approved updater is an `ExecStart` entry in `auto-updates/auto-updates.service`; the standalone T3 Code server is the first one.

The timer runs at 6:00 AM Pacific, when the machines are least likely to be in use. It does not catch up after a missed run, so starting a machine later in the day cannot trigger an update during work.

The module runs `update_t3 --server-only` on sfx and srv. The T3 desktop package on sfx stays an on-demand update. `update_mdnote` (`mdnote/update_mdnote`) runs after it; systemd runs the entries in order and stops at the first failure, so a failed T3 update also skips mdnote that day.

```sh
systemctl --user list-timers auto-updates.timer # next scheduled run
journalctl --user -u auto-updates -n 50         # last update output
systemctl --user start auto-updates.service     # run the approved list now
```
