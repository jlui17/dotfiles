---
name: context-audit
description: Use whenever standing context is created, changed, questioned, or audited. Fires when Justin says to remember something or corrects the same thing twice; when a lesson from the current task looks worth keeping; when deciding whether and where something should persist; before writing, editing, or reviewing a rules.d fragment, a global or repo skill, a slash command, an output style, or a CLAUDE.md in any repo; when existing context looks stale, wrong, or duplicated; and on any ask to audit the rules, consolidate context, or find overlapping instructions or twins.
---

# Maintaining standing context

## Which layer a piece of context belongs to

Standing context has two homes, routed by scope. Useful to every session regardless of project → global (a rules.d fragment or global skill). Useful to every session in one project → that repo's CLAUDE.md, skills, or docs. Useful only to this task or session → nowhere: point-in-time facts, session-scoped rules, and workarounds never persist.

Personal facts go to auto-memory, standing rules go to rules.d. Auto-memory covers what one machine's sessions learn; a rule every session must follow still lands as a fragment.

Within a layer, split by what the text does. A trigger or gate belongs to the always-on layer, because a skill loads too late to gate its own loading. Detail, procedure, and reference material belong to the skill, which pays its cost only when it fires.

Judgment goes to context, determinism goes to code. Decisions, tradeoffs, and taste are prose; a fixed procedure (runbook, check, recovery sequence) gets codified as a script, hook, or skill script, with the prose keeping only the pointer and the why.

## One home per instruction

Every rule, threshold, or workflow step legislates in exactly one place; everything else points. Classify every overlap:

1. **Undeclared duplicate**: same instruction, two homes, neither marked as the copy. Worst when the wordings disagree on substance (different threshold, exception, or default); name the disagreement exactly.
2. **Declared copy**: one copy names the other canonical. Fine while in sync; flag only drift.
3. **Pointer**: one home plus a cross-reference. Correct; still verify the reference resolves (section renames strand pointers).

Picking the canonical home between two copies: the one that fires when it's needed wins. Two placements follow from that. A skill never restates an always-on rule (the always-on layer is guaranteed loaded, so a restatement only creates a drift twin); it cites it. CLAUDE.md and the output style reach different audiences (subagents get only the former), so route by audience and keep the text in one of them.

An addition is an edit. A new lesson lands in its topic's existing home, so grep both layers for prior coverage before writing; a new fragment or skill is for a new topic, not a new lesson. After any context edit, run the scoped sweep (`resources/sweeps.md`) so the edit doesn't ship a twin.

## Maintain in both directions

Stale or wrong context gets removed with the same energy new lessons get added. Confident in the edit, or it was already discussed → apply and commit it yourself end to end (repo edits get their own commit, never folded into the task's commits), reporting what changed. Unsure → propose and wait. A repeated correction is the deadline, not the trigger: save the lesson the first time when it clearly generalizes.

The writing bar for both layers, what earns a line in a CLAUDE.md and what earns a skill, is the next two sections; read them before writing either layer.

## Writing a skill

Distilled from Anthropic's skill-creator (https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md), keeping only what applies here. Holds for global and repo skills alike.

- **The description is the trigger, and the only part always in context.** Write it as a pure use-when: third person, naming the concrete situations and phrasings that should fire it. Keep it to about 100 words. Err pushy, since models undertrigger; the body, never the description, carries the how.
- **Progressive disclosure.** The body loads only on trigger: keep it well under 500 lines, and move reference-grade material into `resources/` files the body points at (the style skill is the example). A script the skill keeps rewriting inline belongs in a bundled `scripts/` dir instead.
- **Explain why, not just what.** A principle plus its reason beats a rigid prescription; the model generalizes from the why. Keep the skill general: when feedback prompts an edit, encode the generalized lesson, not the one triggering example.
- **Only the non-derivable.** A skill carries workflow, gotchas, and contracts the model can't deduce from the repo or from generic best practice; everything else is context spent twice.
- **Test against a baseline.** For a skill worth validating, run the trigger prompt with and without the skill in parallel subagents and compare; cut instructions that don't change the output.

## Writing a CLAUDE.md (and rules.d fragments)

From the Claude 5 context-engineering guidance (https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models). rules.d fragments assemble into `~/CLAUDE.md`, so this applies to them and to any per-repo CLAUDE.md.

- **Lightweight: gotchas over description.** Briefly say what the repo is for, then spend the tokens on non-obvious insights: unique architectural decisions, invariants, traps. Never spend them on what the model can deduce by reading the tree or the code.
- **Judgment over constraint.** State the principle and trust the model's reasoning ("write code that reads like the surrounding code") instead of enumerating rigid per-case rules.
- **Progressive disclosure.** Specialized guidance goes in a skill; CLAUDE.md carries the pointer and the trigger, not the content (the output style → style skill split is the example).
- **Consolidate as you grow.** A fragment that outgrows a few paragraphs gets distilled, detail pushed into a skill; additions compete for the generated `~/CLAUDE.md`'s line budget (install.sh owns the number and warns past it).

## Where the global layer lives

The global layer (`~/CLAUDE.md`, global skills, slash commands, the output style) is deployed from the dotfiles repo, and the dotfiles skill carries the mechanics. It is installed globally, so it is available in every session: load it before changing any of that. Two facts hold before it loads: never edit `~/CLAUDE.md` directly, since it is generated and the next install overwrites it; and machine-only rules go in the gitignored `99-local.md`.

## Sweeping for twins

The scoped sweep after an edit, and the full corpus audit on request, are in `resources/sweeps.md`.
