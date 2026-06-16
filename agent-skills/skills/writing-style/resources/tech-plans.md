# Tech plans / design docs / RFCs

Voice (main doc) holds. This is the structure layer: more formal and spacious than a PR. Numbered sections, fixed schemas, tradeoff tables, named alternatives, room to explain.

## Mechanism then components

Explain the mechanism once narratively, then re-list by component. Numbered flow for understanding; per-system "Key Changes" list for implementation. Redundancy deliberate — narrative builds the model, list makes it actionable.

Each step = actor + action + grounding. "X already does Y (`file:line`). Today it only does Z. We will also do W."

## Alternatives — fixed mini-schema

**Approach** / **Why rejected** (or **Why deferred** — keep the distinction; *deferred* = viable later, *rejected* = no). One or two sentences each. No sprawl into prose.

## Tables for tradeoffs/metadata

One-word verdict column ("Neutral/Good", "Good"), Notes column for nuance. Verdict skimmable; notes carry the reasoning.

## Test plans — flat declarative bullets

Each = subject + what it proves, proof in a parenthetical. State what's proven, not how it runs.
> `createRecord` persists an explicit `userId` override (proving override beats the run fallback).

## Open questions

Numbered Q1/Q2 with inline priority tag: "Q2 (low priority): ...". Orients reader on blocking vs nice-to-resolve.
