-- macOS-style keybindings - overrides for Omarchy.
-- These bindings simulate macOS Cmd key behavior.

-- Swap SUPER CTRL, C and SUPER CTRL, V (capture menu and clipboard manager)
hl.unbind("SUPER + CTRL + C")
hl.unbind("SUPER + CTRL + V")
o.bind("SUPER + CTRL + V", "Capture menu", "omarchy-menu toggle capture")
o.bind("SUPER + CTRL + C", "Clipboard manager", "omarchy-shell shell toggle omarchy.clipboard")

-- Screenshot straight to the clipboard, no file left on disk
-- (unbinds the preinstalled Google Maps webapp on the same key)
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot to clipboard", "omarchy-capture-screenshot smart copy")

-- Move pseudo window to SUPER CTRL, P
hl.unbind("SUPER + P")
hl.unbind("SUPER + SHIFT + P")
o.bind("SUPER + CTRL + P", "Pseudo window", hl.dsp.window.pseudo())

-- Move keybindings menu to SUPER SHIFT, K
hl.unbind("SUPER + K")
o.bind("SUPER + SHIFT + K", "Keybindings", "omarchy-menu-keybindings")

-- Swap herdr and the plain terminal: herdr takes SUPER RETURN, terminal moves
-- to SUPER CTRL RETURN
hl.unbind("SUPER + RETURN")
hl.unbind("SUPER + CTRL + RETURN")
o.bind("SUPER + RETURN", "Herdr", { omarchy = "terminal-herdr" })
o.bind("SUPER + CTRL + RETURN", "Terminal", { omarchy = "terminal" })

-- Speech-to-text. hyprwhspr setup writes this to ~/.config/hypr/bindings.conf,
-- which Omarchy's Lua config no longer reads.
-- (unbinds the background switcher, still reachable from the Omarchy menu)
hl.unbind("SUPER + CTRL + SPACE")
o.bind("SUPER + CTRL + SPACE", "Speech-to-text", "/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh record")

-- Blip messages popover (unbinds Omarchy's Music TUI on the same key).
-- Double-click the bar icon for the full app window instead.
hl.unbind("SUPER + M")
o.bind("SUPER + M", "Blip messages", "omarchy-shell nixfred.blip toggle")

-- Gmail and Notion keep the keys Omarchy reassigned to Spotify and its editor
hl.unbind("SUPER + SHIFT + M")
hl.unbind("SUPER + SHIFT + N")
o.bind("SUPER + SHIFT + M", "Gmail", { webapp = "https://mail.google.com" })
o.bind("SUPER + SHIFT + N", "Notion", { webapp = "https://notion.so" })
