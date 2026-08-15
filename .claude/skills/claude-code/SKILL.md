---
name: claude-code
description: Use when adding or editing a global skill, slash command, CLAUDE.md rule fragment, or the output style; when writing or reviewing any skill or CLAUDE.md (the writing guidance lives here); when adding or removing Claude Code plugins; when changing shared or per-machine settings.json; or when a plugin unexpectedly disappears after install.sh.
---

Deployed by install.sh `setup_claude_code` (the comment there describes the module split). The shared rules ship to Claude Code only: the old `~/AGENTS.md` assembly was dropped when the module went Claude Code-specific, so other harnesses (pi, opencode) have no default voice. If one later needs the rules, add a harness-native sink over the same `rules.d/` fragments rather than a parallel rules source; the deleted AGENTS.md assembly in git history is the template.

## Skills, commands, rules, output style

`rules.d/NN-<slug>.md` fragments (the `NN-` prefix orders them, the rest of the filename is the slug) are assembled into the generated `~/CLAUDE.md`, skipping slugs in this machine's `SKIP_RULES` (`.dotfiles-local`). Generated, not symlinked, because per-machine section exclusion needs a per-machine artifact; edits reach `~/CLAUDE.md` only on the next `./install.sh` run, and direct edits to the generated file get overwritten. `99-local.md` is gitignored for machine-only rules.

The fragments listed in `OUTPUT_STYLE_RULES` (install.sh) are additionally assembled into the output style `~/.claude/output-styles/justin.md`, selected via `outputStyle` in `claude-code/settings.json`. `~/CLAUDE.md` keeps its copy of the same fragments because subagents load CLAUDE.md but never see output styles.

Skills named in this machine's `SKIP_SKILLS` (`.dotfiles-local`) are not linked, and an already-linked skill added to the list gets its symlink pruned on the next run (prune_stale_links in install.sh — repo-pointing symlinks only, so copied-in external skills and hand-made files survive).

**External skills** (other people's repos, e.g. humanlayer/skills) are declared in `claude-code/external-skills.txt` (format in its header) and installed by replaying `bunx skills add <repo> --skill <names> -g -y -a claude-code` — the [skills CLI](https://github.com/vercel-labs/skills) copies them into `~/.claude/skills`, so re-running the add updates in place (`update_pkgs` in zshrc also runs `bunx skills update -g`). `SKIP_SKILLS` filters them like repo skills. Removal is manual: delete the manifest entry, then `bunx skills remove <skill> -g`. bun ships in the mise seed baseline so bunx exists on fresh machines; a machine without it gets a warn + note instead.

## Settings, statusline, plugins

**settings.json** is not symlinked, because Claude Code rewrites `~/.claude/settings.json` at runtime (theme, model, `/fast`). It stays a real machine-local file; install.sh deep-merges the repo's tracked keys into it, **repo winning on conflicts** (merge_json in install.sh), while machine-only keys the repo doesn't declare are preserved.

**settings.local.json** (gitignored) holds this machine's overrides; install.sh merges it *after* the repo file, so on this machine **local wins over repo** for the keys it declares, re-asserted every run instead of being clobbered by the shared settings.

**statusline-command.sh** is a plain symlink; unlike settings.json it is never rewritten at runtime.

**Plugins** can't be symlinked: their state in `~/.claude/plugins/` carries machine-specific absolute paths, timestamps, and pinned commit SHAs. install.sh instead replays `claude plugin marketplace add` + `claude plugin install` from `claude-code/plugins.txt` (format in its header); the CLI calls are idempotent. **The sync uninstalls plugins missing from the manifest**: a hand-installed plugin gets removed on the next run unless listed in `KEEP_PLUGINS` in `.dotfiles-local`, the home for machine-only plugins the shared manifest shouldn't know about.

## Writing a skill

Distilled from Anthropic's skill-creator (https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md), keeping only what applies here. Holds for runtime skills (`claude-code/skills/`), module maintenance skills (`.claude/skills/`), and pi skills alike.

- **The description is the trigger, and the only part always in context.** Write it as a pure use-when: third person, naming the concrete situations and phrasings that should fire it, ~100 words max. Err pushy, since models undertrigger; the body, never the description, carries the how.
- **Progressive disclosure.** The body loads only on trigger: keep it well under 500 lines, and move reference-grade material into `resources/` files the body points at (the style skill is the in-repo example). A script the skill keeps rewriting inline belongs in a bundled `scripts/` dir instead.
- **Explain why, not just what.** A principle plus its reason beats a rigid prescription; the model generalizes from the why. Keep the skill general: when feedback prompts an edit, encode the generalized lesson, not the one triggering example.
- **Only the non-derivable.** A skill carries workflow, gotchas, and contracts the model can't deduce from the repo or from generic best practice; everything else is context spent twice.
- **Test against a baseline.** For a skill worth validating, run the trigger prompt with and without the skill in parallel subagents and compare; cut instructions that don't change the output.

## Writing a CLAUDE.md (and rules.d fragments)

From the Claude 5 context-engineering guidance (https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models). rules.d fragments assemble into `~/CLAUDE.md`, so this applies to them and to any per-repo CLAUDE.md.

- **Lightweight: gotchas over description.** Briefly say what the repo is for, then spend the tokens on non-obvious insights (unique architectural decisions, invariants, traps); never on what the model can deduce by reading the tree or the code.
- **Judgment over constraint.** State the principle and trust the model's reasoning ("write code that reads like the surrounding code") instead of enumerating rigid per-case rules.
- **Progressive disclosure.** Specialized guidance goes in a skill; CLAUDE.md carries the pointer and the trigger, not the content (the style fragment → style skill split is the in-repo example).
- **One home per instruction.** Never repeat guidance across CLAUDE.md, the output style, and skills; place it where it's most relevant and point from elsewhere. A skill never restates an always-on rule (the always-on layer is guaranteed loaded, so a restatement only creates a drift twin); it cites it. Where a copy is deliberate (the output-style fragments duplicated into `~/CLAUDE.md` for subagents), name which copy is canonical.
- **Consolidate as you grow.** A fragment that outgrows a few paragraphs gets distilled, detail pushed into a skill; additions compete for the generated `~/CLAUDE.md`'s line budget (install.sh owns the number and warns past it). Routing and the addition-is-an-edit rule are canonical in `rules.d/51-context-maintenance.md`; the context-audit skill carries the overlap sweep.
- **Personal facts go to auto-memory, standing rules go to rules.d** (routing canonical in `rules.d/51-context-maintenance.md`). Auto-memory covers what one machine's sessions learn; a rule every session must follow still lands as a fragment.

## Tasks

- Any add/edit (command, skill, rule fragment, setting) lands by re-running `./install.sh`.
- Remove a capability: delete the file/dir, re-run `./install.sh` (the run prunes the stale symlink from `~/.claude`).
- Remove a plugin: delete its manifest line, re-run install.sh (the sync uninstalls it).
- Keep a plugin on this machine only: install it by hand, add it to `KEEP_PLUGINS`.

Note: this is the **repo maintenance** skill (lives in `.agents/skills/`); the skills inside `claude-code/skills/` are the **runtime** skills that get deployed.
