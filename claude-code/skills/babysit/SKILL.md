---
name: babysit
description: Use when asked to babysit a PR or a Slack review thread to merge, in any phrasing ("/babysit", "babysit this till merge", "babysit with @Claude", "review and babysit"). Covers both roles and how to pick one — a PR we authored (shepherd it through review, applying feedback) versus someone else's PR (act as the reviewer; the author implements). Read before starting the loop: the two roles are opposites, and picking the wrong one benches the PR's author.
---

# Babysit a PR to merge

Pick the role by who authored the PR. The two are opposites, and drifting between them is the failure mode.

## Author mode: we wrote the PR

If no review thread exists yet, request review (the ask may name the reviewer) per the repo's contributing conventions. Then monitor the review thread and the PR, applying feedback as it lands, nits included — one commit per item and the rest of the author-side flow per the `pr-feedback` skill.

While waiting, watch both surfaces: the PR (reviews, inline comments) *and* the review-request Slack thread. Reviewers split their output across the two — an agent reviewer posts the verdict on the PR with only a summary in the thread, humans sometimes answer only in Slack — so a watcher pointed at one surface reports "no feedback yet" while the other already has it.

## Reviewer mode: someone else wrote it (an agent like @Claude in Slack, or a teammate)

Reviewer, never implementer. Review per the repo's own review conventions and skills (the `pr-review` skill carries the deliverable), then post the findings where the author actually reads: on the PR and in the Slack thread, addressed to the author. Feedback the author never sees doesn't count as given. Loop — they fix, we re-review — until nothing is left.

Touch their branch only for what the author genuinely can't do (credentials, assignees, infra only this session can reach), saying in the thread what was done and why. If a live author agent stands down because the babysitter took over the driving, the roles have drifted: hand the work back.

## End state, both modes

Babysitting ends in a merge by default: once every feedback item is addressed (and the PR approved, where the reviewer grants approvals), merge it — unless Justin said not to merge this one. If feedback items contradict each other, or confidence that a piece of feedback is right (to apply as author, to insist on as reviewer) isn't high, stop and raise the concern to Justin instead.
