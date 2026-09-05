## Picking the right models for workflows and subagents

Rankings, higher = better. Cost is what Justin actually pays, not list price. Intelligence is how hard a problem the model can be handed unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| model        | cost | intelligence | taste |
|--------------|------|--------------|-------|
| gpt-5.6-sol  | 7    | 9            | 8     |
| gpt-5.6-luna | 9    | 6            | 5     |

Codex does the execution. `gpt-5.6-sol` is the default worker; `gpt-5.6-luna` takes bulk mechanical passes (step-by-step implementation, migrations, bulk renames, grep-and-report). Never Sonnet, Opus, or Haiku for a worker: the Agent/Workflow `model` parameter takes only Claude models, so a Claude agent spawned to reach Codex is plumbing and its model is not a tier decision.

These are defaults, not limits, and overriding them needs no permission: when output doesn't meet the bar, rerun or redo it with more reasoning without asking. Escalating costs less than shipping mediocre work. Reach for `--effort` (up to `xhigh`) before reaching for another model. Cost is a tie-breaker only; when the axes conflict for anything that ships, intelligence > taste > cost. Cheap runs earn their keep as reconnaissance: use luna to gather information and try things, then move the real work up.

Anything user-facing (UI, copy, API design) needs taste ≥ 7, so it goes to sol. Reviews of plans and implementations go to sol; the adversarial review is the second, challenging pass, not a second model. When computer use would help do or verify the work, hand it to Codex — the browser plugin is wired up there.

Mechanics: delegation goes through the codex-plugin-cc plugin, not hand-rolled `codex` CLI strings. Agent-initiated work spawns the `codex:codex-rescue` subagent (via the Agent tool) — it forwards one request and returns Codex's output verbatim. The plugin's other commands (`/codex:review`, `/codex:status`, `/codex:result`, `/codex:cancel`, `/codex:transfer`) are Justin's to type; they are not model-invocable. Three flags ride in the rescue request text: `--model gpt-5.6-sol` or `--model gpt-5.6-luna` (always pass it, since an unset model is a silent tier change), `--effort`, and `--background` for anything long-running (the result arrives as a task notification). Rescue is **write-capable by default**, so a request that should only look must say read-only.

Two limits to plan around. Codex can't reach this session's own tooling (MCP servers, Hunk, herdr), so work that needs it stays Claude-side. And Workflow token budgets count Claude tokens only, so Codex work is invisible to `budget.spent()`. Label every delegating agent with the real worker's prefix, e.g. `{label: 'gpt-5.6-sol:review-auth'}`, since the UI shows only the wrapper's Claude model.
