## Picking the model for a Codex worker

Codex does the execution. One ladder, cheapest rung first; cost is what Justin actually pays, relative to luna.

| rung | model        | effort      | cost | use                                                                                                                                                                             |
|------|--------------|-------------|------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1    | gpt-5.6-luna | any         | 1x   | Bulk mechanical passes (step-by-step implementation, migrations, renames, grep-and-report) and open-ended exploration and evidence gathering. Strong there, and cheap enough to run long, so it is the reconnaissance before real work moves up. |
| 2    | gpt-5.6-sol  | low, medium | ?x   | The default for real work.                                                                                                                                                      |
| 3    | gpt-6-astra  | low → xhigh | ?x   | When sol at medium misses the bar. Astra low is the next rung after sol medium, and astra's effort climbs from there.                                                             |

Start at the lowest rung the task could plausibly clear and climb when the output misses the bar. Climbing costs less than shipping mediocre work, so it needs no permission. Taste (UI/UX, code quality, API design, copy) tracks the ladder, with astra at the top.

Spawn the `codex:codex-rescue` subagent; it forwards one request and returns Codex's output verbatim. Name the rung in every request, since an unset model is a silent tier change: `--model`, `--effort`, and `--background` ride in the request text. Rescue writes by default, so a request that should only look must say read-only. Label the delegating agent with the worker, e.g. `{label: 'gpt-5.6-sol:review-auth'}`, because the UI shows only the wrapper's Claude model.

Codex has the CLIs, the credentials in the shell, the browser plugin, and the same skills as Claude, so anything with a command-line or browser path is fair game. It cannot reach the claude.ai connectors (Slack, Notion, Drive, Linear, Sentry), the t3-code preview, Hunk, or herdr; that work stays Claude-side.
