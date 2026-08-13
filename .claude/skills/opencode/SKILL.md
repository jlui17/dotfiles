---
name: opencode
description: Use when adding or removing an OpenCode MCP server, editing opencode.json, or handling OpenCode credential files.
---

OpenCode is configured declaratively in opencode.json. MCP servers and their env vars (file paths only, never raw secrets) live there; credential files (service account keys, tokens) live in env/. Config is read at OpenCode startup; edits (or a re-run of install.sh) take effect on the next launch.

**Install flow** (install.sh): symlinks opencode/opencode.json → ~/.config/opencode/opencode.json and opencode/env/ → ~/.config/opencode/env/ (created if missing). Backs up existing non-symlinks.

**Tasks:**
- New MCP server that needs credentials: drop the file in env/ (already gitignored; provision out-of-band), reference it via a $HOME-based path in opencode.json, chmod 600
- Update env vars: edit "environment" block and/or add credential files to env/
