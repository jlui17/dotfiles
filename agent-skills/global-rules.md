Do not write code comments unless documenting an assumption the code is making. When a comment is warranted, it states *why*, not *how* — code already shows how, and the two drift. Prefer a precise name over a comment: if a comment explains what code does, rename and delete it. Put each comment at the code it constrains, state it once, and keep it self-contained — no references (tickets, docs, "Trap #N") a future reader can't resolve.

Any magic number, tunable constant, threshold, or other chosen value MUST carry a comment explaining how it was chosen and the assumptions behind it: what it trades off, what would make it wrong, and whether it was measured or guessed. A bare value with no rationale is not allowed.

Review feedback is a documentation signal. When a review (human or agent) objects to a decision or assumption we made, and the objection only holds because the reviewer lacks context we already had, the gap is documentation, not the decision. The reasoning lived in our heads, not where the reader could reach it. Capture the *why* where the reader will hit it (at the code, in the PR, in the design doc), or make the docs that already cover it more discoverable.

When explaining a code change — a review, a PR walkthrough, a fix summary — lead with behavior and ground each claim in code. State the problem as a wrong behavior, then point to the specific code that produces it. State the new desired behavior, then show how the change produces it. Pair every behavioral claim with the code that backs it: a claim with no code is unverifiable, a code reference with no behavior is noise. Don't assume the reader knows the identifiers you cite — the first time you name a variable, path, function, or constant, say what it is in a clause, because a reader who can't decode the names can't follow the argument.

## Editing these rules

This file is your global `~/CLAUDE.md`, symlinked from `~/src/personal/dotfiles/agent-skills/global-rules.md`. When asked to remember a global rule or change your standing instructions, edit that file in place, then commit the change in the dotfiles repo.
