# Visual artifacts (diagrams, HTML reports/sims, slide decks)

Anything the reader looks at before they read. Voice holds where words appear, but here the medium carries the meaning. Strong defaults, not hard rules: judge what this artifact needs to communicate.

## Too much text is the first failure mode

A visual drowning in prose has failed before layout is judged ("not what i was thinking. there's too much text"). Encode with position, size, color, and arrows; words are a last resort, only for what can't be shown. If a paragraph is explaining the picture, the picture isn't doing its job.

When words are needed anyway (step-by-step narration, why something is slow, contracts, remaining caveats), put them behind a `<details>` block under the picture. The picture stands alone; a reader opens a collapsible only when they want more. Cut a collapsible whose content is about a component the picture no longer shows.

## A working diagram grammar

The grammar that survived a week of drawio iteration; start here instead of rediscovering it.

- **Box granularity follows the question being answered, not the process topology.** When the processes themselves are the question, every process gets its own box, even one running inside another service's group, connected not merged; containers group what shares a process or a managed boundary. When the reader only acts on one box in a longer chain, collapse the rest of that chain into it and name it for what the reader knows it as: a layer that's technically on the path but the reader doesn't act on is noise, even when accurate.
- **For a code path, swimlanes carry where code runs** (browser / backend / database); a box for each function or component sits inside the lane it runs in.
- **Edges are numbered in execution order.** Label with behavior + payload only when the payload matters; otherwise the number alone carries the sequence: "5. on requested: start the snapshot job (passes our tracking id), mark started".
- **Color carries the point, always with a small legend.** Ownership is one use (in-scope / ours-but-downstream / external-managed, dashed for out of our sight); a highlighted path is another (the slow repeated call in red, a cache hit in green, every database read in one color). Boundary lines encode system ownership, never document scope.
- **One headline number as a badge when a single count makes the point** (e.g. "postgres reads while user waits: 0").

The why: once the numbering exists, feedback arrives in that vocabulary ("X does step 5, then 6 happens from the DB"). The grammar is the shared language for discussing the design, not decoration.

## Every label answers "what does this actually mean"

Precise, domain-standard names, with a definitional tooltip or caption where the name alone doesn't carry it: "colony registry" with tooltip "a key-value store of where each colony keeps its data" beats "colony list".

## Converge on the team's shared picture

When a physical whiteboard or a teammate's sketch becomes the team's mental model, the diagram adopts its layout and its names. Two competing pictures of the same system split the discussion; converging on one keeps every comment landing on the same boxes.

## No misleading simplifications

A diagram asserts everything it draws. An uncertain claim is deleted, not softened ("the bottleneck of step 4 is kind of unknown" → remove the bottleneck): an absent element reads as unknown, a drawn one reads as fact.

Edge routing asserts too: a line passing through or near a box reads as a data flow into that box. Crossing or ambiguous lines are worth a bigger canvas.

## Differences must be visually obvious

When two states or designs are compared, the delta shows up in the pixels (color, position, an added element), not in a text annotation the reader must parse. If you covered the caption, could you still spot the change?

For two full states of the same system, use identical layout in both, behind a Before / After toggle, so the only thing that moves between views is the delta.

## Doc and diagram are one artifact

Final-design-only (see `tech-plans.md`) holds for diagrams too: no "(formerly X)" residue, no date stamps.

## One overview page beats per-section pages

Keep the overview; per-section tabs get killed. Pages get copy-pasted into the team doc, which makes labeled, self-contained pages a functional requirement, not polish. ASCII flow diagrams lose to drawio for the same reason: they don't paste.

## Verify the render before handing over

A layout that was never rendered is unverified. Screenshot with a headless browser (e.g. `chromium --headless=new --screenshot=...`), check both light and dark mode if the artifact supports them, and fix overlapping labels, invisible badges, and lines that cross boxes.

## The terseness floor still applies

Lean labels, not telegraphic ones: caveman fragments read as dumb. Keep the article or verb that makes a label read naturally; cut only the words that add nothing.
