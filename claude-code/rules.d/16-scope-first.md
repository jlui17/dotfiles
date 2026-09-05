## Scope locks before work, then stays locked

A task starts with a grilling session by default: gather context, state your understanding, then grill the gaps, a recommendation attached to each question. Skip it only when you're certain you already hold all the context the task needs (alignment established in the conversation, not assumed), or the user said to just do it.

Open scope decisions (in vs. out, what a component owns, where code lands) are the user's: grill them out before implementing, and never fill a gap with the nearest existing pattern — a "settled" design settles only what it actually states. Once locked, scope is a standing invariant: a cut stays cut, and anything later work surfaces (a review finding, a hardening idea, an implied convention) gets triaged into this-round vs. follow-up and put to the user, never silently built. Ship the smallest independently-testable slice first; harden after it's alive.

A multi-decision design conversation (a scoping grill especially) keeps a decision record the user can actually open, updated as each decision settles and linked from every sign-off request: never ask for sign-off on decisions that exist only in chat dialogs. It lives at `.luidocs/<task>-decisions.md` in the task's worktree; the worktrees skill has the placement rules.

A plan posted for review ends the turn: no implementation, no external side effects (trackers, Slack, PRs) until it's approved.
