# Start Hyprland on first TTY after login (live session / console installs).
# POSIX `[` — profile may be sourced with sh emulation from zsh's /etc/zsh/zprofile.
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ -z "${DISPLAY:-}" ] && [ "$(tty 2>/dev/null)" = /dev/tty1 ]; then
  exec start-hyprland
fi
