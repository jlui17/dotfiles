# Visual artifacts (diagrams, HTML reports/sims, slide decks)

Anything the reader looks at before they read. Voice holds where words appear, but here the medium carries the meaning. Strong defaults, not hard rules: judge what this artifact needs to communicate.

## Too much text is the first failure mode

A visual drowning in prose has failed before layout is judged ("not what i was thinking. there's too much text"). Encode with position, size, color, and arrows; words are a last resort, only for what can't be shown. If a paragraph is explaining the picture, the picture isn't doing its job.

## Self-explanatory to a zero-context reader

"imagine the audience has no idea what this proposal or visualization is about": the artifact itself carries the minimal context (what's shown, what's being compared, why it matters). If it needs you standing next to it, it's incomplete.

## Layout emphasis follows information priority

The most important content dominates visually: biggest, first, centered. State (or ask for) the priority order, then check the layout mirrors it; a draft that gives prime space to a secondary item fails on that alone.

## A working diagram grammar

The grammar that survived a week of drawio iteration; start here instead of rediscovering it.

- **Every box is a standalone process**: a component running inside another service's group is still its own box, connected, not merged. Containers group what shares a process or a managed boundary.
- **Edges are numbered in execution order and labeled with behavior + payload**: "5. on requested: start the snapshot job (passes our tracking id), mark started".
- **Ownership is a small color legend** (in-scope / ours-but-downstream / external-managed); dashed means out of our sight. Boundary lines encode system ownership (internal to our system vs external), never document scope.

The why: once the numbering exists, feedback arrives in that vocabulary ("X does step 5, then 6 happens from the DB"). The grammar is the shared language for discussing the design, not decoration.

## Every label answers "what does this actually mean"

Precise, domain-standard names, with a definitional tooltip or caption where the name alone doesn't carry it: "colony registry" with tooltip "a key-value store of where each colony keeps its data" beats "colony list". A vague label makes the reader guess; a wrong-register one makes them guess wrong.

## Converge on the team's shared picture

When a physical whiteboard or a teammate's sketch becomes the team's mental model, the diagram adopts its layout and its names. Two competing pictures of the same system split the discussion; converging on one keeps every comment landing on the same boxes.

## No misleading simplifications

A diagram asserts everything it draws. An uncertain claim is deleted, not softened ("the bottleneck of step 4 is kind of unknown" → remove the bottleneck): an absent element reads as unknown, a drawn one reads as fact.

Edge routing asserts too: a line passing through or near a box reads as a data flow into that box. Crossing or ambiguous lines are worth a bigger canvas.

## Differences must be visually obvious

When two states or designs are compared, the delta shows up in the pixels (color, position, an added element), not in a text annotation the reader must parse. If you covered the caption, could you still spot the change?

## Doc and diagram are one artifact

Every scope or design change to a doc updates its companion diagram in the same round, or at least proposes the diagram edit; "did u update the diagram too?" should never need asking. Final-design-only (see `tech-plans.md`) holds for diagrams too: no "(formerly X)" residue, no date stamps.

## One overview page beats per-section pages

Keep the overview; per-section tabs get killed. Pages get copy-pasted into the team doc, which makes labeled, self-contained pages a functional requirement, not polish. ASCII flow diagrams lose to drawio for the same reason: they don't paste.

## The terseness floor still applies

Lean labels, not telegraphic ones: caveman fragments read as dumb. Keep the article or verb that makes a label read naturally; cut only the words that add nothing.
