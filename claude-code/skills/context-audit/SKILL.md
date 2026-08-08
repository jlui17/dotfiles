---
name: context-audit
description: Use after editing any standing-context artifact (a rules.d fragment, a global skill, a slash command, a repo CLAUDE.md or repo skill) to sweep for twins of the edit before committing, and for the full overlap audit of the context corpus when asked ("audit the rules", "context audit"). Finds the same instruction stated in more than one home, classifies each copy, and consolidates to one canonical home.
---

# Context audit

The bar is the claude-code skill's "one home per instruction": every rule, threshold, or workflow step legislates in exactly one place; everything else points. Classify every overlap:

1. **Undeclared duplicate**: same instruction, two homes, neither marked as the copy. Worst when the wordings disagree on substance (different threshold, exception, or default); name the disagreement exactly.
2. **Declared copy**: one copy names the other canonical. Fine while in sync; flag only drift.
3. **Pointer**: one home plus a cross-reference. Correct; still verify the reference resolves (section renames strand pointers).

Picking the canonical home: the copy that fires when it's needed wins. A trigger or gate belongs to the always-on layer (a skill loads too late to gate its own loading); detail and procedure belong to the skill.

## Scoped sweep (after every context edit)

Before committing a context edit, hunt for twins of what you just wrote:

1. Grep the corpus for the edit's signature phrases and the topic's key terms; the concept, not just the exact wording.
2. Classify each hit per the bar. An existing home for the topic means the edit moves there (the addition-is-an-edit rule in `~/CLAUDE.md`); an overlapping statement gets pointerized or named canonical.
3. Fix in the same round; a context edit that ships a new twin is incomplete.

Corpus for global edits (dotfiles repo): `claude-code/rules.d/*.md`, `claude-code/skills/**/*.md`, `claude-code/commands/*.md`, `.claude/skills/claude-code/SKILL.md`. For a repo-layer edit: that repo's CLAUDE.md, its `.claude`/`.agents` skills, and its docs.

## Full audit (on request)

1. Spawn two independent subagent auditors, each reading every corpus file, building its own topic index (which file:line legislates on each topic), and reporting overlaps with verbatim quotes, classification, substance disagreements, and a recommended home. Don't share one auditor's findings with the other.
2. Verify every quoted line at its cited location before reporting or fixing; auditors misread.
3. Report findings ranked, disagreeing copies first, one disposition per finding; apply per the context-maintenance confidence rule in `~/CLAUDE.md`.
4. One commit per finding, so a wrong consolidation reverts cleanly.
