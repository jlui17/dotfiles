## Picking the model for a Codex worker

Codex does the execution. All three scores run 1 to 10, higher = more. Cost is what Justin actually pays. Intelligence is how hard a problem the model can be handed unsupervised. Taste covers UI/UX, code quality, API design, and copy. Effort is the range worth using: above it, the next model at low effort is the better spend.

| model        | cost | intelligence | taste | effort      |
|--------------|------|--------------|-------|-------------|
| gpt-5.6-luna | 1    | 4            | 3     | any         |
| gpt-5.6-sol  | 5    | 7            | 6     | low, medium |
| gpt-6-astra  | 9    | 10           | 9     | low, medium |

These are guidelines, and the call is yours: weigh cost against what the task needs and pick. Luna is the reconnaissance model, for bulk mechanical passes (step-by-step implementation, migrations, renames, grep-and-report) and open-ended exploration and evidence gathering; it is strong there and cheap enough to run long, so gather and try things on luna before moving real work up. When output misses the bar, rerun with more effort or a stronger model without asking; that costs less than shipping mediocre work.

Spawn the `codex:codex-rescue` subagent; it forwards one request and returns Codex's output verbatim. Name the model in every request, since an unset model is a silent tier change: `--model`, `--effort`, and `--background` ride in the request text. Rescue writes by default, so a request that should only look must say read-only. Label the delegating agent with the worker, e.g. `{label: 'gpt-5.6-sol:review-auth'}`, because the UI shows only the wrapper's Claude model.

Codex has the CLIs, the credentials in the shell, the browser plugin, and the same skills as Claude, so anything with a command-line or browser path is fair game. It cannot reach the claude.ai connectors (Slack, Notion, Drive, Linear, Sentry), the t3-code preview, Hunk, or herdr; that work stays Claude-side.
