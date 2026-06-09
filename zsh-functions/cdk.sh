#!/bin/zsh

# ──────────────────────────────────────────────────────────────
# cdk / aws — 1Password CLI plugin wrappers
# ──────────────────────────────────────────────────────────────
# Replaces the aliases from plugins.sh (`alias aws="op plugin run -- aws"`)
# with Zsh functions defined canonically in dotfiles.
#
# WHY FUNCTIONS INSTEAD OF ALIASES
#   Functions support autocomplete, flags, and composition. They're
#   also the canonical config — this file is the source of truth,
#   not the auto-generated plugins.sh.
#
# WHY PNPM SCRIPTS STILL WON'T USE THESE
#   pnpm spawns a non-interactive shell for script execution. Shell
#   functions (and aliases) don't carry over. pnpm also prepends
#   node_modules/.bin to PATH, so any `cdk` script from aws-cdk
#   npm package takes priority.
#
#   To make `pnpm cdk deploy ...` go through 1Password, either:
#
#   A) Wrap inline in package.json (recommended — explicit):
#        "cdk": "op plugin run -- cdk"
#        Now `pnpm cdk deploy --all` flows through 1Password.
#
#   B) Wrapper script on PATH (use if the package.json is shared):
#        Create ~/.local/bin/cdk:
#          #!/bin/bash
#          exec op plugin run -- cdk "$@"
#        WARNING: pnpm still prefers node_modules/.bin/cdk over this.
#        Only works if cdk isn't a project dependency.
#
#   C) Use the full command in pnpm scripts:
#        pnpm exec op plugin run -- cdk deploy --all
# ──────────────────────────────────────────────────────────────

# Remove the auto-generated aliases from plugins.sh so our functions
# take precedence in interactive shells.
unalias cdk 2>/dev/null
unalias aws 2>/dev/null

cdk() {
  # Runs the AWS CDK CLI through 1Password's shell plugin.
  # Injects AWS credentials from your 1Password vault on every invocation.
  op plugin run -- cdk "$@"
}

aws() {
  # Runs the AWS CLI through 1Password's shell plugin.
  op plugin run -- aws "$@"
}
