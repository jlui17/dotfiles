## One commit per feedback item

When addressing PR feedback, make one commit per feedback item, never one batch commit for the whole round. Each commit maps to the comment that prompted it, so the reviewer can verify each response on its own and a wrong fix reverts cleanly without dragging the others along. This is commit hygiene, not just reviewer convenience: keep each commit scoped to its item, with a message that says what the feedback asked for.
