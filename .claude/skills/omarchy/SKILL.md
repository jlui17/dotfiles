---
name: omarchy
description: macOS-style keybindings for Hyprland via Omarchy (Arch Linux only). Use when adding, changing, or reverting Hyprland keybindings on the Arch machine.
---

Single override file that unbinds and rebinds Omarchy's default keybindings to match macOS Cmd-key muscle memory. Edits propagate via symlink + hyprctl reload. Only runs on Arch; skipped entirely on macOS.

**Install flow** (install.sh): guards on OS=arch + omarchy-update exists. Symlinks bindings-override.conf → ~/.config/hypr/bindings-override.conf. Appends `source = bindings-override.conf` to hyprland.conf if missing.

**Tasks:**
- Add/modify binding: edit bindd lines, `hyprctl reload`
- Revert to default: comment/remove unbind+bindd lines for that binding, `hyprctl reload`
- SUPER key: Cmd on Apple keyboards, Windows key on PC — set by Omarchy, not this module
