# Slack / peer messages

Casual and conversational — closer to how you'd actually type to a teammate than to a PR description. Same voice (actor-as-subject, behavior-first, append-reason, no hype, no em-dashes), but it *flows*. Don't telegraph.

- **A light greeting is fine.** "Hey," to open is normal chat, not throat-clearing.
- **Full conversational sentences, clauses joined naturally** with `since` / `but` / `as long as` / `then`. The one-idea-per-sentence rule (voice #8) is for dense technical prose; in chat you write the way you'd say it out loud. One-claim-per-line bullets read as a robot.
- **Link the one artifact the reader will open** (the PR URL, inline), and name only the 1-2 identifiers central to your point. Don't enumerate every test file, pass count, or "runs in CI" — that reads as AI over-justification. Trust them to click through.
- **Say how the work was actually done**, plainly. "I got Claude to mock it locally by …" beats "I forced it." No inflation.
- **State your confidence and the assumption it rests on** (voice #13), inviting correction rather than declaring victory.
- **Scope to this reader's decision.** Cut tangents that don't bear on what they need now (leave the infra/CI flakiness on the PR, not in the ping).

## Worked example

Context: telling a teammate why a fix can't be verified in a live rollout, and how it was verified instead.

> Hey, for colony-279 (https://git.colony.camp/colony/colony/pulls/586) we can't deterministically verify in a live rollout since the bug only fires when the reviewer simuser posts on the wrong PR, but the model usually picks right.
>
> I got Claude to mock it locally by having the model pass a wrong PR number and saw that `submit_review` now rejects it and points back to the right PR under review. I think as long as I'm understanding correctly that if `ctx.pr_number` is set the model should use that number, then I'm quite confident this change will fix the issue.

Why it lands:
- one-word greeting, then straight into the point.
- flowing sentences (`since` / `but` / `as long as` / `then`), not fragments.
- links the PR and names only `submit_review` + `ctx.pr_number` — not the test suite, pass counts, or CI status.
- says Claude did the mocking, plainly.
- closes on confidence *conditional on a stated assumption*, which hands the reader the one thing to check.
- says nothing about the deploy/infra side, because it doesn't bear on the point.

The AI-sounding version of the same message telegraphs it into `param, on colony-279:` followed by one-claim-per-line bullets listing both test files, `3/3`, "runs in CI", and a parenthetical on the infra flakiness. Every fact is true; it just reads like a status report, not a person.
