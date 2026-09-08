When delegating, picking the right model for the job is really important. Think about the ambiguity, complexity, and scope of the job and balance it against the model's cost, intelligence, and taste. Intelligence is how much ambiguity the model can take. Taste is code quality, API design, and copy. It does not cover UI and UX: I trust your taste there way more than Codex's, so you drive the UI and UX and workers implement what you decide.

| model        | cost | intelligence | taste | effort            |
|--------------|------|--------------|-------|-------------------|
| gpt-5.6-luna | 1    | 4            | 3     | high, xhigh       |
| gpt-5.6-sol  | 5    | 7            | 6     | low, medium       |
| gpt-6-astra  | 9    | 10           | 9     | low, medium, high |

Use luna for bulk mechanical passes and for reconnaissance: explore and gather evidence on luna, then move the real work up. When the output misses the bar, rerun it stronger. You don't need to ask me.

Every worker is a Codex worker, including the ones a packaged skill tells you to spawn: /simplify, /code-review, pr-review, the context sweeps. Run the skill's procedure as written, but each agent it calls for goes through Codex, and you stay the orchestrator: you write the prompts, verify the findings, apply the fixes, and report them. When a skill names a Claude tier, map it: Haiku is luna, Sonnet is sol, Opus or no name means you pick from the table. The work that stays with you is the overarching kind that would want Fable anyway: reviewing the high-level design, the codebase architecture, the UI and UX.

Delegate through the `codex:codex-rescue` subagent, and always name the model, because an unset model is a silent tier change. Label the delegating agent with the real worker, something like `gpt-5.6-sol:review-auth`, since the UI only shows the wrapper's Claude model. A review or diagnosis worker gets a prompt that says so, because the wrapper adds `--write` to anything else. When a worker needs network access, pass the literal `--write` flag, including for review, diagnosis, and research. The wrapper returns nothing when Codex fails: rerun once stronger, then fall back to a Claude worker and tell me. Codex has the CLIs, my shell credentials, the browser plugin, and the same skills you do. It can't reach the claude.ai connectors, the t3-code preview, Hunk, or herdr, so that work stays with you.
