# Start Hyprland on first TTY after login (live session / console installs).
if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" && "$(tty 2>/dev/null)" == /dev/tty1 ]]; then
  exec start-hyprland
fi