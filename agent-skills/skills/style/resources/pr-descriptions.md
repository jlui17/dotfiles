# PR descriptions

The body makes a reviewer fast and confident, not a restage of the diff. The diff shows *what changed*; the description carries what it can't: **what was happening** (the behavior, in plain terms) and **what we're doing about it conceptually**. Spend words there. Cut anything readable straight from the code.

## The arc

These are the beats a good PR description covers when they apply. **Guidelines, not a required template.** Scale to the change: a one-line fix gets one or two sentences; a large feature gets the full arc. Headers vary freely; the arc underneath stays constant. Skip a beat when it's absent or the code makes it obvious. Format however reads best (prose, headers, bullets): these are the *contents* to cover, not a fixed schema.

1. **Problem**: what's happening today and why it's wrong, in user-visible behavior terms. The behavior that's exhibited, not the internals. For a system the reviewer likely hasn't touched, open with a "What this is" line first (what the component is, what breaks when it breaks), then the behavior.
2. **Root cause**: the specific code or condition producing that behavior. Its own beat, distinct from the problem: the problem is what the reader sees, the root cause is why it happens. Cite the code, don't restate it.
3. **Fix / Changes**: the new desired behavior and the conceptual fix that produces it. Give the architecture's shape if the solution has one (the few moving parts and who owns what, not param names, caps, or call order), name a rejected alternative in a line when one was live, and point at the code that proves the behavior holds. Cite, don't restate.
4. **Verification**: what you ran and what each run proves, paired with the concern it answers (see below).
5. **Limits / Out of scope**: what the approach costs, what it deliberately doesn't cover, and what's safe to leave alone. State limits plainly and bold the load-bearing one (#6 in the voice).
6. **Follow-ups**: the next problem, named so it stays visible without scope-creeping this PR.

The weight is on 1–3. 5 and 6 are short. Don't pad a small change to hit every beat.

## Lead in plain English, behavior first

Write so someone who's never seen the code gets the problem and the idea. Two beats, in order:

1. **What's happening**: current behavior and why it's wrong, in user-visible terms. No internals yet. ("The worker hands the model a session's entire transcript. A few very large sessions don't fit the input limit, so the call fails and those annotations never get processed.")
2. **What we're doing about it**: the *idea*, conceptually. Why it works, not how it's wired. ("The model doesn't need the whole conversation to read an annotation, just what was happening around it. So we send the slices near each annotation plus a bit of the start and end.")

Then give the root cause, the architecture's shape if the solution has one, and point at the code and tests that prove the behavior. Keep low-level mechanism in the code. If a reviewer needs the prose to follow the *mechanism*, the code isn't self-documenting: fix the code, not the writing.

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

## Make it stand alone for a cold reviewer

Assume the reviewer hasn't read the ticket and doesn't know this corner of the system. The body has to carry them top to bottom on its own.

- **Open with one line of orientation when the system isn't self-evident**: what the component is, what it's for, what breaks when it breaks ("a colony-vm build packs the prod databases into one image the eval platform boots; if it fails, no new eval environment ships"), then the behavior.
- **Spell out an unfamiliar term inline on first use:** "a git worktree (a separate checkout of the same repo on its own branch)", "the Collector (the service that ingests traces)". Skip what's dead-obvious.
- **A cited file or symbol needs a one-clause definition and why it's relevant, not a bare name.** "Same pattern in `vm_warm.py` and `vm_snapshot.py`" tells a stranger nothing; "both build layers that push images (`vm_warm` = warm base, `vm_snapshot` = data restored in), so the fix lands in both" does. Name it for findability, but earn the name.
- **Even a single internal helper or flag is mechanism leak.** Naming `_run` or `check=True` makes the reader chase code; state the behavior instead ("a rejected push fails the build"). Architecture-vs-mechanism applies at the smallest scale too.
- **Stand-alone holds per section, not just per document.** Reviewers jump straight to Verification or Limits without reading top to bottom, so each section has to re-ground its own load-bearing nouns. Don't let a later section borrow a term ("the crash", "the predicate") that only the root-cause prose defined; restate the behavior in plain words where it's used. A section that only parses if you've memorized an earlier one isn't standalone.

## Verification and non-goals

- **Verification**: tie each method to the claim it proves, not a flat log of what you ran. Each entry must read on its own as a small narrative in four beats: **the broken behavior in plain terms → how you exercised it → what you saw → why that proves the fix.** Lead the bold with the *proven behavior* (the claim) and put the method in a parenthetical: "**The smoke test no longer dies on a bad token (`test_smoke.py::test_bad_token_fails_loud`).**" Give each proof a half-line of the question or concern it answers, *before* the evidence ("could the retry loop hammer a healthy service? 3 attempts, 2s apart, in the run log"), so the reviewer knows what's at stake before reading the numbers. When the proof is a test, the parenthetical names the actual test (`` `test_file.py::test_name` ``), never a bare "unit tests" — an independent reviewer must be able to open the test and verify the claimed behavior without grepping for it. Same for any test-backed claim elsewhere in the description. Name the one or two load-bearing tests per claim, not the whole suite (over-citation reads as padding; findability is the goal). When the proof is live/integration validation (a real run, a probe on real infra) rather than a test, the proof is the *steps you took*: a short numbered list (2–4 steps) under the concern, behaviorally described — what you did, then what you observed, ending with what that proves when it isn't obvious. Not a command dump, and not just the outcome ("all 8 jobs green" alone is a claim, not a proof — the reviewer can't tell what was exercised). The plain-behavior restatement is what reviewers actually missed: an entry that opens "the crash is pure Python (a `null` fed through the predicate)" is unreadable to someone who hasn't memorized the root-cause section: say "the build used to crash when the smoke step read a user's email out of a `null` login response" instead. A single behavior gets flat bullets (subject + what it proves). When the change has several claims (e.g. multiple root causes) or mixes methods (unit test vs live run vs a logic-only check), group by the claim and make each entry also carry *why that method fit* ("pure logic, so a unit test pins it with no infra"; "shell against a live service, so it can't be unit-tested"; "the real failure only reproduces in prod, so verify the decision directly"). "We ran X, then Y" doesn't tell the reviewer what's proven or why the method is trustworthy.
- **Non-goals**: what you didn't do and why deferred. Part of Limits / Out of scope (beat 5). Keep the next problem visible without scope-creeping this PR.

## Condense pass

Evidence-dense is the right density; the failure mode is restating, not over-citing. After drafting, do a condense pass: keep every claim and its evidence, cut restatement, scaffolding, and anything the diff already shows. A thorough draft usually condenses by half without losing a claim. Report every test you ran, as concisely as each proof allows.

## After the first push

The body should stay accurate for the life of the PR. Strong defaults, sized to the PR:

- **Later commits that change the story get an "Update" section** prepended with the head SHA, and the superseded body text marked as superseded, so the body never claims something the diff no longer does.
- **Fold review and chat answers back into the body.** A question one reviewer asked is a gap the next reviewer will hit; add the answer to the description instead of leaving it in the thread.
- **Post-merge verification lands as a PR comment with numbers** ("Post-merge prod verification: PASS across the board"), not silence.
- **Review responses are numbered dispositions**, each mapping the comment to its fix commit SHA. Declining is fine when the reason is stated: "**Minor: `bash -e` without `pipefail`: leaving it.** A behavior change worth its own scoped pass, not a rider here."
- **Scope stays clean.** Unrelated tooling or scripts that rode along get split to their own PR, ideally before a reviewer has to ask.

## Where effort goes

The weak part is almost always a missing plain-English problem statement plus too much internal mechanism. Put the effort on the opening "what's happening / what we're doing" beats and the architecture's shape. Trust the code for the rest. Keep Limits and Follow-ups short.
