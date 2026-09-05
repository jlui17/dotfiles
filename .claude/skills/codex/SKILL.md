---
name: codex
description: Use when changing shared Codex CLI configuration, MCP servers, or the codex module in this dotfiles repo, or when a Codex setting disappears after install.sh.
---

# Codex module

`codex/config.toml` owns the marked dotfiles block inside `~/.codex/config.toml`.
The destination deliberately remains a real file because Codex and the ChatGPT
desktop app write machine-local MCP entries and settings there.

Codex shares the Claude Code skills: every `claude-code/skills/` directory not
in `SKIP_SKILLS` is linked into `~/.codex/skills/`, so a skill has one home and
both agents read it. The installer prunes only repo-pointing links, so bundled,
plugin-provided, copied, and hand-made skills survive.

Put only portable, non-secret configuration in the tracked fragment. The
installer replaces tables named by the fragment before appending the generated
block, so a pre-module hand-created version of a now-managed table is migrated
without creating duplicate TOML tables. Unmanaged tables and settings survive.
OAuth credentials are stored by Codex outside this fragment and authentication
still happens per machine with `codex mcp login <name>`.

After an edit, run `./install.sh`, validate any changed skill with the system
skill validator, then use `codex mcp list` and `codex mcp get <name>` to verify
the realized configuration. Do not make an MCP server required unless every
target machine can initialize it unattended; optional integrations must not
prevent Codex from starting.
