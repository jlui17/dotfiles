-- macOS-style keybindings - overrides for Omarchy.
-- These bindings simulate macOS Cmd key behavior.

-- Swap SUPER CTRL, C and SUPER CTRL, V (capture menu and clipboard manager)
hl.unbind("SUPER + CTRL + C")
hl.unbind("SUPER + CTRL + V")
o.bind("SUPER + CTRL + V", "Capture menu", "omarchy-menu toggle capture")
o.bind("SUPER + CTRL + C", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")

-- Move scratchpad to SUPER SHIFT, S
hl.unbind("SUPER + S")
o.bind("SUPER + SHIFT + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))

-- Move pseudo window to SUPER CTRL, P
hl.unbind("SUPER + P")
hl.unbind("SUPER + SHIFT + P")
o.bind("SUPER + CTRL + P", "Pseudo window", hl.dsp.window.pseudo())
