# Agents

Owns the global skills in `agents/skills/<name>/`, linked by `setup_agents` into `~/.agents/skills` and `~/.claude/skills`.

A skill has one home. Codex reads `~/.agents/skills` natively; Claude Code discovers only `~/.claude/skills`, so the same directory is linked into both. Neither harness gets its own copy, so an edit in the repo reaches both on the next run.

"Update my global skills" means: edit or add a directory under `agents/skills/`, run `./install.sh`, commit. Removing a skill is deleting its directory and re-running; `prune_stale_links` in `setup_agents` removes the dead links from both harness directories; it never touches a link that points outside the repo.

`SKIP_SKILLS` in `.dotfiles-local` hides a skill on one machine; the run prunes an already-linked skill once it is listed. An unknown name warns at the top of the run (`validate_skip_lists`) instead of failing silently.

The writing bar for a skill (what earns a skill, what earns a line in it, the trigger description) lives in the context-audit skill. Read it before writing or editing one; this file does not restate it.

## External skills

Skills from other people's repos are declared in `claude-code/external-skills.txt` (format in its header) and installed by `setup_claude_code_skills`, which replays `bunx skills add <repo> --skill <names> -g -y -a claude-code codex` per manifest line. They are not repo symlinks because the repo does not own the files: the skills CLI (vercel-labs/skills) keeps one universal copy as a real directory in `~/.agents/skills/<skill>` and links `~/.claude/skills/<skill>` to it. Re-running the add refreshes that copy from upstream, and the `update_pkgs` alias in zshrc also runs `bunx skills update -g`. `SKIP_SKILLS` filters external skills the same way it filters repo skills.

Because the CLI's copy is a real directory, the prune never touches it, and removal is manual: delete the manifest line, then run

```
bunx skills remove <skill> -g
```

Do not give a repo skill the same name as an external one; `backup_and_link` would move the CLI's directory aside as a `.bak`.

bunx comes from bun, which `setup_mise` seeds into the machine-local mise config on a fresh machine only. A machine set up before bun joined the seed has no bunx; install.sh warns, skips the external skills, and the note names the fix.
