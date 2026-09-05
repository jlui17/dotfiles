## Picking the right models for workflows and subagents

Rankings, higher = better. Cost is what Justin actually pays, not list price. Intelligence is how hard a problem the model can be handed unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| model        | cost | intelligence | taste |
|--------------|------|--------------|-------|
| gpt-5.6-sol  | 7    | 9            | 8     |
| gpt-5.6-luna | 9    | 6            | 5     |

Codex does the execution: `gpt-5.6-sol` by default, `gpt-5.6-luna` for bulk mechanical passes (step-by-step implementation, migrations, bulk renames, grep-and-report) and for open-ended exploration and evidence gathering, where it is strong and its cost lets it run long. No Claude model does worker-tier thinking; the Agent/Workflow `model` parameter takes only Claude models, so a delegating agent's own model is not a tier decision.

These are defaults, not limits, and overriding them needs no permission: when output doesn't meet the bar, rerun or redo it with more reasoning without asking. Escalating costs less than shipping mediocre work. Reach for `--effort` (up to `xhigh`) before reaching for another model, and use luna as reconnaissance — gather information and try things cheap, then move the real work up. The adversarial review is the second, challenging pass, not a second model. When computer use would help do or verify the work, hand it to Codex; the browser plugin is wired up there.

Mechanics: delegation goes through the codex-plugin-cc plugin, not hand-rolled `codex` CLI strings — spawn the `codex:codex-rescue` subagent, which forwards one request and returns Codex's output verbatim. Always pass `--model`, since an unset model is a silent tier change; `--effort` and `--background` ride in the same request text. Rescue is **write-capable by default**, so a request that should only look must say read-only.

Codex can't reach this session's own tooling (MCP servers, Hunk, herdr), so work that needs it stays Claude-side. Label every delegating agent with the real worker's prefix, e.g. `{label: 'gpt-5.6-sol:review-auth'}`, since the UI shows only the wrapper's Claude model.
