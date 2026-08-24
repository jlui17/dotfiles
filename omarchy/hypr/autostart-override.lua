-- Omarchy's own autostart starts the shell GPU-backed; this replaces it with a
-- software-rendered one. See omarchy-shell-software for why.
o.exec_on_start("omarchy-shell-software")
