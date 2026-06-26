# PR descriptions

The body makes a reviewer fast and confident, not a restage of the diff. The diff shows *what changed*; the description carries what it can't: **what was happening** (the behavior, in plain terms) and **what we're doing about it conceptually**. Spend words there. Cut anything readable straight from the code.

## What a PR description captures

These are the pieces a good PR description carries when they apply. **Guidelines, not a required template.** Scale to the change: a one-line fix gets one or two sentences; a large feature gets all of it. Skip a piece when it's absent (no real alternatives → say so in a clause, or drop it) or when the code makes it obvious. Format however reads best (prose, headers, bullets) — these are the *contents* to cover, not a fixed schema.

1. **Problem + context** — what's happening today and why it's wrong, in user-visible behavior terms. The behavior that's exhibited, not the internals.
2. **The behavioral solution** — the new desired behavior, conceptually. What's different in outcome terms, and why that's the right fix.
   - **2a. High-level architecture** — the shape of the solution that produces that behavior: the few moving parts and how they fit. High-level only (the *what owns what*), not param names, caps, or call order.
   - **2b. The code that proves it** — point at the specific code and tests that demonstrate the new behavior actually holds. This is where you let the diff and tests talk; cite, don't restate.
3. **Pros, cons, limitations** — what the approach buys, what it costs, and what it deliberately doesn't cover. State limits plainly and bold the load-bearing one (#6 in the voice).
4. **Alternatives considered** — briefly: what else you weighed and why this won. One line each. If there were none worth naming, say so or omit.

The weight is on 1 and 2. 3 and 4 are short. Don't pad a small change to hit every bullet.

## Lead in plain English, behavior first

Write so someone who's never seen the code gets the problem and the idea. Two beats, in order:

1. **What's happening** — current behavior and why it's wrong, in user-visible terms. No internals yet. ("The worker hands the model a session's entire transcript. A few very large sessions don't fit the input limit, so the call fails and those annotations never get processed.")
2. **What we're doing about it** — the *idea*, conceptually. Why it works, not how it's wired. ("The model doesn't need the whole conversation to read an annotation — just what was happening around it. So we send the slices near each annotation plus a bit of the start and end.")

Then give the high-level architecture if the solution has real shape (2a), and point at the code and tests that prove the behavior (2b). Keep low-level mechanism in the code. If a reviewer needs the prose to follow the *mechanism*, the code isn't self-documenting — fix the code, not the writing.

Weak drafts open on the solution ("Adds windowing to…") or dump a feature list of internals ("short-circuits when under budget, hard cap with a warning, sentinel turns, retro widening…"). Cut that. Flip it: behavior, then concept, then the architecture's shape, then point at the code.

## High-level architecture vs. mechanism

The line: **architecture is the shape a reviewer must agree with; mechanism is detail the code already shows.**

Prose, yes (architecture):
- The few moving parts and who owns what ("a new `Windower` slices the transcript; the worker just calls it").
- A load-bearing *decision* a reviewer must agree with and the code won't surface ("we keep the original turn numbers so the model's citations stay valid"). State it as a property + reason, never a jargon checklist.

Code's job, not prose (mechanism):
- How turns are selected, exact window size, cap value, parameter names.
- Data threading and call order.
- Anything a behavior-preserving rename or refactor would obsolete. Cut it.

When the code and tests already make a decision obvious, skip it.

## The wrong behavior and who it hurts; what's safe to leave alone

Always worth prose:
- The wrong behavior and who/what it hurts.
- The conceptual fix and why it's sound.
- What's deliberately unchanged or out of scope, and why it's safe ("normal-sized sessions still get the full transcript, so this only touches the ones already failing").

## Define the proper nouns

Spell out an unfamiliar term inline on first use: "a git worktree (a separate checkout of the same repo on its own branch)", "the Collector (the service that ingests traces)". Skip what's dead-obvious.

## Test plan and non-goals

- **Test plan** — flat declarative bullets, each = subject + what it proves. This is part of 2b: the tests are the proof the behavior holds. Already verifiable, rarely needs rework; leave a good one alone.
- **Non-goals** — what you didn't do and why deferred. Part of limitations (#3). Keep the next problem visible without scope-creeping this PR.

## Where effort goes

The weak part is almost always a missing plain-English problem statement plus too much internal mechanism. Put the effort on the opening "what's happening / what we're doing" beats and the architecture's shape. Trust the code for the rest. Keep 3 and 4 short.
