---
name: pr-review
description: Use when reviewing a PR, branch, or diff: a fresh review, a re-review after fixes, or a "review and summarize" ask. Applies alongside a repo's own review skill (colony's impl-review and colony-pr-review own the methodology there).
---

# PR review

What a good review looks like, distilled from real corrections. The author-side counterpart is the `pr-feedback` skill; the prose voice is the `style` skill.

## Grounded in the repo's own conventions

A good review checks the change against what the repo declares, not just general judgment. Discovery starts from the repo's README.md and CLAUDE.md and follows their pointers to the convention docs they name: reviewer-guidance docs, the docs policy, the README/CLAUDE.md of each module the diff touches (those files exist to be enforced in review). The two root files are only entry points; the docs they link carry the actual conventions, invariants, and gotchas. And the *posted* review body names which convention docs were applied. A recurring failure: the internal draft had that line, the posted body dropped it.

## "Review and summarize" is both halves

Prose anchored on previous behavior (what the system did before and why that is being replaced), plus a per-file signature profile of the code changes (the style skill's `resources/change-walkthroughs.md`), then verdict and findings. Either half alone is half the deliverable.

Write the summary so the reader can judge the findings without opening the PR. They know the codebase's patterns and service architecture, but none of the diff, so the prose explains each piece from zero (what it is, what it does at runtime, why it moved) rather than labeling hunks ("renames X to Y, adds a replace directive") in a recap register that only makes sense with the diff open. The correction that produced this: "imagine I didn't look at the code and you're explaining the whole PR."

## Factual precision is load-bearing

Verification is table stakes: CI state, the head SHA reviewed, file:line on every finding. A wrong claim ("the store has no event ID column" when the table has an `id UUID` PK; an inverted dedup sentence) converts the reader's review of the review into debugging it. Before posting, an independent fact-check pass (a subagent re-verifying every cited file, claim, and quote against the tree) is worth its cost.

## The world moves while the review is written

The style skill's moving-world rule, reviewer side. Right before posting, re-check the head and sibling-PR state, and re-verify findings the moved world invalidated: "this can't go green before #760 merges" reads badly two hours after #760 merged and the author pushed fixes. A posted review later found stale gets amended on the forge, not just walked back in chat.
