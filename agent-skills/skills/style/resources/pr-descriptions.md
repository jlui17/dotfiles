# PR descriptions

The body makes a reviewer fast and confident, not a restage of the diff. The diff shows *what changed*; the description carries what it can't: **what was happening** (the behavior, in plain terms) and **what we're doing about it conceptually**. Spend words there; cut anything readable straight from the code.

## The arc

The compact core of this arc is always-loaded in `rules.d/40-explaining-work.md`; update both together so they don't drift.

The beats a good description covers when they apply. **Guidelines, not a required template**: a one-line fix gets a sentence or two, a large feature gets the full arc. Headers vary freely; skip a beat when it's absent or the code makes it obvious; format however reads best (prose, headers, bullets).

1. **Problem**: what's happening today, why it's wrong, and who/what it hurts, in user-visible behavior terms, not internals. For a system the reviewer likely hasn't touched, open with one line of orientation: what the component is, what breaks when it breaks ("a colony-vm build packs the prod databases into one image the eval platform boots; if it fails, no new eval environment ships").
2. **Root cause**: the specific code or condition producing that behavior. Its own beat: the problem is what the reader sees, the root cause is why it happens. Cite the code, don't restate it.
3. **Fix / Changes**: the new desired behavior, the conceptual fix that produces it, and why it's sound. Give the architecture's shape if the solution has one, name a rejected alternative in a line when one was live, and point at the code that proves the behavior holds.
4. **Verification**: what you ran and what each run proves, paired with the concern it answers (see below).
5. **Limits / Out of scope**: what the approach costs, what it deliberately doesn't cover, and what's safe to leave alone and why ("normal-sized sessions still get the full transcript, so this only touches the ones already failing"). Bold the load-bearing limit (voice #6).
6. **Follow-ups**: the next problem, named so it stays visible without scope-creeping this PR.

The weight is on 1-3; 5 and 6 stay short. Don't pad a small change to hit every beat.

## Lead in plain English, behavior first

Write so someone who's never seen the code gets the problem (beat 1) and the idea (beat 3), in that order:

- Behavior: "The worker hands the model a session's entire transcript. A few very large sessions don't fit the input limit, so the call fails and those annotations never get processed."
- Concept: "The model doesn't need the whole conversation to read an annotation, just what was happening around it. So we send the slices near each annotation plus a bit of the start and end."

Weak drafts open on the solution ("Adds windowing to...") or dump a feature list of internals ("short-circuits when under budget, hard cap with a warning, sentinel turns..."). Flip it: behavior, then concept, then the architecture's shape, then point at the code. If a reviewer needs the prose to follow the *mechanism*, the code isn't self-documenting: fix the code, not the writing.

## High-level architecture vs. mechanism

The line: **architecture is the shape a reviewer must agree with; mechanism is detail the code already shows.**

Prose, yes (architecture):
- The few moving parts and who owns what ("a new `Windower` slices the transcript; the worker just calls it").
- A load-bearing *decision* a reviewer must agree with and the code won't surface ("we keep the original turn numbers so the model's citations stay valid"). State it as a property + reason, never a jargon checklist. When the code and tests already make it obvious, skip it.

Code's job, not prose (mechanism): how turns are selected, exact window sizes and caps, parameter names, data threading, call order: anything a behavior-preserving refactor would obsolete. Even a single internal helper or flag is mechanism leak: naming `_run` or `check=True` makes the reader chase code; state the behavior instead ("a rejected push fails the build").

## Stand alone for a cold reviewer

Assume the reviewer hasn't read the ticket and doesn't know this corner of the system; the body carries them on its own.

- **Spell out an unfamiliar term inline on first use**: "the Collector (the service that ingests traces)". Skip the dead-obvious.
- **A cited file or symbol gets a one-clause definition and why it's relevant, never a bare name.** "Same pattern in `vm_warm.py` and `vm_snapshot.py`" tells a stranger nothing; "both build layers that push images (`vm_warm` = warm base, `vm_snapshot` = data restored in), so the fix lands in both" does. Name for findability, but earn the name.
- **Stand-alone holds per section, not just per document.** Reviewers jump straight to Verification or Limits, so each section re-grounds its own load-bearing nouns instead of borrowing a term ("the crash", "the predicate") only the root-cause prose defined. A section that only parses if you've memorized an earlier one isn't standalone.

## Verification and non-goals

Group proofs by the claim they prove, never a flat activity log ("we ran X, then Y" tells the reviewer neither what's proven nor why the method is trustworthy). A single behavior gets flat bullets (subject + what it proves); several claims or mixed methods get one group per claim. Each entry:

- **Reads on its own in four beats**: the broken behavior in plain terms → how you exercised it → what you saw → why that proves the fix. Open in plain behavior, not a noun from an earlier section: "the build used to crash when the smoke step read a user's email out of a `null` login response", not "the crash is pure Python (a `null` fed through the predicate)". The plain-behavior opening is the beat drafts most often skip.
- **Bold lead = the proven behavior, method in a parenthetical**: "**The smoke test no longer dies on a bad token (`test_smoke.py::test_bad_token_fails_loud`).**"
- **A half-line of the concern before the evidence** ("could the retry loop hammer a healthy service? 3 attempts, 2s apart, in the run log"), so the reviewer knows what's at stake before reading the numbers.
- **A test-backed claim names the actual test** (`` `test_file.py::test_name` ``), never a bare "unit tests", here or anywhere in the description: an independent reviewer must be able to open it without grepping. Name the one or two load-bearing tests per claim, not the whole suite (over-citation reads as padding; findability is the goal).
- **Live/integration proof (a real run, a probe on real infra) = the steps you took**: 2-4 numbered steps under the concern, behaviorally described (what you did, what you observed, what that proves when it isn't obvious). Not a command dump, and not the outcome alone ("all 8 jobs green" is a claim, not a proof: the reviewer can't tell what was exercised).
- **When methods mix, say why the method fit the claim**: "pure logic, so a unit test pins it with no infra" vs "the real failure only reproduces in prod, so verify the decision directly".

**Non-goals**: what you didn't do and why deferred. Part of Limits / Out of scope (beat 5); keeps the next problem visible without scope-creeping this PR.

## Condense pass

Evidence-dense is the right density; the failure mode is restating, not over-citing. After drafting, keep every claim and its evidence, cut restatement, scaffolding, and anything the diff already shows. A thorough draft usually condenses by half without losing a claim. Report every test you ran, as concisely as each proof allows.

## After the first push

The body stays accurate for the life of the PR. Strong defaults, sized to the PR:

- **Later commits that change the story get an "Update" section** prepended with the head SHA, and the superseded body text marked as superseded, so the body never claims something the diff no longer does.
- **Fold review and chat answers back into the body**: a question one reviewer asked is a gap the next reviewer will hit.
- **Post-merge verification lands as a PR comment with numbers** ("Post-merge prod verification: PASS across the board"), not silence.
- **Review responses are numbered dispositions**, each mapping the comment to its fix commit SHA. Declining is fine when the reason is stated: "**Minor: `bash -e` without `pipefail`: leaving it.** A behavior change worth its own scoped pass, not a rider here."
- **Scope stays clean**: unrelated tooling that rode along gets split to its own PR, ideally before a reviewer has to ask.

## Where effort goes

The weak part is almost always a missing plain-English problem statement plus too much internal mechanism. Put the effort on the opening behavior/concept beats and the architecture's shape; trust the code for the rest. Keep Limits and Follow-ups short.
