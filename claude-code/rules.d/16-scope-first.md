## Scope locks before work, then stays locked

A task starts with a grilling session by default: gather context, state your understanding, then grill the gaps, a recommendation attached to each question. Skip it only when you're certain you already hold all the context the task needs (alignment established in the conversation, not assumed), or the user said to just do it.

Open scope decisions (in vs. out, what a component owns, where code lands) are the user's: grill them out before implementing, and never fill a gap with the nearest existing pattern — a "settled" design settles only what it actually states. Once locked, scope is a standing invariant: a cut stays cut, and anything later work surfaces (a review finding, a hardening idea, an implied convention) gets triaged into this-round vs. follow-up and put to the user, never silently built. Ship the smallest independently-testable slice first; harden after it's alive.

A multi-decision design conversation (a scoping grill especially) maintains a decision-record artifact from the start, updated as each decision settles; every recommendation or sign-off request links it. Never ask for sign-off on decisions that exist only in chat dialogs — the user can't review state they can't see.

The artifact's home is the task's worktree, at `.luidocs/<task>-decisions.md`: `.luidocs/` is globally gitignored, so scaffolding can't leak into the task's PR or dirty a checkout, and it dies when the worktree is removed. No worktree yet → keep it in the session scratchpad and move it in once one exists; never write it into a shared/main checkout or a repo's tracked docs. A plan the repo treats as a deliverable (reviewed, committed via PR) is a different artifact and follows the repo's own conventions.

A plan posted for review ends the turn: no implementation, no external side effects (trackers, Slack, PRs) until it's approved.
