# Terminal

Owns tmux (`tmux.conf` at repo root, installed by `setup_tmux`, plugin manager cloned by `setup_tpm`) and Ghostty (`ghostty/config` plus `ghostty/themes/`, installed by `setup_ghostty`).

## tmux

Reload after an edit, then test in a new session:

```
tmux source-file ~/.config/tmux/tmux.conf
```

Plugins are `set -g @plugin` lines above the TPM `run` line. tmux keeps its default split keys, and herdr mirrors them (`resources/herdr.md`), so rebinding a split in tmux.conf means changing herdr too. After adding one, reload and press prefix + I inside tmux to install it. Prefix + U updates all plugins, prefix + alt + u removes ones no longer listed (keys defined in `~/.tmux/plugins/tpm/scripts/variables.sh`). `setup_tpm` only clones TPM; the plugins themselves install from inside tmux, so a plugin that "isn't loading" on a fresh machine usually has not been installed yet.

The status line is the catppuccin plugin. The flavor knob is `@catppuccin_flavor` (latte, frappe, macchiato, mocha). The plugin is pinned to a tag in the `@plugin` line; bump the tag there to upgrade.

## Ghostty

Themes are files, not inline palettes. `ghostty/config` carries the font, keybinds, and `theme = <name>` only. Every color lives in `ghostty/themes/<name>`, an ordinary config fragment. Switching themes is a one-line edit; adding one is a new file. `setup_ghostty` links the whole `themes/` directory, so neither needs an install.sh change.

On macOS the config and the themes land in different directories. Ghostty reads its config from Application Support but scans only the XDG path (`~/.config/ghostty/themes`) for user themes, which is why `setup_ghostty` links two places. Linux uses the XDG path for both. The module's `MODULES` row is macos,arch and `ghostty` is in `UBUNTU_DROP_PACKAGES`.

A running Ghostty does not watch its config file. Apply an edit with the `reload_config` action (default keybind super+shift+, on macOS) or a restart. `ghostty +show-config --default --docs` lists every key with its docs.

On macOS the `ghostty` CLI is not on PATH in a non-interactive shell; call `/Applications/Ghostty.app/Contents/MacOS/ghostty`.

Verify a theme edit:

```
ghostty +list-themes --plain | grep user     # the repo's themes, tagged (user)
ghostty +show-config | grep -E '^(theme|background)'   # must echo the theme's own background
ghostty +validate-config                      # exit 0
```

## Colorblind-safe palettes

The rule lives in the global ~/CLAUDE.md; this section is the verification recipe for terminal palettes. Both shipped themes put orange in the red slot (1, 9) and blue in the green slot (2, 10), so opposed meanings sit on the blue-yellow axis. A palette edit that restores green to slot 2 or 10 defeats the point. The duplicate blue in `github-dark-colorblind` (slots 2 and 4, 10 and 12) is upstream's design, not a transcription error.

To verify a new or edited theme:

1. Convert every palette entry and the background to linear RGB and apply the Vienot dichromat matrices for deuteranopia and for protanopia.
2. For each simulation, compute CIE ΔE76 between every pair of text colors from different hue families (slots 1 to 7 and 9 to 15; slots 0 and 8 are chrome, never text). Every pair must clear 15. fleet exists because the GitHub palette misses it: its green and blue slots are the same hex, and under simulation its orange sits too close to yellow, so a directory listing matches a success message. The matrix variant and color space behind the shipped themes' numbers are not recorded in the repo, so pick one method and hold it fixed when comparing two palettes.
3. Check WCAG contrast of every text color on the background. Every one must clear 4.5:1.

The Omarchy fleet theme mirrors this palette; `resources/omarchy.md` says how an edit propagates. herdr inherits the terminal palette; see `resources/herdr.md`.
