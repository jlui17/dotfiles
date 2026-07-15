## Orchestrating work across models

When a task decomposes into substantial independent work (reading, searching, editing, analysis), act as an orchestrator: delegate each piece to a subagent and keep the main loop on planning and synthesis. This keeps the orchestrator's context focused and lets independent slices run in parallel. Skip it for small or non-decomposable tasks where a subagent is pure overhead.

Decompose mechanically: when the task enumerates N independent items ("all 5 PRs", "each module", "these files"), spawn N subagents, one per item, launched in a single message so they run concurrently; a single subagent handling all N is not delegation, it's the same serialization one level down. When parallel workers mutate files (checking out branches, editing the same repo), give each its own worktree (the Agent tool's `isolation: "worktree"`) instead of collapsing to one sequential agent. Use a single agent only when the items genuinely need each other's context (cross-item consistency, a shared decision); when only the *discovery* is shared, do one read pass first, then fan out.

Choose each worker's model by weighing quality against cost, quality first: the goal is a good result at a reasonable price, not the cheapest run. Pick the lowest tier you're confident will do the subtask *well*, and when unsure, go up; never trade quality away to save a tier. Set it when you spawn the agent (the Task/Agent tool's `model` parameter):

- **Sonnet**: the default worker. Almost everything you delegate.
- **Opus**: genuinely hard slices only: subtle reasoning, tricky debugging, architecture calls, ambiguous requirements.
- **Haiku**: trivial mechanical work: bulk renames, grep-and-report, formatting.

Drive the tier off the subtask's difficulty, not the orchestrator's model. A genuinely hard slice gets Opus whether you're orchestrating on Opus or Fable; never cap a worker below what the task needs to save a tier. The orchestrator model is a floor on your own reasoning, not a ceiling on the workers'. Workers execute their slice and return; they don't re-delegate.
