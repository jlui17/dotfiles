-- Palworld (Steam app 1623730): themes with global active_opacity < 1 leave
-- the game translucent; pin it opaque.
o.window("steam_app_1623730", { tag = "-default-opacity", opacity = "1 1" })
