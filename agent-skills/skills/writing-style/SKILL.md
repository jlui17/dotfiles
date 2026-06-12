---
name: writing-style
description: Write technical docs in Justin's voice — tech plans, PR/commit descriptions, design docs, RFCs, code comments, Slack/review messages. Use whenever drafting prose Justin will publish under his name, or when asked to "write like me" / match his style.
---

# Writing style: Justin

Write technical prose the way Justin writes it. The **voice** below is constant across every artifact. The **format/density** flexes by artifact type (see Registers).

Derived from Justin's tech plans and PR descriptions. When in doubt, prefer the plainer, shorter version.

## The voice (constant)

These hold everywhere — plan, PR, comment, Slack.

1. **Code identifiers are the subjects of sentences.** Name the actor and give it the verb.
   - Yes: "`processTrace` reads it into a single `traceUserId` and passes it to `createRun`."
   - No: "The user ID is read and then passed along to the run creation logic."

2. **Establish current behavior, then the delta. The "Today X → we'll do Y" move.** Always anchor a proposed change against what exists now.
   - "Today it only forwards the org ID. We will also forward the creator's user ID."
   - "were attributed to the synthetic `background-job` user. This PR attributes traces to the API key creator instead."

3. **Append the reason; never make it its own sentence.** Use `because` / `since` / `so` / `which`.
   - "the only place we can resolve the creator"
   - "so it's the trusted key owner"
   - "which keeps the read-logic change much simpler"

4. **Point at the concrete artifact.** Every claim names the file, line, function, metric, or column that implements it — usually parenthetical.
   - "(`activities.ts:1108`)", "(`reportIfTraceUserMismatch`)", "the `search_text` column"

5. **Pre-empt the obvious objection in one clause.** Answer the reader's next question before they ask.
   - "There's no frontend changes required since the Records table already renders..."
   - "not a client-supplied field that could be spoofed"

6. **Be honest about scope and limits. No hedging-for-politeness.** State weaknesses plainly, bolded if load-bearing.
   - "**Key Limitation: Existing Trace Records are not backfilled.**"
   - "no E2E test through the Collector; probably acceptable because..."

7. **Dry restraint, mild editorializing — never hype.** Opinions land in short asides.
   - "to avoid footguns and confusion", "it's too easy to just throw any kind of information in there", trailing "for now..."

## Punctuation & emphasis devices

- **Bold** marks the one load-bearing claim or decision in a paragraph — the thing you'd want skimmed. Often a bold lead-in opens a paragraph or bullet: "**Attribution is forward-looking / source-agnostic:** ..."
- *Italics* mark the single pivot/qualifying word the sentence turns on: "the *only* place", "*after* a backfill", "re-attributing *later*". Bold = the claim; italics = the word that limits it.
- **`→`** for chains and transitions: "Fallback chain: `api_key_user_id → parent run's user → background-job`", "missing attribute → `background-job`".
- **`/`** joins two related ideas into one concept-name: "read/list", "forward-looking / source-agnostic", "first-writer-wins", "Merge/update paths".
- **Em-dashes** attach a clarifying aside without a new sentence: "the request-context user — not a client-supplied field".
- **Parentheticals** scope precisely: "(i.e. Records with a `trace_id`)", "(nullable)", file:line refs.
- **Backticks** on every code identifier, column, attribute, and UI string state ("Created By", "Anonymous").
- Short-to-medium sentences. Longer ones are linear "if X, then Y" mechanism descriptions, not nested clauses. Starting a sentence with "So" / "But" / "Today" is fine.
- Write logic as operators inline, not paraphrased: "derive it as `labels.user_id ?? run.user_id`", not "use the labels value, or the run's user if absent".

## Structure habits

- **Open straight on the problem.** No throat-clearing. "Trace records show 'Created By' as **'Anonymous'** instead of the user who created them."
- **Explain the mechanism once narratively, then re-list by component.** Numbered flow for understanding; per-system "Key Changes" list for implementation. Deliberate redundancy.
- **Each step = actor + action + grounding.** "X already does Y (`file:line`). Today it only does Z. We will also do W."
- **Alternatives use a fixed mini-schema:** **Approach** / **Why rejected** (or **Why deferred** — keep the distinction; deferred means viable later). One or two sentences each.
- **Tables for tradeoffs/metadata.** One-word verdict column ("Neutral/Good", "Good"), Notes column for the nuance.
- **Test plans as flat declarative bullets**, each = subject + what it proves, with the proof in a parenthetical: "`createRecord` persists an explicit `userId` override (proving override beats the run fallback)." State what's proven, not how it runs.
- **Open questions numbered Q1/Q2 with an inline priority tag:** "Q2 (low priority): ..."

## Registers (flex by artifact)

Same voice, different density:

- **Tech plan / design doc** — more formal, spacious. Numbered sections, fixed schemas (Approach/Why rejected), tradeoff tables, named alternatives. Room to explain.
- **PR description** — denser, faster. More devices per sentence (`→`, `/`, italics), bold paragraph lead-ins, tight test-plan bullets. Compress.
- **Code comment / Slack / review** — most compressed. One claim per line, point at the artifact, drop the scaffolding. Still: actor-as-subject, append-reason, no hype.

## Anti-patterns (do not do)

- Throat-clearing intros ("In order to address this issue, we will...").
- Hedging for politeness ("It might be worth considering perhaps...").
- Abstract nominalizations where a verb works ("perform a resolution of" → "resolve").
- Paraphrasing code logic in English when an operator is clearer.
- Marketing tone, exclamation, or praising the design.
- Claims with no artifact to point at.

## Quick self-check before finishing

- Is the actor of each sentence the actual code thing doing the work?
- Did I show "today → change" rather than only the change?
- Is every claim anchored to a file/function/column?
- Did I bold exactly the load-bearing claims (not decorate)?
- Did I cut every "just/really/basically" and politeness hedge?
- Honest about the limits and what's *not* covered?
