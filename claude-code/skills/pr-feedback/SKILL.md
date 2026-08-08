---
name: pr-feedback
description: Use when responding to review comments on a PR (human or agent reviewer), before pushing fixes or replying to the reviewer.
---

# PR feedback

One commit per feedback item (always-on rule in `~/CLAUDE.md`); the response format and PR-body upkeep live in the style skill's `resources/pr-descriptions.md`.

## Review feedback is a documentation signal

When a review objects to a decision or assumption we made, and the objection only holds because the reviewer lacks context we already had, the gap is documentation, not the decision. The reasoning lived in our heads, not where the reader could reach it. Capture the *why* where the reader will hit it, or make the docs that already cover it more discoverable.

"Where the reader will hit it" is ranked, and defers to the code-comments rule: first encode it in code or pin it with a test; then the package's docs (README, design doc) for context that outlives the change; a code comment only if it clears the comment bar. Lifetime picks the venue: **information that persists lives in the package; information true only for the PR's lifetime (deploy status, merge order, what exists yet, review dispositions) lives in the PR, always the PR, never the package.**

## Close the loop in Slack

After pushing fixes, reply in the requester's Slack thread (the original review-request message) with a short note that the comments are addressed. Claude monitors Slack, not the PR: dispositions posted only on the PR won't be seen. Details stay in the PR; the thread reply is the ping (the depth-pairing rule in the style skill's `resources/slack.md`).
