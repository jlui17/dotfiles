# Slack / peer messages

Casual and conversational: closer to how you'd actually type to a teammate than to a PR description. The voice holds, but it *flows*: lean, not telegraphic.

- **A light greeting is fine.** "Hey," to open is normal chat, not throat-clearing.
- **Full conversational sentences, clauses joined naturally** with `since` / `but` / `as long as` / `then`. One idea per sentence is for dense technical prose; in chat, write the way you'd say it out loud. One-claim-per-line bullets read as a robot.
- **Link the one artifact the reader will open** (the PR URL, inline) and name only the 1-2 identifiers central to your point. Don't enumerate test files, pass counts, or "runs in CI": that reads as AI over-justification. Trust them to click through.
- **Say how the work was actually done**, plainly. "I got Claude to mock it locally by ..." beats "I forced it." No inflation.
- **State your confidence and the assumption it rests on**, inviting correction rather than declaring victory.
- **Scope to this reader's decision.** Cut tangents that don't bear on what they need now (infra/CI flakiness belongs on the PR, not in the ping).
- **Pair the channel with the depth.** Full reasoning lands on the PR as a comment first; then the Slack ping is the quick version pointing at it.
- **A review request to a teammate (Yash, Reinaldo) is one or two lines.** The shape is fixed: `Hey, <non-urgent|urgent> pr to <what it does, one line>: <link>`. The PR body carries the context, so the ping carries none. A second ask goes on its own line after a blank line, stated as an opinion in plain verbs: "I think we should commit them", not "I'd like to land them so that…".

## Worked example

Telling a teammate why a fix can't be verified in a live rollout, and how it was verified instead:

> Hey, for colony-279 (https://git.colony.camp/colony/colony/pulls/586) we can't deterministically verify in a live rollout since the bug only fires when the reviewer simuser posts on the wrong PR, but the model usually picks right.
>
> I got Claude to mock it locally by having the model pass a wrong PR number and saw that `submit_review` now rejects it and points back to the right PR under review. I think as long as I'm understanding correctly that if `ctx.pr_number` is set the model should use that number, then I'm quite confident this change will fix the issue.

Every bullet above shows up: greeting then straight to the point, flowing clauses, one link plus two identifiers, plain "I got Claude to", confidence conditional on a stated assumption, nothing about the deploy/infra side. The AI-sounding version telegraphs the same facts into one-claim-per-line bullets listing both test files, `3/3`, "runs in CI", and an infra parenthetical: every fact true, and it reads like a status report, not a person.

## Worked example: review request

> Hey, non-urgent pr to make triage treat .claude/settings.json hook changes as advisory instead of risk: high: https://github.com/scorecard-ai/scorecard/pull/980
>
> Also, the replay mode + grading harness from #960 aren't on main. Do you still have them? I think we should commit them so rule edits like this one have a check.

The first draft of this was three paragraphs explaining the motivating PR, the design reasoning, and an offer to do the work. All of it was already on the PR. What survived is the ask, the link, and the one follow-up question.
