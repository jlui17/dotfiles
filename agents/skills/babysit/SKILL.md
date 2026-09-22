---
name: babysit
description: Use when Justin says "babysit" a PR, or asks to carry a PR through its automated feedback: bot reviews, triage, CI on each push. Also when asked to merge and a branch rule blocks the merge.
---

# Babysitting a PR

Justin's definition: loop over the automated feedback on a PR, fixing and replying and resolving on GitHub, until a poll on the current head shows nothing left to address. Stop and align with him only when blocking feedback is valid and either contradicts a decision we made together or meaningfully expands the PR's scope. Everything else is yours to handle. Summoning a bot (`@claude review`, `@codex review`) is his, per `~/CLAUDE.md`.

Per-item handling is the `pr-feedback` skill (one commit per item, resolve the thread once addressed, feedback as a documentation signal); reply prose is the `style` skill; fixes go to workers per `~/CLAUDE.md`. This skill is the loop around them.

## The loop

1. Snapshot the PR: `scripts/gh-pr-status.sh OWNER/REPO PR [SINCE]` prints head SHA, checks on the head that are not green, unresolved threads, merge state, and issue comments since a time. Read everything against the head SHA: a comment or check carrying an older SHA is stale.
2. Sort the feedback (below). Fix the actionable items, one commit each, push.
3. Reply to each item with the fix SHA, or with the evidence that no change is needed, then resolve its thread.
4. Wait for the bots to finish on the new head. Review bots and triage post minutes after a push, CI a few minutes more. Then snapshot again.

Done when the snapshot shows no failing check on the head, no unresolved thread, and no bot comment newer than the head that asks for something. Report that state, and what still blocks the merge, since "no automated feedback left" is not "mergeable".

## Sorting feedback

Learned on real PRs; the bot roster changes, the classes hold.

- **Inline review threads** (Codex, Claude): actionable. A valid finding gets a fix; an invalid one gets a reply with evidence. Both get resolved.
- **Triage bot** (risk rating plus open questions): answer in one comment, "Dispositions as of `<sha>`", one bullet per question. It is a checklist for the human reviewer, so it gets a written answer, not just a fix.
- **Size or split suggestion**: reposts on every push. When we decided the PR stays whole, answer once with the reason (the halves are one contract, each unverifiable alone). Later identical reposts get no reply.
- **CI checks**: judge on the head. A check with conclusion `CANCELLED` whose workflow ran again was superseded; read the latest run's result. A failure in a package the PR did not touch is a pre-existing break: verify the touched packages individually and say so in the report.
- **Deploy, preview, coverage bots** (Vercel, Railway, Supabase, coverage tables): informational. Read the numbers, reply to none.

## Main moves under you

A long loop outlives main. When the snapshot shows `CONFLICTING`, merge main into the branch, keep both sides where both added to the same spot, regenerate generated clients (Prisma and the like) before typechecking, run the touched packages' checks, push. The bots re-run on the merge commit; that is a normal turn of the loop, not a new review.

## Merge gates

When asked to merge and the branch rule wants a human review, set auto-merge (`gh pr merge --squash --auto --delete-branch`) so the approval merges it, then tell Justin who can approve. An admin bypass goes out under his name: name the command, leave the run to him.
