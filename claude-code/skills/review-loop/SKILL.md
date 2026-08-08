---
name: review-loop
description: Use by default after any substantive change before declaring done — proactively, not only when asked — or when user says "review loop", "review-and-fix until clean", or asks to review approach and implementation separately. Skip only trivial edits (rename, typo, one-line config).
---

# Review loop

Two reviewer subagents, every round. Directional judges the *approach* vs problem. Correctness judges the *implementation* vs approach. Catches both a sound plan built buggy and a clean build of the wrong plan.

This is a fix-and-re-review loop; for a review-only third-party pass with no fixes, run the reviewers once and report instead.

Skip for trivial changes (rename, typo, one-line config).

## Loop

1. Build one context packet. Both reviewers get identical copy.
2. Spawn both reviewers parallel, read-only; collect findings. Neither has actionable feedback → exit, done.
3. Fix every actionable finding unless a tradeoff justifies declining. Record declines + reason.
4. Back to 1 with a changelog of what changed.

## Step 1 — Context packet

Reviewers lack your conversation history; the packet must stand alone:

- **Problem.** What's wrong/needed, concrete. Point at symptom, not your framing.
- **Desired outcome.** What "solved" looks like.
- **Approach.** How the solution solves it, and *why this way* — key decisions, rejected alternatives.
- **Implementation.** The change. `git diff` + paths to read in full. Enough to verify, not a tour.
- **Constraints.** What bounds the solution: compat, perf budget, deadline, "can't touch X", patterns to match.

## Step 2 — Spawn two reviewers

Both at once, read-only. Neither sees the other's output — independence is the point, else they anchor.

Sample questions below are a prod, not a checklist. Tell each reviewer: **think what this problem and solution most need scrutinized, review that.**

### Directional — right approach?

Judge intent and approach vs problem, not code. Starters:

- Simplest approach that fully works? Cheaper/smaller solution exist?
- What does it fail to handle — edge cases, scale, failure modes out of reach?
- Different framing that dissolves the problem instead of solving it?

### Correctness — build matches approach?

Take approach as given, validate the implementation delivers it. Starters:

- Follows the stated approach or quietly diverges?
- Parts claiming to do X actually do X? Trace load-bearing paths.
- **One fact duplicated across places — did every copy move?** (The reviewer side of the always-on artifact-sweep rule in `~/CLAUDE.md`.) When the diff changes a value, name, or rule that's represented in more than one place, the stale copy lives *outside* the diff, so reading only the changed lines can't catch it. Grep the repo for the concept, not the diff: a string that must match between producer and consumer, a rule enforced in both client and server, a schema vs the migration that mirrors it. Confirm every copy moved, or a mechanism (single source of truth, drift-guard test, exhaustiveness check) makes divergence impossible.

**Test coverage — explicit charge, not optional.** A test that mocks the thing under test is theater. Missing or weak coverage on a load-bearing path is `must-fix`, not a `nit`.

### Output contract

Findings in this shape so triage is mechanical:

- **severity** — `must-fix` (breaks outcome), `should-fix` (real weakness, no strong reason to leave), `nit` (taste, optional).
- **location** — file:line, function, or decision challenged.
- **what** — problem, one sentence.
- **why** — consequence if left.
- **direction** — where to take it, not the exact patch.

No `must-fix`/`should-fix` → reviewer says **"no actionable feedback"** outright. No praise, no padding. That phrase ends the loop.

If asked to deliver findings via Hunk (the `/hunk` inline-comment reviewer) and no live Hunk session exists or it can't load the worktree, return findings as structured text in this shape; don't retry Hunk.

Example finding:

- **severity:** must-fix
- **location:** `processTrace` (`activities.ts:1108`)
- **what:** reads `labels.user_id` but never falls back to `run.user_id`, so trace records with labels-only attribution get a null creator.
- **why:** the "Created By" column renders "Anonymous" for every labeled record, the exact bug this change set out to fix.
- **direction:** fall back to the run's owner when the label has no user; don't hardcode a sentinel.

## Step 3 — Triage and fix

Fix every `must-fix` and `should-fix`. Default is fix, not debate. The exception is a finding that widens scope (a hardening idea, work beyond the change's locked scope): that routes through the scope-first triage in `~/CLAUDE.md` (this-round vs. follow-up, put to the user), never fixed silently.

Decline only when balance favors leaving it — fix costs more than flaw, breaks a constraint, or reviewer missed packet context. On decline, **write the finding + reason in your response**; a silent skip reads as "addressed everything".

`nit` optional — take the near-free ones, drop the rest.

Fix the cause, not the symptom; a silencing patch returns next round.

Comment findings follow the global code-comments rule in `~/CLAUDE.md`: reviewers propose DELETE, not rewrites, for comments that fail its bar.

## Step 4 — Loop or exit

**Exit** when both reviewers say "no actionable feedback" same round. Converged.

**Else** re-run from step 1. Same packet + a **changelog**: what changed, and why for any decline, so reviewers verify fixes instead of re-deriving.

## Guardrails

- **Cap rounds at 4.** Still churning after four usually means an unstated disagreement a human breaks. Hit the cap → **stop, surface unresolved findings to user.** No silent loop, no false done.
- **No scope widening.** Reviewers review the solution to *this* problem. A rewrite of an untouched neighbor is out of scope unless the change broke it.
- **"Wrong" ≠ "different."** A directional reviewer's preferred approach is a finding only if the current one is worse, not merely other.
- **Independence each round.** Reviewers see the solution + changelog, never each other's reports.
