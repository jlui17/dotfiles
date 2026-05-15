---
name: helium
description: Browser automation using your local Helium browser (Chromium fork). Load this when you need to browse websites, take screenshots, fill forms, or do any browser task — it configures the agent_browser tool to use Helium instead of the default headless Chrome.
---

# Helium Browser Automation

Your default browser is **Helium**, a Chromium fork at `/Applications/Helium.app/Contents/MacOS/Helium`. When using the native `agent_browser` tool, prefer Helium over the default headless Chrome.

## Launch Helium directly

Use `--executable-path` on the first call, with `sessionMode: "fresh"`:

```json
{
  "args": ["--executable-path", "/Applications/Helium.app/Contents/MacOS/Helium", "open", "https://example.com"],
  "sessionMode": "fresh"
}
```

Subsequent calls in the same session don't need the flag — the extension tracks the session:

```json
{ "args": ["snapshot", "-i"] }
{ "args": ["click", "@e2"] }
```

## Connect to a running Helium instance

If Helium is already open with remote debugging (`--remote-debugging-port=9222`):

```json
{ "args": ["connect", "9222"], "sessionMode": "fresh" }
```

## Gotchas

- **Always use `sessionMode: "fresh"`** on the first Helium call to avoid conflicting with the default headless Chrome session.
- **`--auto-connect` won't auto-discover Helium** — `agent-browser` looks for Chrome/Chromium processes. Use explicit `connect <port>` or `--cdp <port>` instead.
- **Sandboxing** — if you hit permission issues, add `--args "--no-sandbox"`:
  ```json
  {
    "args": ["--executable-path", "/Applications/Helium.app/Contents/MacOS/Helium", "--args", "--no-sandbox", "open", "https://example.com"],
    "sessionMode": "fresh"
  }
  ```
- **Binary path** — confirm it exists with `ls /Applications/Helium.app/Contents/MacOS/Helium`.
