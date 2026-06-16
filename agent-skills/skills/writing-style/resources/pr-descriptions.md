# PR descriptions

The body makes a reviewer fast and confident — not a restage of the diff. The diff shows *what changed*. The description carries what it can't: **why** the change exists, **how** it works (design decisions, invariants), **what impact** on users/callers. Spend words there. Cut everything readable straight from the code.

## The shape

Lead with the problem in user-visible terms, before naming the fix.

- Open on current pain / wrong behavior, anchored against status quo ("Today X / Currently Y"). Reviewer needs the problem to judge the solution.
- One sentence: "This PR does Z."
- Design decisions and invariants (**Key Changes** list, below).
- Non-goals: what you deliberately didn't do, why deferred.
- Test plan: flat declarative bullets, each = subject + what it proves.

Weak drafts open on the solution ("Adds tooling to…") and assume the problem. Flip it.

## Always use a Key Changes list

Every PR gets a **Key Changes** list (numbered or bold-lead-in bullets) naming the load-bearing *decisions* — choices and invariants a reviewer must agree with. Not a file-by-file changelog.

An entry states a property the code now holds and why:
> 1. **The attribution source is easy to re-point.** The binding lives in one place, so re-attributing later (e.g. to an end-user id) is a small change, not a refactor.
> 2. **A creator is set once, at creation (first-writer-wins).** Later merges leave the original owner untouched, matching how `org_id` is already handled.

Does NOT belong: "`processTrace` reads `api_key_user_id` into `traceUserId` and passes it to `createRun`." That's code flow — the diff shows it, and it rots on a rename.

## Don't narrate code flow — make the code self-documenting

If the description must spell out the call sequence / data threading / exact edits to be understood, the **code** isn't self-documenting — fix the code, not the prose. Name functions and variables so the flow reads itself. Then the description is free for why and impact.

Test: if a line would be obsoleted by a behavior-preserving rename/refactor, it's mechanism, not design. Cut it or push the clarity into the code.

Exception: one short narrative pass when a mechanism genuinely needs framing (see "Mechanism then components" in tech-plans.md). One pass, then re-list by decision.

## Why / How / Impact

- **Why** — the user-visible problem and who it hurts. "Trace records show their creator as **'Anonymous'**… so you can't filter by who's doing what."
- **How** — design decisions, trust assumptions, invariants. "The Collector verifies the key against Clerk server-side, so the creator is trusted, not a spoofable client value."
- **Impact** — what callers/users see now, and what's explicitly unchanged. "Does **not** change the read/list API; that's a follow-up after a backfill migration, which keeps that change much simpler."

## Define the proper nouns

Spell out the unfamiliar term inline on first use: "a git worktree (a separate checkout of the same repo on its own branch)", "the Collector (the service that ingests traces)", "Clerk (our auth provider)". Skip what's dead-obvious.

## Where effort goes

Test plans rarely need rework — already verifiable. The weak part is missing motivation plus too much mechanism. Put effort on the opening problem statement and the Key Changes decisions; leave a good test plan alone.
