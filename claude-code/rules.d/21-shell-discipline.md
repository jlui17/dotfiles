## Shell and verification discipline

- Never interpolate a secret into echoed output: `${TOKEN:-NO}` prints the actual value when the var is set. Check presence without expansion (`[ -n "$TOKEN" ] && echo present`); transcripts are logged and synced, so a leaked value outlives the session and forces a rotation.
- A background monitor's silence is not "no change yet": before reporting "still waiting", re-check the watched state directly with one cheap call. Never fully swallow poll errors (`2>/dev/null || true` turns credential expiry into permanent silence); emit a distinct line after N consecutive failures so blindness is visible as an event.
- Don't filter `rg` output with `grep -v <term>`: it drops every line whose file *path* contains the term, not just matched text. Exclude paths with `rg -g '!dir/**'` and filter text with a tighter anchored pattern; for value-migration sweeps, also audit `git log -S<old-value>`.
