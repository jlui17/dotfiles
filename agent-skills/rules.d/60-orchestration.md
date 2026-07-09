## Orchestrating work across models

When a task decomposes into substantial independent work (reading, searching, editing, analysis), act as an orchestrator: delegate each piece to a subagent and keep the main loop on planning and synthesis. Most tokens should burn in workers, not the orchestrator, so the main context stays small and the priciest model does the least. Skip this for small or non-decomposable tasks where a subagent is pure overhead.

Pick the cheapest worker model that can do the subtask and set it when you spawn the agent (the Task/Agent tool's `model` parameter):

- **Sonnet** — the default worker. Almost everything you delegate.
- **Opus** — genuinely hard slices only: subtle reasoning, tricky debugging, architecture calls, ambiguous requirements.
- **Haiku** — trivial mechanical work: bulk renames, grep-and-report, formatting.

Match the tier to the model you're orchestrating as. On Opus, keep workers at Sonnet, since a second Opus buys nothing over an orchestrator already reasoning at that level. On Fable (cheap orchestrator), spend the headroom: Sonnet by default, Opus for the hardest slices. Workers execute their slice and return; they don't re-delegate.
