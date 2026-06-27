#!/usr/bin/env bash
#
# Developer OS — optional components also applied on the live image (customize.sh).
# Installs: Flathub + Brave Flatpak, vfox, JetBrains Toolbox, MacTahoe theme (system-wide).
# Run as root (mkarchiso chroot or arch-chroot /mnt). Failures are non-fatal except where noted.
#
set -euo pipefail

[[ "$(id -u)" -eq 0 ]] || { echo "Run as root." >&2; exit 1; }

# --- Flathub + Brave (same as customize.sh) ---
if command -v flatpak &>/dev/null; then
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
  set +e
  flatpak install -y --system flathub com.brave.Browser
  _brave=$?
  set -e
  if ((_brave != 0)); then
    echo "[install-extras] WARNING: Brave Flatpak install failed (${_brave}); need network." >&2
  else
    echo "[install-extras] Brave Browser installed from Flathub (com.brave.Browser)."
  fi
else
  echo "[install-extras] WARNING: flatpak not installed; skipping Brave." >&2
fi

# --- vfox (pin here; bump with customize.sh / README) ---
VFOX_VERSION="1.0.11"
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
    echo "[install-extras] WARNING: vfox install failed (${_vf}); need network." >&2
  else
    echo "[install-extras] vfox ${VFOX_VERSION} installed to /usr/local/bin/vfox"
  fi
else
  echo "[install-extras] WARNING: curl missing; skipping vfox." >&2
fi

# --- JetBrains Toolbox ---
TOOLBOX_BUILD="3.5.0.84344"
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
    echo "[install-extras] WARNING: JetBrains Toolbox install failed (${_tb}); need network." >&2
  else
    echo "[install-extras] JetBrains Toolbox ${TOOLBOX_BUILD} installed under /opt/jetbrains-toolbox"
  fi
else
  echo "[install-extras] WARNING: curl missing; skipping JetBrains Toolbox." >&2
fi

# --- MacTahoe KDE theme ---
if [[ -x /usr/local/bin/install-mactahoe-kde-theme.sh ]]; then
  set +e
  /usr/local/bin/install-mactahoe-kde-theme.sh
  _mt=$?
  set -e
  if ((_mt != 0)); then
    echo "[install-extras] WARNING: MacTahoe theme install failed (${_mt}); need git + network (or rsync from live during disk install)." >&2
  else
    echo "[install-extras] MacTahoe theme installed."
  fi
else
  echo "[install-extras] WARNING: install-mactahoe-kde-theme.sh missing." >&2
fi
