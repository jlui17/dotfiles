## Code comments

Do not write code comments unless documenting an assumption the code is making. When a comment is warranted, it states *why*, not *how*: code already shows how, and the two drift. Why-shaped is not a pass: the why itself must clear the bar below, and rationale a reader would infer anyway (a generic benefit, restated design intent) is not documentation. Prefer a precise name over a comment: if a comment explains what code does, rename and delete it. Put each comment at the code it constrains, state it once, and keep it self-contained, with no references (tickets, docs, "Trap #N") a future reader can't resolve.

No comment unless it carries information that can't be derived or inferred from ANY part of the codebase or context (other files, tests, types, language semantics, conventions all count as derivable); default to encoding a relationship in code and pinning it with a test, and comment only what neither can hold. A comment that fails this bar is deleted, not shortened (keep only the clause that passes), and cross-file authority gets a bare pointer (`-- enum defined in status.go`), nothing more.

Named failure modes, each an instant delete:

- **Convention docs.** API doc comments (godoc, docstrings, JSDoc) get no exemption: a header that paraphrases the name or signature is deleted even on an exported identifier the ecosystem expects documented. Document an export only when it carries a contract the signature can't show, and say only that contract.
- **Inferable why.** Purpose or benefit prose the reader would guess ("shared so the two sides can't drift", "stdlib-only so it stays dependency-free").
- **Point-in-time talk.** Comments are timeless. Anything true only at this moment of the project (what exists yet, "for now", "for the MVP", "until X lands", open questions) and any provenance ("the design doc's CREATE TABLE says") belongs in the PR description, never in code.
- **Restating an adjacent artifact.** A comment whose content a neighboring constraint, test, type, error message, or sibling's convention already carries.

A magic number, tunable constant, threshold, or other chosen value that embodies a real tradeoff or measurement MUST carry a comment: what it trades off, what would make it wrong, measured or guessed. Do not manufacture rationale to satisfy this: when the honest answer is "arbitrary, any similar value works" or adjacent code already carries the meaning, a fabricated justification is itself a bad comment; write nothing.
