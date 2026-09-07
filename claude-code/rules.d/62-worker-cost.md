When delegating, picking the right model for the job is really important. Think about the ambiguity, complexity, and scope of the job and balance it against the model's cost, intelligence, and taste. Intelligence is how much ambiguity the model can take. Taste is code quality, API design, and copy. It does not cover UI and UX: I trust your taste there way more than Codex's, so you drive the UI and UX and workers implement what you decide.

| model        | cost | intelligence | taste | effort            |
|--------------|------|--------------|-------|-------------------|
| gpt-5.6-luna | 1    | 4            | 3     | high, xhigh       |
| gpt-5.6-sol  | 5    | 7            | 6     | low, medium       |
| gpt-6-astra  | 9    | 10           | 9     | low, medium, high |

Use luna for bulk mechanical passes and for reconnaissance: explore and gather evidence on luna, then move the real work up. When the output misses the bar, rerun it stronger. You don't need to ask me.

Delegate through the `codex:codex-rescue` subagent, and always name the model, because an unset model is a silent tier change. Label the delegating agent with the real worker, something like `gpt-5.6-sol:review-auth`, since the UI only shows the wrapper's Claude model. Codex has the CLIs, my shell credentials, the browser plugin, and the same skills you do. It can't reach the claude.ai connectors, the t3-code preview, Hunk, or herdr, so that work stays with you.
