---
name: opencode
description: OpenCode AI coding tool config — MCP servers and credential management.
---

OpenCode is configured declaratively in opencode.json. MCP servers and their env vars (file paths only, never raw secrets) live there; credential files (service account keys, tokens) live in env/. Config is read at OpenCode startup — no restart needed after install.sh re-symlinks.

**Install flow** (install.sh): symlinks opencode/opencode.json → ~/.config/opencode/opencode.json. Backs up existing non-symlink.

**Tasks:**
- Add MCP server: add entry under "mcp" in opencode.json; if it needs credentials, drop file in env/ and reference via $HOME-based path
- Update env vars: edit "environment" block and/or add credential files to env/
- Remove MCP server: delete entry from "mcp" in opencode.json
- Credential hygiene: chmod 600 on sensitive files; gitignore or provision out-of-band if they shouldn't be versioned
