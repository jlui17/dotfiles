## Scope locks before work, then stays locked

Open scope decisions (in vs. out, what a component owns, where code lands) are the user's: grill them out before implementing, and never fill a gap with the nearest existing pattern — a "settled" design settles only what it actually states. Once locked, scope is a standing invariant: a cut stays cut, and anything later work surfaces (a review finding, a hardening idea, an implied convention) gets triaged into this-round vs. follow-up and put to the user, never silently built. Ship the smallest independently-testable slice first; harden after it's alive.

A plan posted for review ends the turn: no implementation, no external side effects (trackers, Slack, PRs) until it's approved.
