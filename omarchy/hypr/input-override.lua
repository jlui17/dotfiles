-- Modifier remapping - overrides for Omarchy.
-- Required from hyprland.lua after Omarchy's defaults so this kb_options wins.

hl.config({
  input = {
    -- Left cluster rotates so physical Ctrl acts as Super, Super as Alt, Alt as Ctrl.
    -- Right cluster keeps the plain Win/Ctrl swap; xkb has no right-hand rotate.
    kb_options = "compose:caps,shift:both_capslock_cancel,ctrl:swap_lalt_lctl_lwin,ctrl:swap_rwin_rctl",
  },
})
