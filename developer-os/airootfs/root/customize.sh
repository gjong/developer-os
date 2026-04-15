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

# --- vfox (version-fox): not in Arch [extra]; install official GitHub release (x86_64) ---
# Pin version here; bump when upgrading the live image.
VFOX_VERSION="1.0.8"
VFOX_TAG="v${VFOX_VERSION}"
VFOX_TAR="vfox_${VFOX_VERSION}_linux_x86_64.tar.gz"
VFOX_BASE="https://github.com/version-fox/vfox/releases/download/${VFOX_TAG}"
install_vfox_from_github() {
  local tmp _root
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp}'" EXIT
  curl -fsSL "${VFOX_BASE}/checksums.txt" -o "${tmp}/checksums.txt"
  curl -fsSL "${VFOX_BASE}/${VFOX_TAR}" -o "${tmp}/${VFOX_TAR}"
  (cd "${tmp}" && grep -F "${VFOX_TAR}" checksums.txt | sha256sum -c -)
  tar -xzf "${tmp}/${VFOX_TAR}" -C "${tmp}"
  _root="${tmp}/vfox_${VFOX_VERSION}_linux_x86_64"
  install -d /usr/local/share/bash-completion/completions /usr/local/share/zsh/site-functions
  install -Dm0755 "${_root}/vfox" /usr/local/bin/vfox
  install -Dm0644 "${_root}/completions/bash_autocomplete" /usr/local/share/bash-completion/completions/vfox
  install -Dm0644 "${_root}/completions/zsh_autocomplete" /usr/local/share/zsh/site-functions/_vfox
  trap - EXIT
  rm -rf "${tmp}"
}
if command -v curl &>/dev/null; then
  set +e
  install_vfox_from_github
  _vf=$?
  set -e
  if (( _vf != 0 )); then
    echo "[customize.sh] WARNING: vfox install failed (${_vf}); need network during ISO build." >&2
  else
    echo "[customize.sh] vfox ${VFOX_VERSION} installed to /usr/local/bin/vfox"
  fi
else
  echo "[customize.sh] WARNING: curl missing; skipping vfox install." >&2
fi