---
name: pr-review
description: Use when producing or posting a review deliverable for a PR, branch, or diff (a fresh review, a re-review after fixes, or a "review and summarize" ask). Read before drafting or posting the review. Where the repo carries its own review skill (colony's impl-review and colony-pr-review), that skill owns the methodology and this one still applies.
---

# PR review

What a good review looks like: guidance, not a procedure, distilled from real corrections. The author-side counterpart is the `pr-feedback` skill.

## Grounded in the repo's own conventions

A good review checks the change against what the repo declares, not just general judgment. Discovery starts from the repo's README.md and CLAUDE.md and follows their pointers to the convention docs they name: reviewer-guidance docs, the docs policy, the README/CLAUDE.md of each module the diff touches (those files exist to be enforced in review). The two root files are only entry points; the docs they link carry the actual conventions, invariants, and gotchas. And the *posted* review body names which convention docs were applied. A recurring failure: the internal draft had that line, the posted body dropped it.

## The "review and summarize" deliverable is both halves

"Review and summarize" means the what/why/how prose anchored on previous behavior ("Today X → we'll do Y": what the system did before and why that's being replaced), plus a per-file signature profile of the code changes (the `+`/`~`/`-` shape in `~/CLAUDE.md`), then verdict and findings. Verdict and findings alone is half the deliverable; the profile alone is the other half.

Write the summary for a reader who has not opened the PR: they know the codebase's patterns and service architecture, but none of the diff. So the prose explains each piece from zero — what it is, what it does at runtime, why it moved — rather than labeling hunks ("renames X to Y, adds a replace directive") in a recap register that only makes sense with the diff open. The test: the reader can judge the findings without ever loading the PR. A summary that failed it drew the correction "imagine I didn't look at the code and you're explaining the whole PR."

## Factual precision is load-bearing

Verification is table stakes: CI state, the head SHA reviewed, file:line on every finding. A wrong claim ("the store has no event ID column" when the table has an `id UUID` PK; an inverted dedup sentence) converts the reader's review of the review into debugging it. Before posting, an independent fact-check pass (a subagent re-verifying every cited file, claim, and quote against the tree) is worth its cost.

## The world moves while the review is written

This is the reviewer side of the always-on artifact-sync rule in `~/CLAUDE.md`. Right before posting, the head and sibling-PR state get re-checked, and findings the moved world invalidated get re-verified; "this can't go green before #760 merges" reads badly two hours after #760 merged and the author pushed fixes. A posted review later found stale gets amended on the forge, not just walked back in chat.

## The loop closes with the requester

Whoever asked for the review hears it landed, usually in the Slack thread, with the link. A re-review that ends at the forge approval leaves the author polling.
