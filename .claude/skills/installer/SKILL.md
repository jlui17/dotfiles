---
name: installer
description: Use when editing install.sh — adding or changing a module, a package, or a GUI app; when its terminal output looks wrong (a missing result line, a leaked subprocess line, a prompt that hangs); when debugging a failed install from /tmp/dotfiles-install.log; or when changing what the installer prints, logs, or reports.
---

`install.sh` is the spine every module plugs into: OS detection → packages → symlinks → plugin managers, each phase idempotent. Modules are declared in the `MODULES` registry (`name:function[:os,os]`) and run through `run_module`.

## The terminal is the exception, not the default

`open_log` parks the terminal on **fd 3** and gives stdout and stderr to the log for the whole run. Reaching the screen takes a deliberate call; everything else lands in `/tmp/dotfiles-install.log`.

This is structural on purpose. A convention ("remember to redirect noisy commands") rots one new module at a time, and the failure mode is noise. Here, forgetting the API costs a summary line and nothing else — a bare `echo` in a module is not a bug, it's the log's per-item detail.

**The API — the only routes to the terminal:**

| Call | For |
| --- | --- |
| `result "..."` | Override the module's synthesized result line |
| `changed "..."` | Record one thing that changed; every one is named in the result |
| `warn "..."` | ⚠️ line, run continues (failure bookkeeping stays the caller's) |
| `note "..."` | A follow-up action for the closing Notes block |
| `track "label" cmd...` | Run a fallible command: label into the log, tail to the screen on failure, label into `FAILURES` |
| `ask var "prompt"` | Prompt the user |
| `die "..."` | Fatal, with the log path (the summary that normally prints it is never reached) |

**Two traps this shape creates.** zsh's `read -r "var?prompt"` writes its prompt to stderr, which the log now owns, so a raw prompt looks like a hang — use `ask`. And a fatal path that `echo`s before `exit` says nothing at all — use `die`.

## Result lines are synthesized, not written

`backup_and_link`, `install_generated_file` and `merge_json` record what they did (`changed`, or `MODULE_UNCHANGED++`), so **a module built from symlinks needs no reporting code**. `run_module` joins the recorded changes, or prints `up to date` when there were none. Reporting nothing means nothing changed, which is the honest default for an idempotent phase.

Reach for `result` only when links and counts aren't the story — what runtimes are configured, what the module deliberately skipped. `backup_and_link` returns 0 when it linked and 1 when the link was already correct, which is how a note fires on first-time setup only:

```zsh
backup_and_link "$src" "$dst" && note "Restart X to pick it up."
```

**Notes are registered by the module that did the work**, never re-derived centrally, so a steady-state run prints none of them. A note that would print on every run is a result line wearing the wrong hat.

## Adding a module

1. Add `name:function` to `MODULES` (append an OS list — `name:function:macos,arch` — only if it can't apply everywhere; that's what keeps the `[n/N]` counter honest, and it replaces an early `return` inside the function).
2. Write the function using `backup_and_link` for symlinks and `track` for anything fallible. Don't add reporting unless synthesis gets it wrong.
3. Add the maintenance skill under `.agents/skills/<name>/`.

Nothing needs wiring in `main` — the registry is the single place a module is named, including for the skip-list template appended to `.dotfiles-local`.

## The log

Overwritten each run, so it always describes the run you just did. Structure: a header naming machine, invocation and resolved skip lists; then `════ <module>` banners, `--- <label>: <cmd>` blocks written *before* each tracked command (so a hung or Ctrl-C'd run still shows what it was doing), and `──> <result>` lines.

It's a superset of what the terminal showed. When output "disappears" after an edit, it's in there — check before assuming it was dropped.

## Verifying a change to the output

Capture a run, diff against it, and account for every line that moved. The paths this machine can't reach — fresh-machine first-run, and the Arch and Ubuntu branches — are read, not run; say so rather than implying coverage. A failure path is cheap to exercise deliberately (point a package at a name that doesn't exist) and worth doing whenever `track` or the summary changes.
