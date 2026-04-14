#!/usr/bin/env bash
# Runs inside the ISO rootfs via arch-chroot (see mkarchiso).

set -euo pipefail

# --- Live user (entry comes from airootfs/etc/passwd; home is pre-seeded in the profile) ---
# passwd lists GID 1000, but pacstrap's /etc/group has no "liveuser" name — chown user:liveuser then fails.
if ! getent group liveuser &>/dev/null; then
  groupadd -g 1000 liveuser || {
    groupadd liveuser
    usermod -g liveuser liveuser
  }
fi
if ! id -u liveuser &>/dev/null; then
  useradd -M -d /home/liveuser -g liveuser -s /usr/bin/zsh liveuser
fi
usermod -aG wheel,video,input,audio,storage liveuser 2>/dev/null || true
passwd -d liveuser &>/dev/null || true
install -d -m 0755 -o liveuser -g liveuser /home/liveuser/Pictures
chown -R liveuser:liveuser /home/liveuser
chmod 0700 /home/liveuser

# --- Sudo for wheel (passwordless on live medium) ---
install -d -m 0750 /etc/sudoers.d
printf '%%wheel ALL=(ALL:ALL) NOPASSWD: ALL\n' >/etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel

# --- Services ---
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service

# --- Optional: autologin on tty1 as liveuser ---
install -d -m 0755 /etc/systemd/system/getty@tty1.service.d
cat >/etc/systemd/system/getty@tty1.service.d/autologin.conf <<'EOF'
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin liveuser --noclear %I $TERM
EOF

# --- Flatpak + Flathub (system remote) ---
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# --- Hyprbars: Hyprland plugin from hyprland-plugins (not a pacman package; hyprpm + exec-once reload) ---
# Runs as liveuser so state is under /home/liveuser/.local/share/hyprpm. Needs git + network during mkarchiso.
if command -v hyprpm &>/dev/null; then
  _hyprpm() { runuser -u liveuser -- env HOME=/home/liveuser USER=liveuser LOGNAME=liveuser "$@"; }
  set +e
  _hyprpm hyprpm update
  _st=$?
  set -e
  if (( _st != 0 )); then
    echo "[customize.sh] WARNING: hyprpm update failed (${_st}); hyprbars skipped (no network or headers mismatch)." >&2
  else
    set +e
    _hyprpm hyprpm add https://github.com/hyprwm/hyprland-plugins
    set -e
    _hyprpm hyprpm enable hyprbars
    set +e
    _hyprpm hyprpm update
    _st2=$?
    set -e
    if (( _st2 != 0 )); then
      echo "[customize.sh] WARNING: hyprpm plugin build failed (${_st2}); check build log for hyprbars." >&2
    else
      echo "[customize.sh] hyprbars plugin installed for liveuser (hyprpm)."
    fi
  fi
fi