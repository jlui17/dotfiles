---
name: review-loop
description: Harden a solution by looping two review subagents (directional + correctness) and fixing feedback until it converges. Use after a non-trivial change before declaring done, or when user says "review loop", "review-and-fix until clean", or asks to review approach and implementation separately.
---

# Review loop

Two reviewers, every round. Directional judges the *approach* vs problem. Correctness judges the *implementation* vs approach. Catches both a sound plan built buggy and a clean build of the wrong plan.

Skip for trivial changes (rename, typo, one-line config). Loop costs two subagent runs per round.

## Loop

1. Build one context packet. Both reviewers get identical copy.
2. Spawn both reviewers parallel, read-only.
3. Collect findings. Neither has actionable feedback → exit, done.
4. Fix every actionable finding unless a tradeoff justifies declining. Record declines + reason.
5. Back to 1 with a changelog of what changed.

## Step 1 — Context packet

Reviewers lack your conversation history. Packet must stand alone. Both get the same one:

- **Problem.** What's wrong/needed, concrete. Point at symptom, not your framing.
- **Desired outcome.** What "solved" looks like.
- **Approach.** How the solution solves it, and *why this way* — key decisions, rejected alternatives.
- **Implementation.** The change. `git diff` + paths to read in full. Enough to verify, not a tour.
- **Constraints.** What bounds the solution: compat, perf budget, deadline, "can't touch X", patterns to match.

## Step 2 — Spawn two reviewers

Both at once, read-only. Neither sees the other's output — independence is the point, else they anchor.

Sample questions below are a prod, not a checklist. Tell each reviewer: **think what this problem and solution most need scrutinized, review that.** Top finding is usually one no generic checklist names.

### Directional — right approach?

Judge intent and approach vs problem, not code. Starters:

- How does this approach tackle the problem? Solves the stated problem or an adjacent one?
- Simplest approach that fully works? Cheaper/smaller solution exist?
- Tradeoffs conscious? What does it give up?
- What does it fail to handle — edge cases, scale, failure modes out of reach?
- Different framing that dissolves the problem instead of solving it?

### Correctness — build matches approach?

Take approach as given, validate the implementation delivers it. Starters:

- Follows the stated approach or quietly diverges?
- Where wrong — logic, edge cases, off-by-one, wrong condition, missed case?
- Parts claiming to do X actually do X? Trace load-bearing paths.
- Breaks under concurrency, failure, empty input, large input?
- Tested where it matters? Tests prove the claim or just pass?

### Output contract

Findings in this shape so triage is mechanical:

- **severity** — `must-fix` (breaks outcome), `should-fix` (real weakness, no strong reason to leave), `nit` (taste, optional).
- **location** — file:line, function, or decision challenged.
- **what** — problem, one sentence.
- **why** — consequence if left.
- **direction** — where to take it, not the exact patch.

No `must-fix`/`should-fix` → reviewer says **"no actionable feedback"** outright. No praise, no padding. That phrase ends the loop.

## Step 3 — Triage and fix

Fix every `must-fix` and `should-fix`. Default is fix, not debate.

Decline only when balance favors leaving it — fix costs more than flaw, breaks a constraint, or reviewer missed packet context. On decline, **write the finding + reason in your response.** Silent skip reads as "addressed everything" when it wasn't.

`nit` optional — take the near-free ones, drop the rest.

Fix the cause, not the symptom. A patch that silences the finding without fixing the cause returns next round.

## Step 4 — Loop or exit

**Exit** when both reviewers say "no actionable feedback" same round. Converged.

**Else** re-run from step 1. Same packet + a **changelog**: what changed, and why for any decline. Lets reviewers verify fixes instead of re-deriving, and stops resolved findings resurfacing.

## Guardrails

- **Cap rounds at 4.** Most converge in 1–2. Backstop against a loop that won't settle — still churning after four usually means an unstated disagreement a human breaks. Trades runaway cost vs convergence room; guessed, not measured, so raise if a task class needs more. Hit the cap → **stop, surface unresolved findings to user.** No silent loop, no false done.
- **No scope widening.** Reviewers review the solution to *this* problem. A rewrite of an untouched neighbor is out of scope unless the change broke it.
- **"Wrong" ≠ "different."** A directional reviewer's preferred approach is a finding only if the current one is worse, not merely other. Weigh it, don't reflex-adopt.
- **Independence each round.** Reviewers see the solution + changelog, never each other's reports.
