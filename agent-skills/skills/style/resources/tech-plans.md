# Tech plans / design docs / RFCs

Voice (main doc) holds. This is the structure layer: more formal and spacious than a PR (numbered sections, fixed schemas, tradeoff tables, named alternatives, room to explain).

## Final design only; history lives in the PR

A design doc states the current design with its rationale: "just say 'here's the design'" (a correction repeated three escalating times on one draft). Decision archaeology (dates, attributions, "we used to think X", whole rejected-alternative paragraphs) moves to PR/VCS history, replaced by one pointer line: "Rejected alternatives and their reasoning live in the PR history." Rationale for the *chosen* design stays inline; only comparative history moves. This is a lifecycle with the Alternatives mini-schema below, not a contradiction: while a decision point is live, keep the mini-schema; once the doc is the settled record, compress to the pointer.

## Glossary at the top when terms are ambiguous

When a term means different things in team discussion ("colony", "snapshot"), open with a glossary: one line per term, pointing at the section that uses it, plus the meta-rule that a plan needing a different meaning changes the glossary, not its local definition. Jargon that doesn't self-decode gets renamed, even mid-design ("drain outbox" → "re-enqueue pending work").

## Sections open with one framing line

One unlabeled line saying what the section covers and why it's here, when not obvious. No scaffolding label: an explicit "**Purpose:**" prefix was tried and reversed.

## Mechanism then components

Explain the mechanism once narratively, then re-list by component: numbered flow for understanding, per-system "Key Changes" list for implementation. The redundancy is deliberate: narrative builds the model, list makes it actionable. Each step = actor + action + grounding: "X already does Y (`file:line`). Today it only does Z. We will also do W."

## Alternatives: fixed mini-schema

**Approach** / **Why rejected** (or **Why deferred**: keep the distinction; *deferred* = viable later, *rejected* = no). One or two sentences each, no sprawl into prose. This is the live-decision form; a settled doc compresses it per "Final design only" above.

## Tables for tradeoffs/metadata

One-word verdict column ("Neutral/Good", "Good") plus a Notes column: verdict skimmable, notes carry the reasoning.

## Short and complete: density, not omission

Shortness is won by density, not by dropping definitions: naming a field is not defining it, and an interface enumerates its values. Win the length back by cutting context the stated audience already has, and dedup two redundant sections by deleting one, not slimming both. A section not yet designed says so instead of faking completeness: "**Deliberately underdesigned: we need to think this through more**" is a valid section body.

## Test plans: flat declarative bullets

Each = subject + what it proves, proof in a parenthetical. State what's proven, not how it runs.
> `createRecord` persists an explicit `userId` override (proving override beats the run fallback).

## Open questions

Numbered Q1/Q2, one question per item, owner in bold, inline priority tag ("Q2 (low priority): ...") so blocking vs nice-to-resolve is visible. A settled question moves into its section and leaves the list; never annotate it "decided" in place.
