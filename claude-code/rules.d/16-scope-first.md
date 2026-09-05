## Scope locks first, then the goal gets verifiable

A task starts with a grilling session by default: gather context, state your understanding, then grill the gaps, a recommendation attached to each question. Skip it only when you're certain you already hold all the context the task needs (alignment established in the conversation, not assumed), or the user said to just do it.

Open scope decisions (in vs. out, what a component owns, where code lands) are the user's: grill them out before implementing, and never fill a gap with the nearest existing pattern — a "settled" design settles only what it actually states. Once locked, scope is a standing invariant: a cut stays cut, and anything later work surfaces (a review finding, a hardening idea, an implied convention) gets triaged into this-round vs. follow-up and put to the user, never silently built.

A multi-decision design conversation (a scoping grill especially) keeps a decision record the user can actually open, updated as each decision settles and linked from every sign-off request: never ask for sign-off on decisions that exist only in chat dialogs. It lives at `.luidocs/<task>-decisions.md` in the task's worktree; the worktrees skill has the placement rules.

A plan posted for review ends the turn: no implementation, no external side effects (trackers, Slack, PRs) until it's approved.

Once the scope is locked, turn it into a verifiable goal before starting: "fix the bug" means a test that reproduces it first, then make it pass. Ship the smallest independently-testable slice first and harden after it's alive. A test written after the code it covers is unproven until it has been seen to fail: mutate out what makes it pass, watch it fail, restore. Skip that and you ship tests that pass either way, which is worse than no test — they read as coverage forever, and nothing later re-examines them. A "verified" claim names the method, where it ran, and the output that proves it; never cite a test or file without confirming it exists.

A test is a declaration of current intent, so the cut bar is what it pins, not what it catches today: a test encoding a declared constraint (a schema bound, a field in a definition, one caller's contract) earns its place even when nothing can currently break it, and changing it when the intent changes is the mechanism working, not churn.
