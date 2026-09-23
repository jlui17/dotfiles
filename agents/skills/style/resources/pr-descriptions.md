# PR descriptions

A PR body answers the questions a reviewer must settle before approving, and nothing the diff already answers. Every line passes one test: **would the reviewer get the change wrong, or not trust it, without this line, and can't they see it in the diff?** Only a yes to both earns the line.

## What the reviewer asks

| Question | Section | When |
|----------|---------|------|
| What was wrong or missing? | Description | Always. 1-2 sentences of user-visible behavior. |
| What's different now? | Description | Always. 1-2 sentences: the new behavior, then the idea that produces it. |
| Why this approach? | Description | Only when a reviewer could reasonably disagree: the decision and one reason, a rejected alternative in a line. |
| What does it look like? | Screenshots | Every UI change. |
| How do I know it works and won't break prod? | Test plan | Always. |
| What must I know to review, merge, or deploy? | Additional notes | Only when true: stack position, why it's safe to merge, deploy order, the load-bearing limit, a named follow-up. One line each. |

Everything else is the diff's job: per-file walkthroughs, helper and flag names, exact values, call order, full test inventories, and how the session got here. Write as if the working session never happened; every claim stands on what this PR shows.

## Shape and size

When the repo has `.github/pull_request_template.md`, its sections are the skeleton, even for a two-line body; a section with nothing to say gets "N/A". Size to the reviewer's risk, not the diff's size: a one-line fix is one sentence and a one-line test plan. **Target 150-250 words of prose**, not counting media and the test plan's list. Draft, then keep only the 15% you'd keep if forced to cut; that is the body.

**A body that can't get down to the target means the PR is too big**: split it into a stack before writing more prose. The exception is a PR that's large on purpose, like a prototype whose implementation details the reviewer doesn't need; the body says so in one line and stays short while the diff is large.

## Description

Behavior first and cold reader, as in SKILL.md. A user-visible change gets a concrete example of what the user now sees. Link the source you were given: the eval run, doc, or PR that surfaced the bug.

## Screenshots and recordings

- Before and after for a fix, after for a feature. Each caption says what to look at.
- A recording when the behavior happens over time (streaming, loading, a multi-step flow); it sits first in Screenshots with one line on what it shows.
- Upload with `gh pr create|edit --attach '<path>#<alt>'` and reference each file in the body as `![alt](<path>)` with the *same path string*; gh swaps a matching reference for the uploaded asset and appends unmatched files at the end. A video renders as a player when its asset URL sits on its own line.

## Test plan

Answers "how can I be confident this works and doesn't break prod?", in first person: "I ran X. It showed Y."

- One entry per behavior the description claims, plus the riskiest thing nearby that could break.
- CI proof first, naming the test so a reviewer can open it. When CI can't prove it, one thorough manual run in 2-4 steps that says what was exercised; "all green" alone is a claim, not a proof.
- Remaining coverage in one closing line.

## Stacks

A stacked PR opens with "PR N of M, based on #X; retarget to `main` once #X merges", plus the tech plan link when one exists. The first PR carries the shared context; later PRs are a few lines on their own change and point back to it.

## After the first push

The body and title stay true for the life of the PR (the moving-world rule in SKILL.md):

- One or two "Update" sections with the head SHA are fine during review; past that, rewrite the body to the final state.
- A question a reviewer asked is a gap the next reviewer will hit: fold the answer into the body.
- Review replies are numbered dispositions mapped to the fix commit SHA; declining is fine with the reason stated.
- Post-merge verification lands as a PR comment with numbers.
