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
systemctl enable sddm.service
systemctl set-default graphical.target

# --- Flatpak + Flathub (system remote) ---
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# --- Brave Browser (Flathub: com.brave.Browser; needs network during mkarchiso) ---
if command -v flatpak &>/dev/null; then
  set +e
  flatpak install -y --system flathub com.brave.Browser
  _brave=$?
  set -e
  if ((_brave != 0)); then
    echo "[customize.sh] WARNING: Brave Flatpak install failed (${_brave}); need network during ISO build." >&2
  else
    echo "[customize.sh] Brave Browser installed from Flathub (com.brave.Browser)."
  fi
fi

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

# --- JetBrains Toolbox App (https://www.jetbrains.com/toolbox-app/) ---
# Pin build here; bump using: https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release&platform=linux
TOOLBOX_BUILD="3.4.3.81140"
TOOLBOX_TAR="jetbrains-toolbox-${TOOLBOX_BUILD}.tar.gz"
TOOLBOX_BASE="https://download.jetbrains.com/toolbox"
install_jetbrains_toolbox() {
  local tmp
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp}'" EXIT
  curl -fsSL "${TOOLBOX_BASE}/${TOOLBOX_TAR}" -o "${tmp}/${TOOLBOX_TAR}"
  curl -fsSL "${TOOLBOX_BASE}/${TOOLBOX_TAR}.sha256" -o "${tmp}/${TOOLBOX_TAR}.sha256"
  (cd "${tmp}" && sha256sum -c "${TOOLBOX_TAR}.sha256")
  tar -xzf "${tmp}/${TOOLBOX_TAR}" -C "${tmp}"
  rm -rf /opt/jetbrains-toolbox
  mv "${tmp}/jetbrains-toolbox-${TOOLBOX_BUILD}" /opt/jetbrains-toolbox
  ln -sf /opt/jetbrains-toolbox/bin/jetbrains-toolbox /usr/local/bin/jetbrains-toolbox
  install -d /usr/share/applications
  cat >/usr/share/applications/jetbrains-toolbox.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=JetBrains Toolbox
Comment=Install and manage JetBrains IDEs (jetbrains.com/toolbox-app)
Exec=/opt/jetbrains-toolbox/bin/jetbrains-toolbox %u
Icon=jetbrains-toolbox
StartupNotify=true
Terminal=false
Categories=Development;Utility;
MimeType=
EOF
  chmod 0755 /opt/jetbrains-toolbox/bin/jetbrains-toolbox
  trap - EXIT
  rm -rf "${tmp}"
}
if command -v curl &>/dev/null; then
  set +e
  install_jetbrains_toolbox
  _tb=$?
  set -e
  if ((_tb != 0)); then
    echo "[customize.sh] WARNING: JetBrains Toolbox install failed (${_tb}); need network during ISO build." >&2
  else
    echo "[customize.sh] JetBrains Toolbox ${TOOLBOX_BUILD} installed under /opt/jetbrains-toolbox"
  fi
else
  echo "[customize.sh] WARNING: curl missing; skipping JetBrains Toolbox install." >&2
fi

# --- MacTahoe KDE theme (Plasma look-and-feel + Kvantum + icons; needs network during mkarchiso) ---
seed_mactahoe_liveuser_config() {
  install -d -m 0755 -o liveuser -g liveuser /home/liveuser/.config/Kvantum
  cat >/home/liveuser/.config/kdeglobals <<'EOF'
[KDE]
LookAndFeelPackage=com.github.vinceliuice.MacTahoe-Dark

[General]
ColorScheme=MacTahoeDark

[Icons]
Theme=MacTahoe-dark
EOF
  cat >/home/liveuser/.config/plasmarc <<'EOF'
[Theme]
name=MacTahoe-Dark
EOF
  cat >/home/liveuser/.config/kwinrc <<'EOF'
[DesktopSwitcher]
LayoutName=org.kde.breeze.desktop

[WindowSwitcher]
LayoutName=org.kde.breeze.desktop

[org.kde.kdecoration2]
ButtonsOnLeft=XAI
ButtonsOnRight=
library=org.kde.kwin.aurorae
theme=__aurorae__svg__MacTahoe-Dark
EOF
  cat >/home/liveuser/.config/kcminputrc <<'EOF'
[Mouse]
cursorTheme=MacTahoe-dark
EOF
  cat >/home/liveuser/.config/Kvantum/kvantum.kvconfig <<'EOF'
[General]
theme=MacTahoe
EOF
  cat > /home/liveuser/.config/plasma-org.kde.plasma.desktop-appletsrc <<'EOF'
[Containments][19][Wallpaper][org.kde.image][General]
Image=file:///usr/share/wallpapers/wallpaper.png
SlidePaths=/usr/share/wallpapers
EOF
  chown liveuser:liveuser /home/liveuser/.config/kdeglobals \
    /home/liveuser/.config/plasmarc \
    /home/liveuser/.config/kwinrc \
    /home/liveuser/.config/kcminputrc \
    /home/liveuser/.config/Kvantum/kvantum.kvconfig
}

if [[ -x /usr/local/bin/install-mactahoe-kde-theme.sh ]]; then
  set +e
  /usr/local/bin/install-mactahoe-kde-theme.sh
  _mt=$?
  set -e
  if ((_mt != 0)); then
    echo "[customize.sh] WARNING: MacTahoe theme install failed (${_mt}); need git + network during ISO build." >&2
  elif [[ -d /usr/share/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-Light ]]; then
    seed_mactahoe_liveuser_config
    chown -R liveuser:liveuser /home/liveuser
    echo "[customize.sh] MacTahoe theme applied; liveuser Plasma defaults seeded."
  fi
fi