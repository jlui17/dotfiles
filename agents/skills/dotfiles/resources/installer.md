# Installer

`install.sh` owns the machine bootstrap: OS detection, packages, then every entry in the `MODULES` registry through `run_module`. This file is how to edit it without breaking its output.

## Run it from the main checkout only

`DOTFILES_DIR` is the script's own directory (`${0:A:h}`), and every symlink points into it. Run from a worktree, the machine's live config would point into the worktree. In practice `maybe_relocate_dotfiles` stops the run first: the main checkout already sits at the expected path, so it dies with "already exists. Move or remove it". Do not follow that message. Merge to the main checkout and run there.

## The terminal is the exception, not the default

`open_log` parks the terminal on fd 3 and gives stdout and stderr to the log for the whole run. Reaching the screen takes a deliberate call; everything else lands in `/tmp/dotfiles-install.log`.

This is structural on purpose. A convention ("redirect noisy commands") rots one module at a time, and the failure mode is noise. Here, forgetting the API costs a summary line and nothing else: a bare `echo` in a module is not a bug, it is the log's per-item detail.

The only routes to the terminal:

| Call | For |
| --- | --- |
| `result "..."` | Override the module's synthesized result line |
| `changed "..."` | Record one thing that changed; every one is named in the result |
| `warn "..."` | Warning line, run continues. Failure bookkeeping stays with the caller |
| `note "..."` | A follow-up action for the closing Notes block |
| `track "label" cmd...` | Run a fallible command: label into the log first, 15-line tail to the screen on failure, label into `FAILURES`, command's exit code returned |
| `ask var "prompt"` | Prompt the user |
| `die "..."` | Fatal, with the log path (the summary that normally prints it is never reached) |
| `emit "..."` | A raw line to both terminal and log. Reserved for `main` and the pre-module steps; a module uses the calls above |

Two traps this shape creates. zsh's `read -r "var?prompt"` writes its prompt to stderr, which the log now owns, so a raw prompt looks like a hang: use `ask`. A fatal path that `echo`s before `exit` says nothing at all: use `die`.

`track` runs the command with `&&`, not `if`, so `$?` still carries the real exit code. Keep that when editing it.

## Result lines are synthesized, not written

`backup_and_link`, `prune_stale_links`, `install_generated_file` and `merge_json` record what they did (`changed` for a change, `MODULE_UNCHANGED++` for a no-op; prune is silent on no-ops), so a module built from symlinks needs no reporting code. `run_module` joins the recorded changes, or prints `up to date` when there were none.

Reach for `result` only when links and counts are not the story: what runtimes are configured (`setup_mise`), what the module deliberately skipped (`skipped — work computer` in `setup_zshrc`). `backup_and_link` returns 0 when it linked and 1 when the link was already correct, which is how a note fires on first-time setup only:

```zsh
backup_and_link "$src" "$dst" && note "Restart X to pick it up."
```

Notes are registered by the module that did the work, never re-derived centrally, so a steady-state run prints none. A note that would print on every run belongs in the result line instead.

## Adding a module

1. Give the subsystem a directory at the repo root (a single-file config lives at the root itself), named lowercase with hyphens. Add `name:function` to `MODULES`. Append an OS list (`name:function:macos,arch`) only when the module cannot apply everywhere; the comment above `MODULES` says what that buys.
2. Write the function with `backup_and_link` for symlinks, `prune_stale_links` when it links a directory of files, and `track` for anything fallible. Add reporting only when synthesis gets it wrong.
3. Add the module to the table in `SKILL.md`, and write `resources/<module>.md` when there is something the code cannot say. Modules do not get their own skill.

Nothing needs wiring in `main`. The registry is the single place a module is named, including for the skip-list template appended to `.dotfiles-local` (`append_local_config_knobs`, kept current by `refresh_local_config_knob_lists`).

Order in `MODULES` is load-bearing: packages before mise and nvim, mise before apps. The comment above the registry says why.

A CLI tool is a `COMMON_PACKAGES` entry, with an `UBUNTU_MISE_PACKAGES` row when apt lacks it or ships it too old. A GUI app or non-package tool is a row in `GUI_APPS`. Neither needs a module.

## A moved path carries its migration

install.sh runs on machines that installed every earlier layout. A change that moves a deployed path or retires a deployed file is not done when the new path works on a fresh machine. The module that owns the new path also converges the old one: move the machine-local file, prune the old links, remove the retired generated file. Record each with `changed` so the result line says it happened. The step lives in install.sh, not in a one-off command, because the machine that needs it may run months later; it leaves once every machine has run it. Examples: the retired `codex-playwright-mcp` link removed in `setup_codex`, `retire_pi`, and the `99-local.md` move and retired `~/AGENTS.md` removal in `setup_agents`.

## The log

Overwritten each run, so it always describes the run you just did. Structure: a `════ run` header naming machine, invocation and resolved skip lists (`log_run_header`), then a `════ <module>` banner per module, `--- <label>: <cmd>` blocks written before each tracked command starts (so a hung or interrupted run still shows what it was doing), and `──> <result>` lines.

It is a superset of what the terminal showed. When output "disappears" after an edit, it is in there. Check before assuming it was dropped.

## Verifying a change to the output

Capture a run, diff against it, and account for every line that moved:

```zsh
cp /tmp/dotfiles-install.log /tmp/dotfiles-install.before.log
./install.sh > /tmp/dotfiles-install.tty
diff /tmp/dotfiles-install.before.log /tmp/dotfiles-install.log
```

The paths this machine cannot reach (fresh-machine first run, the Arch and Ubuntu branches) are read, not run. Say so rather than implying coverage. An upgrade path is the exception. Verify it by running install.sh on a machine that still has the old layout and reading its result lines and log, not by reasoning about it. sfx over the tailnet is the usual one; the dev-machines skill has the access rules. A failure path is cheap to exercise deliberately (point a `track` call at a package name that does not exist) and worth doing whenever `track` or the summary changes.
