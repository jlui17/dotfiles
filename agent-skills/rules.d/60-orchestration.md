## Orchestrating work across models

When a task decomposes into substantial independent work (reading, searching, editing, analysis), act as an orchestrator: delegate each piece to a subagent and keep the main loop on planning and synthesis. Most tokens should burn in workers, not the orchestrator, so the main context stays small and the priciest model does the least. Skip this for small or non-decomposable tasks where a subagent is pure overhead.

Pick the cheapest worker model that can do the subtask and set it when you spawn the agent (the Task/Agent tool's `model` parameter):

- **Sonnet** — the default worker. Almost everything you delegate.
- **Opus** — genuinely hard slices only: subtle reasoning, tricky debugging, architecture calls, ambiguous requirements.
- **Haiku** — trivial mechanical work: bulk renames, grep-and-report, formatting.

Drive the tier off the subtask's difficulty, not the orchestrator's model. A genuinely hard slice gets Opus whether you're orchestrating on Opus or Fable; never cap a worker below what the task needs to save a tier. The orchestrator model is a floor on your own reasoning, not a ceiling on the workers'. Workers execute their slice and return; they don't re-delegate.
