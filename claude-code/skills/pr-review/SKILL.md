---
name: pr-review
description: Use when reviewing a PR, branch, or diff (a fresh review, a re-review after fixes, or a "review and summarize" ask). Read before drafting or posting the review.
---

# PR review

What a good review looks like: guidance, not a procedure, distilled from real corrections. The author-side counterpart is the `pr-feedback` skill. Voice and register live in the `style` skill; read it before drafting the review body.

## Grounded in the repo's own conventions

A good review checks the change against what the repo declares, not just general judgment. Discovery starts from the repo's README.md and CLAUDE.md and follows their pointers to the convention docs they name: reviewer guidance (e.g. REVIEW.md), the docs policy, the README/CLAUDE.md of each module the diff touches (those files exist to be enforced in review). The two root files are only entry points; the docs they link carry the actual conventions, invariants, and gotchas. And the *posted* review body names which convention docs were applied. A recurring failure: the internal draft had that line, the posted body dropped it.

## The "review and summarize" deliverable is both halves

"Review and summarize" means the what/why/how prose anchored on previous behavior ("Today X → we'll do Y": what the system did before and why that's being replaced), plus a per-file signature profile of the code changes (the `+`/`~`/`-` shape in `~/CLAUDE.md`), then verdict and findings. Verdict and findings alone is half the deliverable; the profile alone is the other half.

## Design, not just mechanics

Verification is table stakes: CI state, the head SHA reviewed, file:line on every finding. A good review also interrogates the design: who owns each datum, what should read config versus a stamped id, what happens on failure. A verdict of "design is solid" that leaves every headline design question for the reader to raise afterward wasn't a design review.

## Factual precision is load-bearing

A wrong claim ("the store has no event ID column" when the table has an `id UUID` PK; an inverted dedup sentence) converts the reader's review of the review into debugging it. Before posting, an independent fact-check pass (a subagent re-verifying every cited file, claim, and quote against the tree) is worth its cost.

## The world moves while the review is written

Right before posting, the head and sibling-PR state get re-checked, and findings the moved world invalidated get re-verified; "this can't go green before #760 merges" reads badly two hours after #760 merged and the author pushed fixes. A posted review later found stale gets amended on the forge, not just walked back in chat.

## The loop closes with the requester

Whoever asked for the review hears it landed, usually in the Slack thread, with the link. A re-review that ends at the forge approval leaves the author polling.
