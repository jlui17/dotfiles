# OpenCode

Owns `opencode/opencode.json` (MCP servers and their env vars) and `opencode/env/` (credential files); linked by `setup_opencode`.

OpenCode reads its config at startup, so an edit or a re-run of install.sh applies on the next launch.

Secrets never go in `opencode.json`. A server that needs a credential file gets it in `opencode/env/`, which is gitignored and provisioned out of band on each machine. Reference it from `opencode.json` by a `${HOME}` path (the linked target is `~/.config/opencode/env/`) and `chmod 600` the file.

OpenCode has no shared rules or default voice; the `rules.d` fragments ship to Claude Code only, and `resources/claude-code.md` says how a harness that needs them gets them.
