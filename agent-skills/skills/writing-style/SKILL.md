---
name: writing-style
description: Write technical docs in Justin's voice — tech plans, PR/commit descriptions, design docs, RFCs, code comments, Slack/review messages. Use whenever drafting prose Justin will publish under his name, including writing a PR/pull-request description, or when asked to "write like me" / match his style. The voice is in SKILL.md; per-artifact structure is in resources/ (tech-plans.md, pr-descriptions.md, design-critiques.md) — read the matching one first.
---

# Writing style: Justin

Voice is constant across every artifact. Format/density flexes by type (see Registers). When in doubt, plainer and shorter.

## The voice (constant)

Holds everywhere — plan, PR, comment, Slack.

1. **Code identifiers are sentence subjects.** Name the actor, give it the verb.
   - Yes: "`processTrace` reads it into a single `traceUserId` and passes it to `createRun`."
   - No: "The user ID is read and then passed along to the run creation logic."

2. **Current behavior, then the delta — "Today X → we'll do Y."** Anchor every proposed change against what exists now.
   - "Today it only forwards the org ID. We will also forward the creator's user ID."

3. **Append the reason, never its own sentence.** Use `because`/`since`/`so`/`which`.
   - "the only place we can resolve the creator", "so it's the trusted key owner"

4. **Point at the concrete artifact, pitched to the reader.** Every claim names the file/line/function/metric/column, usually parenthetical. Cite what *this* reader can resolve: file:line for a code reviewer, the metric/number for a report reader. Don't name internal columns or script paths a non-engineer can't open.
   - "(`activities.ts:1108`)", "(`reportIfTraceUserMismatch`)", "the `search_text` column"
   - For a non-technical report: "~931K chars (5% of the corpus)", not "summed from `note_full` + `supplemental_context` extracted on the VM".

5. **Pre-empt the obvious objection in one clause.** Answer the reader's next question first.
   - "There's no frontend changes required since the Records table already renders...", "not a client-supplied field that could be spoofed"

6. **Honest about scope and limits. No politeness-hedging.** State weaknesses plainly, bold if load-bearing.
   - "**Key Limitation: Existing Trace Records are not backfilled.**", "no E2E test through the Collector; probably acceptable because..."

7. **Dry restraint, mild editorializing, never hype.** Opinions land in short asides.
   - "to avoid footguns and confusion", trailing "for now..."

8. **One idea per sentence.** Short declarative over clause-stacking. Two ideas joined by "and"/"which"/comma → split.
   - Yes: "`processTrace` reads the user ID. It passes that to `createRun`."
   - No: "`processTrace` reads the user ID, which it then passes to `createRun` after validating it isn't null and logging the result."

9. **Anyone can follow, not just experts.** Add the one bit of context a newcomer needs. Skip dead-obvious (don't explain what a function or API is).
   - Yes: "the Collector (the service that ingests traces) drops the attribute."
   - No: "the Collector drops the attribute." (reader doesn't know what it is)
   - No: "the Collector, which is a piece of software that runs as a process, drops the attribute." (over-explained)

10. **Subjective UX claims get a subjective qualifier — not banned hedging.** Mark feel/read claims with "to me"/"read as"/"looked"/"felt like" — signals personal-experience report, opposite of politeness hedging (#6).
    - Yes: "The top summary read as mostly empty to me."
    - No: "It might perhaps be slightly cleaner to maybe consider..."

11. **Reframe a confusing thing with the mental model that unlocked it.** State it, italicize the pivot, list options in that frame.
    - "the Scorecard / GitHub / Endpoint choice is really about *who owns the input→output step*" → one bullet per option.

12. **Describing a change: behavior first, mechanism only if it earns its place.** Lead with what's different in outcome terms. Add the technical cause only when the reader needs it for context, or the change is inherently low-level. Holds everywhere, Slack and status updates included, not only PR descriptions.
    - Yes: "Counts all annotation text now. The old script read `created_at` not `applicable_when`, so the span looked like 3 days."
    - No: "Switched the annotations span query from `created_at` to `applicable_when`." (mechanism, no behavior)

## Punctuation & emphasis

- **Bold** = the one load-bearing claim/decision per paragraph (the skimmable thing). Often a bold lead-in: "**Attribution is forward-looking / source-agnostic:** ..."
- *Italics* = the single pivot/limiting word: "the *only* place", "*after* a backfill". Bold = the claim; italics = the word limiting it.
- **`→`** for chains/transitions: "`api_key_user_id → parent run's user → background-job`".
- **`/`** joins two ideas into one concept-name: "read/list", "first-writer-wins".
- **Em-dashes: AVOID.** Prefer parenthetical, colon, comma, or fresh sentence. Em-dash only when nothing else carries the aside — rare.
- **Parentheticals** scope precisely: "(i.e. Records with a `trace_id`)", "(nullable)", file:line.
- **Backticks** on every code identifier, column, attribute, UI string ("Created By", "Anonymous").
- Short-to-medium sentences. Long ones are linear "if X, then Y" mechanism, not nested clauses. Starting with "So"/"But"/"Today" is fine.
- Logic as inline operators, not paraphrase: "`labels.user_id ?? run.user_id`", not "the labels value, or the run's user if absent".

## Structure (general)

- **Open straight on the problem.** No throat-clearing. "Trace records show 'Created By' as **'Anonymous'** instead of the user who created them."

Artifact-specific structure lives in the per-scenario resource files — see Registers.

## Registers (flex by artifact)

Same voice, different density. Read the matching resource first.

| Artifact | Density | Read first |
|----------|---------|------------|
| **Tech plan / design doc / RFC** | Formal, spacious. Numbered sections, fixed schemas, tradeoff tables, named alternatives. | `resources/tech-plans.md` |
| **PR description** | Plain English, behavior first. Lead with what's happening + the conceptual fix; push mechanism into the code. Dense prose is fine, jargon dumps aren't. | `resources/pr-descriptions.md` |
| **Design critique / UX walkthrough** | First-person, experiential. Actor flips from code to *you*. Fixed schema, captioned screenshots, priority up front. | `resources/design-critiques.md` |
| **Code comment / Slack / review** | Most compressed. One claim per line, point at the artifact, drop scaffolding. Still: actor-as-subject, append-reason, no hype. Describing a change here? Behavior first (#12), mechanism only if needed. | (inline — this row is the guidance) |

## Anti-patterns

- Throat-clearing intros ("In order to address this issue, we will...").
- Politeness hedging ("It might be worth considering perhaps...").
- Abstract nominalizations where a verb works ("perform a resolution of" → "resolve").
- Paraphrasing code logic when an operator is clearer.
- Marketing tone, exclamation, praising the design.
- Claims with no artifact to point at.
- Em-dashes for asides → recast as parenthetical/colon/comma/separate sentence.

## Self-check

- Actor of each sentence = the actual code thing doing the work?
- Showed "today → change", not only the change?
- Every claim anchored to file/function/column?
- Bolded exactly the load-bearing claims (not decoration)?
- Cut every "just/really/basically" and politeness hedge?
- Honest about limits and what's *not* covered?
- No em-dashes — asides recast?
- One idea per sentence — clause-stacks split?
- A newcomer could follow — context added where needed, dead-obvious cut?
