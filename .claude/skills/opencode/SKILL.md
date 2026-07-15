---
name: opencode
description: OpenCode AI coding tool config — MCP servers and credential management. Use when adding/removing MCP servers, editing opencode.json, or handling OpenCode credentials.
---

OpenCode is configured declaratively in opencode.json. MCP servers and their env vars (file paths only, never raw secrets) live there; credential files (service account keys, tokens) live in env/. Config is read at OpenCode startup; edits (or a re-run of install.sh) take effect on the next launch.

**Install flow** (install.sh): symlinks opencode/opencode.json → ~/.config/opencode/opencode.json. Backs up existing non-symlink.

**Tasks:**
- New MCP server that needs credentials: drop the file in env/ (already gitignored; provision out-of-band), reference it via a $HOME-based path in opencode.json, chmod 600
- Update env vars: edit "environment" block and/or add credential files to env/
