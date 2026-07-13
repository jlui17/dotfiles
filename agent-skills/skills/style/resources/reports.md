# Reports & ongoing docs

Standalone reports (data reports, findings docs) and living `docs/` pages. Voice holds; this register is numbers-first and ruthlessly lean. These are strong defaults, not a template: use judgement on what this reader and this report need.

## Numbers and findings first; prose is a few sentences per section

A quantitative report exists so the reader can compare sizes. Lead each section with the numbers (table, ranked list), then a few sentences of interpretation ("the audience just wants to know relative sizes... the report can be like a few sentences each"; "trim all of this down hella"). If a section's prose outweighs its findings, invert it.

## Labels name the thing as the reader knows it

Reader-facing names, not pipeline names: "Google Docs (docx)", not "docx"; "Slack (Mattermost) messages", not "mattermost posts". A label or method detail that only makes sense to whoever ran the extraction is a bug (which XML tag the extractor parsed changes nothing for the reader). Keep the method detail the reader can act on: what was counted, what was excluded.

## Evidence lives in the doc, not behind a pointer

Show how the method isolates the thing being measured (the query, the filter, the before/after pair) right where the claim is made, not a brief harness description plus a README pointer. A link is fine as *depth*, never as the proof itself.

## The final artifact is standalone

No session narrative, no meta-progress, no diary of how the draft evolved ("what the audit cut"). A clarification the reader needs gets woven into the sentence it clarifies, not appended as a "Note:" block.

> Weak: "Slack: 1.2M messages. Note: this includes bot messages, which we decided to keep after discussion."
> Strong: "Slack (Mattermost): 1.2M messages, bot messages included (they carry deploy and CI context the model sees)."

## Ongoing `docs/` pages: record the why, briefly

A living doc notes why the current approach was chosen and what was rejected, in a sentence or two, so the next reader doesn't re-walk the dead end. One clause per rejected path ("polling rejected: webhook latency was already under 2s"), not a design history. Design/scoping docs are stricter: comparative post-mortems and decision history move to the PR with a pointer (see `tech-plans.md`); the one-clause why-chosen stays in both.
