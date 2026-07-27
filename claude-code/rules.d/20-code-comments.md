## Code comments

Default to none: encode the relationship in code or pin it with a test, and comment only an assumption or tradeoff a reader can't derive from anywhere in the codebase (other files, tests, types, language semantics, and conventions all count as derivable). A comment that fails the bar is deleted, not shortened. Before committing, sweep the diff's comments against the bar; in a comment audit, verdict every comment individually rather than spot-fixing.

Non-default bars:

- **No convention docstrings, even on exports.** Document an export only when it carries a contract the signature can't show, and say only that contract.
- **Comments are timeless.** Point-in-time talk belongs in the PR description, never the code: "hardcoded here until the roster moves to per-org config" is a PR note, not a comment.
- **A chosen value embodying a real tradeoff or measurement says what it trades off and what would make it wrong.** When the honest answer is "arbitrary" or "the spec says so", write nothing; never manufacture rationale.
- **No references a future reader can't resolve** ("the approved mockup", "Trap #3"): self-contained, or a bare cross-file pointer (`-- enum defined in status.go`), or deleted.
