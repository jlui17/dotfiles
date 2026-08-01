# Tech plans / design docs / RFCs

Voice (main doc) holds. This is the structure layer: more formal and spacious than a PR (numbered sections, fixed schemas, tradeoff tables, named alternatives, room to explain).

## Final design only; history lives in the PR

A design doc states the current design with its rationale: "just say 'here's the design'" (a correction repeated three escalating times on one draft). Decision archaeology (dates, attributions, "we used to think X", whole rejected-alternative paragraphs) moves to PR/VCS history, replaced by one pointer line: "Rejected alternatives and their reasoning live in the PR history." Rationale for the *chosen* design stays inline; only comparative history moves. This is a lifecycle with the Alternatives mini-schema below, not a contradiction: while a decision point is live, keep the mini-schema; once the doc is the settled record, compress to the pointer.

A dated review-outcome section at the top ("Review meeting notes (2026-07-31)") is current state, not archaeology: it records the status changes and new requirements a review produced, each pointing at the section it affects.

## Define terms inline; a glossary must earn its place

Introduce each term in a few words at first use ("trace chat (the Chat tab on a record's detail page)"); in a doc of ordinary length that's all the definition it needs. A glossary opens the doc only when it's long *and* its terms are genuinely contested in team discussion ("colony", "snapshot"): one line per term, pointing at the section that uses it, plus the meta-rule that a plan needing a different meaning changes the glossary, not its local definition. Jargon that doesn't self-decode gets renamed, even mid-design ("drain outbox" → "re-enqueue pending work").

## Sections open with one framing line

One unlabeled line saying what the section covers and why it's here, when not obvious. No scaffolding label: an explicit "**Purpose:**" prefix was tried and reversed.

## Current behavior: only what the design leans on

Each current-behavior bullet earns its place by a design section depending on it. The test for a candidate bullet: if cutting it changes nothing about how the reader evaluates the design, cut it. That one test covers both failure modes — the obvious (a fact the reader derives themselves, like "fetched content stays in context") and the out-of-scope (accurate background no decision touches).

## Design: contract first, then flow, at behavior altitude

The Design section opens with the central contract — the API or tool definitions, verbatim in a code block — and its rationale as the first subsection; the flow follows as a subsection, numbered in the order a request runs. Then Key Changes re-lists by component: the redundancy is deliberate, narrative builds the model, the per-file list makes it actionable. In Key Changes, one bullet per file with its changes as sub-bullets.

Write flow steps at the altitude of architecture, behavior, and process: what the system, model, or user does. Include an implementation detail only when it *is* the design (an API interface, a parallelism/concurrency choice, data ownership); function names, encodings, and caching mechanics live in Key Changes or in code. Ground a step with a `file:line` when the claim is load-bearing, not per step.

## Decisions: chosen with its reasons, then "Alternatives considered:"

Each decision opens with the chosen option and its reason in one or two direct sentences (#20): "**Chosen: download the PDF in the browser and extract its text, mostly for simplicity.**" When "why not X" is really what explains the chosen design's boundary (why frontend, not backend), it belongs in this prose, framed as the chosen design's reason.

Then a literal **Alternatives considered:** label over the bullets, each **Approach** / **Why rejected** (or **Why deferred**: keep the distinction; *deferred* = viable later, *rejected* = no), one or two sentences each. Only live options qualify: an extension nobody proposed for now is future direction, not an alternative. This is the live-decision form; a settled doc compresses it per "Final design only" above.

## Tables for tradeoffs/metadata

One-word verdict column ("Neutral/Good", "Good") plus a Notes column: verdict skimmable, notes carry the reasoning.

## Short and complete: density, not omission

Shortness is won by density, not by dropping definitions: naming a field is not defining it, and an interface enumerates its values. Win the length back by cutting context the stated audience already has, and dedup two redundant sections by deleting one, not slimming both. A section not yet designed says so instead of faking completeness: "**Deliberately underdesigned: we need to think this through more**" is a valid section body.

## Inherited constants get provenance

When the design changes an inherited value (a cap, timeout, budget), find where it came from — the introducing PR, its code, its review threads — and state the finding in the doc, absence included: "The existing 3 has no recorded rationale; PR #654 introduced it as a loop backstop." Reviewers then weigh the new value fresh instead of deferring to a number that was never reasoned.

## Test plans: flat declarative bullets

Each = subject + what it proves, proof in a parenthetical. State what's proven, not how it runs.
> `createRecord` persists an explicit `userId` override (proving override beats the run fallback).

## Open questions

Numbered Q1/Q2, one question per item, inline priority tag ("Q2 (low priority): ...") so blocking vs nice-to-resolve is visible. Consensus questions addressed to the reviewers come first ("are we OK with the tool shape (§3)?"), detail questions after. Leave questions unowned so anyone reviewing can answer; name an owner only when asked to. A settled question moves into its section and leaves the list; never annotate it "decided" in place.
