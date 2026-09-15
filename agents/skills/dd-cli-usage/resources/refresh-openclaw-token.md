# Refresh the OpenClaw DoorDash token

Use this runbook when DoorDash authentication expires on `srv`, or when the
user asks to rotate its credential. The exported token is short-lived and acts
as the user, so run the mutation only with explicit user authorization.

## Rotate the vault item

Run the bundled script on `sfx`, where `dd-cli` can open a browser and the
desktop 1Password session can update the `Openclaw` vault:

```sh
~/.agents/skills/dd-cli-usage/scripts/refresh-openclaw-token
```

The user completes the DoorDash authorization in the opened browser. The
script pipes the exported token directly into 1Password: it does not place the
token in arguments, files, or output.

## Refresh and verify on OpenClaw

From the main OpenClaw agent, add `--refresh-secret` to one read-only,
authenticated command such as `address list`. Supply the command's required
`--intent` from the actual user request, and discard address data when the goal
is only verification.

The VPS wrapper replaces its protected runtime cache before executing that
command exactly once. Do not use an order submission or another mutating
command as the refresh probe. Later calls use `dd-cli` normally.

If the vault update succeeds but the refresh probe fails, keep the new vault
item and diagnose the 1Password service account, wrapper, or cache. Export a
second token only after confirming the first token itself is invalid.
