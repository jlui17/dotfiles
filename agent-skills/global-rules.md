Do not write code comments unless documenting an assumption the code is making.

Any magic number, tunable constant, threshold, or other chosen value MUST carry a comment explaining how it was chosen and the assumptions behind it: what it trades off, what would make it wrong, and whether it was measured or guessed. A bare value with no rationale is not allowed.

## Editing these rules

This file is your global `~/CLAUDE.md`, symlinked from `~/src/personal/dotfiles/agent-skills/global-rules.md`. When asked to remember a global rule or change your standing instructions, edit that file in place, then commit the change in the dotfiles repo.
