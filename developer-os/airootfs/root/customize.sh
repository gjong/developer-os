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
# docker group comes from the docker package (installed via packages.x86_64).
if getent group docker &>/dev/null; then
  usermod -aG docker liveuser 2>/dev/null || true
fi
if getent group vfox &>/dev/null; then
  usermod -aG vfox liveuser 2>/dev/null || true
fi
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
systemctl enable docker.service
systemctl enable ollama.service
systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service
systemctl enable sddm.service
systemctl set-default graphical.target

# --- Calamares GUI installer (AUR-only on Arch; keep live-only) ---
if [[ -x /usr/local/share/developer-os/install-calamares.sh ]]; then
  set +e
  /usr/local/share/developer-os/install-calamares.sh
  _cal=$?
  set -e
  if ((_cal != 0)); then
    echo "[customize.sh] WARNING: install-calamares.sh exited ${_cal}; GUI installer will be unavailable." >&2
    rm -f /usr/share/applications/install-develop-os.desktop
  fi
else
  echo "[customize.sh] WARNING: /usr/local/share/developer-os/install-calamares.sh missing." >&2
  rm -f /usr/share/applications/install-develop-os.desktop
fi

# --- Same optional stack as disk install (Flathub/Brave, vfox, JetBrains Toolbox, theme) ---
if [[ -x /usr/local/share/developer-os/install-extras.sh ]]; then
  set +e
  /usr/local/share/developer-os/install-extras.sh
  _ex=$?
  set -e
  if ((_ex != 0)); then
    echo "[customize.sh] WARNING: install-extras.sh exited ${_ex}." >&2
  fi
else
  echo "[customize.sh] WARNING: /usr/local/share/developer-os/install-extras.sh missing." >&2
fi
if getent group vfox &>/dev/null; then
  usermod -aG vfox liveuser 2>/dev/null || true
fi

# --- Remove Peek at Desktop from Plasma panel templates (bottom application bar) ---
if [[ -x /usr/local/share/developer-os/strip-plasma-showdesktop.sh ]]; then
  /usr/local/share/developer-os/strip-plasma-showdesktop.sh /
fi

# --- Developer OS theme: seed Plasma for liveuser ---
if [[ -x /usr/local/share/developer-os/seed-plasma-theme.sh ]]; then
  /usr/local/share/developer-os/seed-plasma-theme.sh liveuser
  chown -R liveuser:liveuser /home/liveuser
  echo "[customize.sh] Plasma Developer OS defaults applied for liveuser."
else
  echo "[customize.sh] WARNING: seed-plasma-theme.sh missing." >&2
fi

# --- New users: same dotfiles + Plasma as liveuser (useradd -m copies /etc/skel) ---
if [[ -x /usr/local/share/developer-os/sync-etc-skel-from-home.sh ]]; then
  /usr/local/share/developer-os/sync-etc-skel-from-home.sh /home/liveuser /
  echo "[customize.sh] /etc/skel synced from liveuser."
else
  echo "[customize.sh] WARNING: sync-etc-skel-from-home.sh missing." >&2
fi

rm /usr/share/applications/calamares.desktop