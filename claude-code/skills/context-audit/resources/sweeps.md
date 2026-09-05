# Sweeps

## Scoped sweep (after every context edit)

Before committing a context edit, hunt for twins of what you just wrote:

1. Grep the corpus for the edit's signature phrases and the topic's key terms; the concept, not just the exact wording.
2. Classify each hit against the one-home bar in `SKILL.md`. An existing home for the topic means the edit moves there; an overlapping statement gets pointerized or named canonical.
3. Fix in the same round; a context edit that ships a new twin is incomplete.

Corpus for global edits (dotfiles repo): `claude-code/rules.d/*.md`, `claude-code/output-styles/*.md`, `claude-code/skills/**/*.md`, `claude-code/commands/*.md`, `.claude/skills/claude-code/SKILL.md`. For a repo-layer edit: that repo's CLAUDE.md, its `.claude`/`.agents` skills, and its docs.

The harness's own tool descriptions are part of the always-on surface too. A rule restating what a tool's description already says is a twin, and grepping the dotfiles repo will never find it — check the description of any tool the rule is about.

## Full audit (on request)

1. Spawn two independent subagent auditors, each reading every corpus file, building its own topic index (which file:line legislates on each topic), and reporting overlaps with verbatim quotes, classification, substance disagreements, and a recommended home. Don't share one auditor's findings with the other.
2. Verify every quoted line at its cited location before reporting or fixing; auditors misread.
3. Report findings ranked, disagreeing copies first, one disposition per finding; apply per the confidence rule in `SKILL.md` ("Maintain in both directions").
4. One commit per finding, so a wrong consolidation reverts cleanly.
