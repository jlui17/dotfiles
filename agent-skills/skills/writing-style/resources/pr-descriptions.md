# PR descriptions

The body makes a reviewer fast and confident — not a restage of the diff. The diff shows *what changed*. The description carries what it can't: **what was happening** (the behavior, in plain terms), and **what we're doing about it conceptually**. Spend words there. Cut everything readable straight from the code.

## Lead in plain English, behavior first

Write so someone who has never seen the code understands the problem and the idea. Two beats, in order:

1. **What's happening** — the current behavior and why it's wrong, in user-visible terms. No internals yet. ("The worker hands the model a session's entire transcript. A few very large sessions don't fit the input limit, so the call fails and those annotations never get processed.")
2. **What we're doing about it** — the *idea*, conceptually. Why it works, not how it's wired. ("The model doesn't need the whole conversation to read an annotation — just what was happening around it. So we send the slices near each annotation plus a bit of the start and end.")

Then stop and let the code talk. The mechanism — data structures, parameters, caps, flags, the call sequence — lives in the **code and tests**, not the prose. If a reviewer needs the description to follow the mechanism, the code isn't self-documenting; fix the code, not the writing.

Weak drafts open on the solution ("Adds windowing to…") or dump a feature list of internals ("short-circuits when under budget, hard cap with a warning, sentinel turns, retro widening…"). That's the mumbo-jumbo to cut. Flip it: behavior, then concept, then point at the code.

## What earns prose vs. what stays in the code

Prose, yes:
- The wrong behavior and who/what it hurts.
- The conceptual fix and why it's sound.
- What's deliberately unchanged or out of scope, and why it's safe ("normal-sized sessions still get the full transcript, so this only touches the ones already failing").

Code's job, not prose:
- How turns are selected, the exact window size, the cap value, the parameter names.
- The data threading and call order.
- Anything a behavior-preserving rename or refactor would obsolete — that's mechanism. Cut it.

A load-bearing *decision* (e.g. "we keep the original turn numbers so the model's citations stay valid") can earn one plain sentence when a reviewer must agree with it and the code alone won't surface the why. State it as a plain property + reason — never a jargon checklist. When the code and tests already make it obvious, skip it.

## Define the proper nouns

Spell out an unfamiliar term inline on first use: "a git worktree (a separate checkout of the same repo on its own branch)", "the Collector (the service that ingests traces)". Skip what's dead-obvious.

## Test plan and non-goals

- **Test plan** — flat declarative bullets, each = subject + what it proves. Already verifiable, rarely needs rework; leave a good one alone.
- **Non-goals** — what you didn't do and why deferred. Keep the next problem visible without scope-creeping this PR.

## Where effort goes

The weak part is almost always a missing plain-English problem statement plus too much internal mechanism. Put the effort on the opening "what's happening / what we're doing" beats. Trust the code for the rest.
