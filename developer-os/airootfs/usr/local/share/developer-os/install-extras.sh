#!/usr/bin/env bash
#
# Developer OS — optional components also applied on the live image (customize.sh).
# Installs: Flathub + Brave Flatpak, vfox, JetBrains Toolbox, and validates the Developer OS theme.
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

# --- vfox (default pin for reproducible ISO builds; override via env for updates) ---
VFOX_VERSION="${VFOX_VERSION:-1.0.11}"
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
  printf '%s\n' "${VFOX_VERSION}" >/usr/local/share/developer-os/vfox.version
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

# --- Shared vfox plugins (Java / Maven / Gradle / Node / .NET) ---
VFOX_HOME="${VFOX_HOME:-/opt/vfox}"
export VFOX_HOME
setup_vfox_shared_home() {
  getent group vfox >/dev/null 2>&1 || groupadd vfox
  install -d -m 2775 -o root -g vfox "${VFOX_HOME}"
  if ! grep -q '^VFOX_HOME=' /etc/environment 2>/dev/null; then
    printf 'VFOX_HOME=%s\n' "${VFOX_HOME}" >>/etc/environment
  fi
  if [[ ! -x /usr/local/bin/vfox ]]; then
    echo "[install-extras] WARNING: vfox missing; skipping plugin pre-add." >&2
    return 0
  fi
  set +e
  /usr/local/bin/vfox add java maven gradle nodejs dotnet
  _plug=$?
  set -e
  if ((_plug != 0)); then
    echo "[install-extras] WARNING: vfox add plugins exited ${_plug}; need network." >&2
  else
    echo "[install-extras] vfox plugins added under ${VFOX_HOME} (java maven gradle nodejs dotnet)."
  fi
  chgrp -R vfox "${VFOX_HOME}" 2>/dev/null || true
  chmod -R g+rwX "${VFOX_HOME}" 2>/dev/null || true
  find "${VFOX_HOME}" -type d -exec chmod 2775 {} + 2>/dev/null || true
}
setup_vfox_shared_home

# --- JetBrains Toolbox (default pin for reproducible ISO builds; override via env for updates) ---
TOOLBOX_BUILD="${TOOLBOX_BUILD:-3.5.0.84344}"
TOOLBOX_TAR="jetbrains-toolbox-${TOOLBOX_BUILD}.tar.gz"
TOOLBOX_BASE="https://download.jetbrains.com/toolbox"
install_jetbrains_toolbox() {
  local tmp extracted
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp}'" EXIT
  curl -fsSL "${TOOLBOX_BASE}/${TOOLBOX_TAR}" -o "${tmp}/${TOOLBOX_TAR}"
  curl -fsSL "${TOOLBOX_BASE}/${TOOLBOX_TAR}.sha256" -o "${tmp}/${TOOLBOX_TAR}.sha256"
  (cd "${tmp}" && sha256sum -c "${TOOLBOX_TAR}.sha256")
  tar -xzf "${tmp}/${TOOLBOX_TAR}" -C "${tmp}"
  extracted="${tmp}/jetbrains-toolbox-${TOOLBOX_BUILD}"
  if [[ ! -d "${extracted}" ]]; then
    # Newer Toolbox tarballs may unpack to a slightly different directory name.
    extracted="$(find "${tmp}" -mindepth 1 -maxdepth 1 -type d -name 'jetbrains-toolbox-*' | head -n1)"
  fi
  [[ -n "${extracted}" && -d "${extracted}" ]] || {
    echo "[install-extras] ERROR: JetBrains Toolbox extract dir missing." >&2
    return 1
  }
  rm -rf /opt/jetbrains-toolbox
  mv "${extracted}" /opt/jetbrains-toolbox
  ln -sf /opt/jetbrains-toolbox/bin/jetbrains-toolbox /usr/local/bin/jetbrains-toolbox
  install -d /usr/share/applications /usr/local/share/developer-os
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
  printf '%s\n' "${TOOLBOX_BUILD}" >/usr/local/share/developer-os/jetbrains-toolbox.version
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

# --- Developer OS Plasma theme (vendored in airootfs; no network required) ---
if [[ -x /usr/local/bin/install-developer-os-theme.sh ]]; then
  set +e
  /usr/local/bin/install-developer-os-theme.sh
  _mt=$?
  set -e
  if ((_mt != 0)); then
    echo "[install-extras] WARNING: Developer OS theme validation failed (${_mt})." >&2
  else
    echo "[install-extras] Developer OS theme present."
  fi
else
  echo "[install-extras] WARNING: install-developer-os-theme.sh missing." >&2
fi
