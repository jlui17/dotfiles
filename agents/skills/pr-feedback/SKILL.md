---
name: pr-feedback
description: Use when addressing review comments on a PR, before pushing the fixes or replying to the reviewer.
---

# PR feedback

One commit per feedback item; the response format and PR-body upkeep live in the style skill's `resources/pr-descriptions.md`.

## Review feedback is a documentation signal

When a review objects to a decision or assumption we made, and the objection only holds because the reviewer lacks context we already had, the gap is documentation, not the decision. The reasoning lived in our heads, not where the reader could reach it. Capture the *why* where the reader will hit it, or make the docs that already cover it more discoverable.

"Where the reader will hit it" is ranked, and defers to `~/CLAUDE.md` (express it in code where you can; comments and docs carry what code can't): first encode it in code or pin it with a test; then the package's docs (README, design doc) for context that outlives the change; a code comment only if it clears the comment bar. Lifetime picks the venue: **information that persists lives in the package; information true only for the PR's lifetime (deploy status, merge order, what exists yet, review dispositions) lives in the PR, always the PR, never the package.**

Watching for the next feedback round (both the PR and the Slack thread, never just one) is the `babysit` skill's domain (lives in the colony plugin as `colony:babysit`).

## Resolve the thread once the comment is addressed

A reply alone leaves the thread open, and open threads block the merge. Once a comment is fixed and pushed, or answered with evidence that no change is needed, reply and then resolve the thread. Leave it open only when the disposition needs the reviewer's judgment (a pushback they have not accepted, a scope call). On GitHub, `scripts/gh-resolve-review-thread.sh` lists a PR's unresolved threads and resolves one by ID; `gh` has no subcommand for it.
