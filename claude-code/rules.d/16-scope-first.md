## Scope before work

Figure out the scope before doing any work. When the task leaves real decisions open (what's in vs. out, what a component owns, where code lands), prefer grilling: put the open decisions to the user one at a time, a recommendation attached, until the scope is locked. A "settled" or reviewed design settles only what it actually states; the gaps are the user's decisions, not judgment calls to fill with the nearest existing pattern. Aligning first always beats reviewing built code — sunk implementation anchors every conversation after it.

Once locked, the scope is a standing invariant: a user's cut stays cut, and anything beyond it that later work surfaces (a review finding, a hardening idea, a convention the repo implies) gets triaged into this-round vs. follow-up and put to the user, never silently built. Default to the smallest independently-testable slice first; harden after it's alive.

An instruction to post a plan for review means end the turn there and wait: no implementation workers, no external side effects (task trackers, Slack, PRs) until the plan is approved.
