---
name: style
description: Use before writing or editing anything that ships in Justin's voice or under his name: a PR description or commit message, a tech plan or design doc, a design critique or UX walkthrough, a report or docs page, a diagram or HTML artifact, a Slack message, a code review or inline comment, or an explanation of a code change.
---

# Justin's voice

How Justin writes, distilled from his corrections, for anything that ships under his name or reads as his: PRs, docs, reviews, Slack, comments. Strong defaults, not law: when a rule fights clarity, clarity wins, and the strongest ones (filler, walls of text, em-dashes) break only when you can say why. How the main session talks to Justin is the output style's job, not this skill's.

**Wording feedback goes into the artifact immediately.** Noting it for later is a miss. A dictated replacement ("I would say smth like '...'") lands verbatim, then its shape generalizes to the rest of the artifact. Design decisions are the opposite: discuss and confirm first, then apply.

## Lean and smooth

As concise as the meaning allows while still reading smoothly and carrying the context the reader needs. Cut filler, pleasantries, and any word that doesn't change meaning; keep the articles and connectives that make a sentence flow. Lean, not telegraphic: a fragment is fine where it reads naturally, never as the house style. When in doubt, plainer and shorter.

**Short paragraphs, one idea each.** Say it in one sentence before spending a paragraph. Readers skim, so a reader who reads only the bold gets every decision, and a qualification rides as a sub-bullet under the claim it qualifies so the top level stays skimmable. A bullet over about 1.5 lines splits or becomes prose; a single point is prose; a multi-step flow is a numbered list. Spacious and sectioned is the goal.

## The voice

**Plain.** Say the thing directly, in words the reader takes at face value. A plain declarative beats an aphoristic line, a coined metaphor ("the gate goes live-capable"), a rhetorical-question frame ("page context answers 'which one?'"), or a personified verb ("rides with each message"): each makes the reader decode instead of read, and reads as AI writing. Opinions land as dry asides ("to avoid footguns and confusion"). The load-bearing word means exactly what the reader will infer, or gets defined inline: "on a clean host" reads as a fresh machine, so when the real condition is a long-lived runner missing one cached file, say that.
- Yes: "Here are some of the failure points we see today and some predicted ones that we should cover from day 1."
- No: "A handful of failure points buy most of our reliability from day 1."

**Cold reader.** Anyone can follow, not just experts, and every term resolves inside the artifact at hand. The first time you name a file, function, column, or component, say what it is and why it matters in a clause: "the Collector (the service that ingests traces) drops the attribute." Skip the dead-obvious (what a function or an API is). This holds when the reader is Justin too: shorthand from an earlier conversation ("the trio wording") is undefined in a fresh reply.
- Yes: "both build layers that push images (`vm_warm` = warm base, `vm_snapshot` = data restored in), so the fix lands in both."
- No: "same pattern in `vm_warm.py` and `vm_snapshot.py`."

**Behavior first.** Anchor every change to what exists now, then the delta: "Today it only forwards the org ID. We will also forward the creator's user ID." Lead with what is different in outcome terms; add the mechanism only when the reader needs it or the change is inherently low-level. State design intent as actor + will + change ("We'll create two new tools the model can use to access attachments"), opening on the content itself. Holds in Slack and status updates as much as in PRs.
- Yes: "Counts all annotation text now. The old script read `created_at` not `applicable_when`, so the span looked like 3 days."
- No: "Switched the annotations span query from `created_at` to `applicable_when`."

**Actor as subject.** Code identifiers are sentence subjects with verbs, one idea per sentence, short declaratives over clause-stacking.
- Yes: "`processTrace` reads the user ID. It passes that to `createRun`."
- No: "The user ID is read and then passed along to the run creation logic after validating it isn't null."

**Confidence and its assumption.** When not certain, say the confidence level and the assumption it rests on, so the reader can correct the assumption and has something concrete to check. State weaknesses and limits plainly, bold when load-bearing ("**Key Limitation: existing trace records are not backfilled.**"). A feel claim carries a personal-experience marker ("read as mostly empty to me"). All three invite correction; politeness hedging hides it.
- Yes: "as long as I'm reading it right that a set `ctx.pr_number` means the model must use that number, then I'm quite confident this fixes it."
- No: "this fixes it." / "this might possibly help in some cases."

**One reason, concrete.** Justify a choice in one sentence naming the capability or cost it buys; token cost, time to v1, and feedback velocity weigh as much as elegance. A second supporting reason or worst-case arithmetic dilutes the one that matters. Point every claim at the artifact this reader can resolve: file:line for a reviewer, the number for a report reader.
- Yes: "We're raising the cap from 3 to 4 so the model can list attachments, fetch twice, and still fetch a skill file in one turn."
- No: a paragraph deriving the same number from worst-case chains and per-round costs.

## Punctuation and emphasis

- **Bold** marks the one load-bearing claim or decision per paragraph, as a fluent phrase ("**The system prompt tells the model how many attachments the record has.**") rather than a coined one-word label ("**Announce:**").
- *Italics* mark the single pivot or limiting word: "the *only* place".
- A parenthetical, colon, comma, or fresh sentence carries an aside; an em-dash only when nothing else does.
- `→` for chains, `/` to join two ideas into one concept-name ("read/list"), parentheticals to scope precisely ("(nullable)", file:line), backticks on every identifier and UI string.
- Logic as inline operators: "`labels.user_id ?? run.user_id`", not a paraphrase.
- Sentences short to medium; a long one is a linear "if X, then Y", not nested clauses. Opening with "So" / "But" / "Today" is fine.

## Explaining engineering work

When explaining a review, a PR, a fix, or a design, lead with behavior and ground every claim in code:

1. The current issue as a wrong behavior, then the specific code or test artifact that produces it.
2. The new behavior and how the change produces it, the concept or architecture it uses, and the code that proves it.
3. Tradeoffs and alternatives, and why this one.

Include each part only when the information exists; a change too simple to have an underlying concept skips that part. A claim with no code is unverifiable; a code reference with no behavior is noise. A confusing choice gets reframed with the mental model that unlocked it ("the Scorecard / GitHub / Endpoint choice is really about *who owns the input→output step*"), then the options listed in that frame.

**A posted claim about a moving world is re-checked right before posting and amended in place afterwards.** PR heads, CI state, and sibling PRs move while you write: "needs #760 merged first" reads badly two hours after #760 merged. An artifact later found stale gets amended where it was posted, not walked back in chat.

Two shapes for explaining a change, both in `resources/change-walkthroughs.md`: the walkthrough by default, the signature profile when the reader asks for scope, shape, or "what changed where".

## Registers

Same voice, different density; read the matching resource before drafting. Everywhere, open straight on the problem: "Trace records show 'Created By' as **'Anonymous'** instead of the user who created them", not "In order to address this issue, we will...". (A "Hey," in chat is saying hello, not preamble.)

| Artifact | Density | Read first |
|----------|---------|------------|
| **Tech plan / design doc / RFC** | Formal, spacious. Numbered sections, fixed schemas, tradeoff tables, named alternatives. | `resources/tech-plans.md` |
| **PR description** | Plain English, behavior first. Lead with what's happening + the conceptual fix; push mechanism into the code. Dense prose fine, jargon dumps aren't. | `resources/pr-descriptions.md` |
| **Change walkthrough / scope summary** | Runtime order, bold behavioral claim + contract per step; or the `+`/`~`/`-` signature profile. | `resources/change-walkthroughs.md` |
| **Design critique / UX walkthrough** | First-person, experiential. Actor flips from code to *you*. Fixed schema, captioned screenshots, priority up front. | `resources/design-critiques.md` |
| **Report / standalone doc** | Numbers and findings first, a few sentences each. Stands alone; no session narrative. | `resources/reports.md` |
| **Visual artifact (diagram / HTML report / deck)** | Visual encoding first, words last resort. Self-explanatory to a zero-context reader. | `resources/visual-artifacts.md` |
| **Slack / peer message** (chat ping, DM, thread) | Casual, conversational, flows like speech. Light greeting OK. Link the one artifact; name only the central identifiers; confidence and its assumption. | `resources/slack.md` |
| **Code comment / inline review** | Most compressed. One claim per line, point at the artifact, drop scaffolding. Behavior first when describing a change. | (this row is the guidance) |
