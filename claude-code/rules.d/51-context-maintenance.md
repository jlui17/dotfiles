## Maintaining standing context

Standing context has two homes, routed by scope. Useful to every session regardless of project → global (a rules.d fragment or global skill; mechanics in "Editing these rules"). Useful to every session in one project → that repo's CLAUDE.md, skills, or docs. Personal or machine-local facts → auto-memory, not a fragment. Useful only to this task or session → nowhere: point-in-time facts, session-scoped rules, and workarounds never persist. The writing bar for both layers lives in the claude-code skill.

Judgment goes to context, determinism goes to code. Decisions, tradeoffs, and taste are prose; a fixed procedure (runbook, check, recovery sequence) gets codified as a script, hook, or skill script, with the prose keeping only the pointer and the why.

Maintain both layers while working, in both directions: stale or wrong context gets removed with the same energy new lessons get added. Confident in the edit, or it was already discussed → apply and commit it yourself end to end (global edits: the fragment, `./install.sh`, a dotfiles commit; repo edits: their own commit, never folded into the task's commits), reporting what changed. Unsure → propose and wait. A repeated correction is the deadline, not the trigger: save the lesson the first time when it clearly generalizes.
