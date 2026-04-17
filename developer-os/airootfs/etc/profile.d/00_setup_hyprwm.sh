#!/bin/sh
# POSIX: sourced from /etc/profile (may run under `emulate sh`).
# Only on tty1: same condition as Hyprland autostart, so we do not run hyprpm on every SSH login.
case $(tty 2>/dev/null) in
/dev/tty1)
  if command -v hyprpm >/dev/null 2>&1 && [ -x /usr/local/bin/prepare-desktop ]; then
    /usr/local/bin/prepare-desktop || true
  fi
  ;;
esac
