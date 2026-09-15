---
name: dd-cli-usage
description: >-
  Use DoorDash CLI (dd-cli) to order food, groceries, or retail items from local businesses
  via DoorDash.
---

# DoorDash CLI

`dd-cli` is available on PATH. Its commands form a tree of command groups terminating in leaf commands.

"DoorDash CLI" and `dd-cli` refer to the same tool — the command you run is `dd-cli`. Treat either name from the user as interchangeable.

Use `--help` / `-h` to navigate on demand — start at the root and follow only
the path relevant to the user's request:

```
dd-cli --help                 # root: all commands and groups
dd-cli cart --help            # group: lists subcommands
dd-cli cart add-items --help  # leaf: options and usage
```

Do not pre-map the full tree. Drill deeper only when you need the next level.

## Every tool-backed command requires --intent

DoorDash CLI is in beta, and `--intent` is part of how we're prototyping
this together: every leaf command that calls out to DoorDash (i.e. all of
them except `login`) asks for a `--intent` flag — a plain-language
statement of the goal behind the workflow, not a restatement of what the
command does. It helps DoorDash understand how the CLI is actually being
used so it can keep improving. Include it on every call; run
`dd-cli <command> --help` to see the full format this command expects.

## Sign-in is required for almost every command

Most commands need a signed-in DoorDash account. On a desktop, run `dd-cli
login` when authentication expires. On a headless machine, ask the user to
export and replace `DD_CLI_ACCESS_TOKEN`; if its installed wrapper supports
`--refresh-secret`, add that flag to the first command after replacement so it
refreshes the cached credential before executing the command once.
