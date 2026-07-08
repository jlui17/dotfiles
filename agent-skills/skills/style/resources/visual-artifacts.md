# Visual artifacts (diagrams, HTML reports/sims, slide decks)

Anything the reader looks at before they read: diagrams, HTML dashboards, simulations, decks. Voice holds where words appear, but here the medium carries the meaning. Strong defaults, not hard rules: judge what this artifact needs to communicate.

## Too much text is the first failure mode

A visual drowning in prose has failed before layout is judged. Justin, on a first draft: "not what i was thinking. there's too much text". Encode with position, size, color, and arrows; words are a last resort ("use the least amount of words possible unless something has to be described with words"). If a paragraph is explaining the picture, the picture isn't doing its job.

## Self-explanatory to a zero-context reader

"imagine the audience has no idea what this proposal or visualization is about... the visualization should be self-explanitory". The artifact itself carries the minimal context: what's shown, what's being compared, why it matters. If it needs you standing next to it, it's incomplete.

## Layout emphasis follows information priority

The most important content dominates visually: biggest, first, centered. When Justin listed priorities ("the most important visual things to display here are: 1. how data flows...") and the draft gave prime space to something else, the note was "i really don't feel like those two things are the most important visually". State (or ask for) the priority order, then check the layout mirrors it.

## Every label answers "what does this actually mean"

Precise, domain-standard names, with a definitional tooltip or caption where the name alone doesn't carry it: "'colony list' is just not good. i would say 'colony registry' and the tooltip should say 'a key-value store of where each colony keeps it's data'". A vague label makes the reader guess; a wrong-register one makes them guess wrong.

## No misleading simplifications

A diagram asserts everything it draws. If a claim is uncertain, delete it rather than soften it: "actually the bottleneck of step 4 is kind of unknown... remove the bottleneck for now". An absent element reads as unknown; a drawn one reads as fact.

## Differences must be visually obvious

When two states or designs are compared, the delta shows up in the pixels (color, position, an added element), not in a text annotation the reader must parse: "i don't think it's visually obvious how it's different". If you covered the caption, could you still spot the change?

## The terseness floor still applies

Lean labels, not telegraphic ones: full caveman fragments got rejected as "too dumb". Keep the article or verb that makes a label read naturally; cut only the words that add nothing.
