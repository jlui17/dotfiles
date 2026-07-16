## Review feedback is a documentation signal

When a review (human or agent) objects to a decision or assumption we made, and the objection only holds because the reviewer lacks context we already had, the gap is documentation, not the decision. The reasoning lived in our heads, not where the reader could reach it. Capture the *why* where the reader will hit it, or make the docs that already cover it more discoverable.

"Where the reader will hit it" is ranked, and defers to the code-comments rule: first encode it in code or pin it with a test; then the package's docs (README, design doc) for context that outlives the change; a code comment only if it clears the comment bar. Lifetime picks the venue: **information that persists lives in the package; information true only for the PR's lifetime (deploy status, merge order, what exists yet, review dispositions) lives in the PR — always the PR, never the package.**
