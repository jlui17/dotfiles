## What a good explanation of a code change is

When walking through a change (a PR, a stacked pair, a subsystem), this is the shape:

- **Open with the one-sentence frame that makes the parts make sense**, the division of responsibility or mental model ("X ships a mechanism with no opinions; Y ships the policy"), before any detail. If pieces connect, say what the connective tissue is (imports, a shared golden, a base branch) in the same breath.
- **Narrate in runtime order, not diff order.** Follow one request or datum through the chain step by step; never file-by-file or commit-by-commit.
- **Each step: bold behavioral claim, then the contract.** One bolded sentence saying what the step means for the system, the method signature or type verbatim in a code block, then the process consequence (what fails where, what can't drift, what an operator sees).
- **Signatures and contracts, not implementation.** Include an impl detail only when it carries an architectural or process decision (no cache until a later task; refusal happens before an execution is spent).
- **Deliberate absences are design decisions: explain them like ones.** Say what the change intentionally does not do and why ("nothing decodes yet, by design, so the deploy is inert").
- **Name ownership boundaries** (which component owns which vars, names, rows) so the reader knows where the next change lands.
- **Compress the plumbing to one closing line** (Dockerfiles, CI filters, flag wiring): name it as serving the chain, never walk it.

When asked for a **summary of what changed** (scope/shape, not a walkthrough), answer with a signature profile instead: code blocks grouped by module, one line per declaration (the signature verbatim, marked `+`/`~`/`-` for added/changed/removed, `// was ...` inline on changes, a trailing comment only where the signature can't carry the meaning), closing with what's untouched and a line or two of prose on what fell out. Full shape: the `style` skill.
