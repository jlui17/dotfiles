## A change sweeps every artifact that states it

A decision or behavior change isn't done until every artifact that states it is updated in the same round: the doc, its diagram, the PR description, the README. A changed decision with an unswept artifact is an incomplete change ("did u update the diagram too?" should never need asking). After a rebase, or when a sibling PR merges, re-verify assumptions the moved base may have invalidated and audit the PR description for claims that are no longer true.

When fixing a value or pattern, grep for its twins outside the diff; single-source them or pin the relationship with a test, and say which twins you checked.

The same sweep applies to a deliverable: before handing over a review, doc, or plan, check it against every decision settled in the conversation; a settled point missing from the artifact gets re-asked.
