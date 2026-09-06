# Agents

Owns the context every harness shares: the global skills in `agents/skills/<name>/`, the external-skill manifest `agents/external-skills.txt`, and the shared rule fragments in `agents/rules.d/`. `setup_agents` links the skills into `~/.agents/skills` and `~/.claude/skills`, replays the external skills, then assembles `~/CLAUDE.md` and Codex's `AGENTS.md`. Context only Claude Code reads is not here; see `resources/claude-code.md`.

A skill has one home. Codex reads `~/.agents/skills` natively; Claude Code discovers only `~/.claude/skills`, so the same directory is linked into both. Neither harness gets its own copy, so an edit in the repo reaches both on the next run.

"Update my global skills" means: edit or add a directory under `agents/skills/`, run `./install.sh`, commit. Removing a skill is deleting its directory and re-running; `prune_stale_links` in `setup_agents` removes the dead links from both harness directories; it never touches a link that points outside the repo.

`SKIP_SKILLS` in `.dotfiles-local` hides a skill on one machine; the run prunes an already-linked skill once it is listed. An unknown name warns at the top of the run (`validate_skip_lists`) instead of failing silently.

The writing bar for a skill (what earns a skill, what earns a line in it, the trigger description) lives in the context-audit skill. Read it before writing or editing one; this file does not restate it.

## Global rules

"Update my global CLAUDE.md, AGENTS.md, or rules" means editing a fragment, never the deployed file. Two fragment directories feed two generated files:

- `agents/rules.d/` holds the shared fragments. They reach both `~/CLAUDE.md` and `${CODEX_HOME:-~/.codex}/AGENTS.md`.
- `claude-code/rules.d/` holds Claude-only fragments. They reach `~/CLAUDE.md` only. `62-worker-cost.md` is the example: it ranks Codex models for Claude to delegate to, which means nothing to Codex.

`assemble_global_rules` takes the destination and the fragment directories, merges their `NN-<slug>.md` files sorted by filename across directories, and writes the generated file with a header naming the source directories. The `NN-` prefix orders (so a shared `10-` fragment, a Claude-only `62-` fragment, and `99-local` interleave correctly); the slug is what `SKIP_RULES` names. Generated rather than symlinked because per-machine section exclusion needs a per-machine artifact; a symlink is all or nothing. Consequences:

- An edit reaches the generated files only on the next `./install.sh`.
- Both files are overwritten on every run (each file's header says so), so a direct edit is lost.
- `99-local.md` in `agents/rules.d/` is gitignored and machine-only; it reaches both files.
- `SKIP_RULES` in `.dotfiles-local` names slugs from either directory (`rule_section_slugs` reads both) and applies to both files. An unknown slug warns (`validate_skip_lists`).
- `assemble_global_rules` warns when a generated file passes its line budget; the number lives there. Past it, distill a fragment or push detail into a skill.

The shared rules are one fragment, `10-letter.md`: a letter in Justin's voice, with the writing bar in the context-audit skill. `62-worker-cost.md` stays its own fragment so a machine can skip it.

## External skills

Skills from other people's repos are declared in `agents/external-skills.txt` (format in its header) and installed by `setup_agents`, which replays `bunx skills add <repo> --skill <names> -g -y -a claude-code codex` per manifest line. They are not repo symlinks because the repo does not own the files: the skills CLI (vercel-labs/skills) keeps one universal copy as a real directory in `~/.agents/skills/<skill>` and links `~/.claude/skills/<skill>` to it. Re-running the add refreshes that copy from upstream, and the `update_pkgs` alias in zshrc also runs `bunx skills update -g`. `SKIP_SKILLS` filters external skills the same way it filters repo skills.

Because the CLI's copy is a real directory, the prune never touches it, and removal is manual: delete the manifest line, then run

```
bunx skills remove <skill> -g
```

Do not give a repo skill the same name as an external one; `backup_and_link` would move the CLI's directory aside as a `.bak`.

bunx comes from bun, which `setup_mise` seeds into the machine-local mise config on a fresh machine only. A machine set up before bun joined the seed has no bunx; install.sh warns, skips the external skills, and the note names the fix.
