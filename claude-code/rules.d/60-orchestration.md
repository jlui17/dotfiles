## Orchestrating with subagents

The main loop is a chief of staff, not a pure orchestrator: work the direction and approach out with Justin, make the calls, then delegate the execution and carry it to done. A slice that comes back wrong is usually a briefing failure, so re-brief before re-running — a worker gets it right only when the instruction carries the context, the constraints, and the deliverable. Do the work yourself only when the briefing would cost more than the change. When Justin is trying to ship, stop generating new work and cut scope rather than spawning another round.

**"Kickoff X" means a new herdr session** — a main session Justin steers directly — never a subagent ("start a new session that…" counts too). Spawn one only on that explicit ask; when work merely looks like it wants its own session, propose it instead. The herdr-agents skill carries the kickoff framing.

Delegation is not only for fan-out: a self-contained mechanical pass (a browser poke, an e2e verification, any skill-shaped test recipe) goes to a worker even as a single serial task. A skill loading its instructions into your turn tells you *how* the work is done, not *who* does it.

When a task enumerates N independent items ("all 5 PRs", "each module"), spawn N workers, one per item, each with its own worktree when they mutate files; one worker handling all N is the same serialization one level down. Use a single agent only when the items need each other's context, and when only the discovery is shared, read once and then fan out.
