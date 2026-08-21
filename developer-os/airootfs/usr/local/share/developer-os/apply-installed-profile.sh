#!/usr/bin/env bash
#
# Apply Developer OS live-profile parity to an installed target.
# Run from the live environment with the target mounted at TARGET_ROOT.
#
set -euo pipefail

TARGET_ROOT="${1:-/mnt}"
IN_USER="${2:-developer}"
EXTRAS_SELECTION="${3:-extras}"

[[ -d "${TARGET_ROOT}" ]] || { echo "Missing target root: ${TARGET_ROOT}" >&2; exit 1; }
[[ -d "${TARGET_ROOT}/etc" ]] || { echo "Target root is not mounted: ${TARGET_ROOT}" >&2; exit 1; }
[[ -n "${IN_USER}" ]] || { echo "Missing target username." >&2; exit 1; }

install -d \
  "${TARGET_ROOT}/usr/local/bin" \
  "${TARGET_ROOT}/usr/local/share/developer-os" \
  "${TARGET_ROOT}/usr/local/share/bash-completion/completions" \
  "${TARGET_ROOT}/usr/local/share/zsh/site-functions" \
  "${TARGET_ROOT}/usr/share/applications" \
  "${TARGET_ROOT}/etc/profile.d"

copy_if_present() {
  local src="$1" dst="$2"
  [[ -e "${src}" ]] && cp -a "${src}" "${dst}" || true
}

copy_executable_helper() {
  local helper="$1"
  if [[ -e "/usr/local/bin/${helper}" ]]; then
    cp -a "/usr/local/bin/${helper}" "${TARGET_ROOT}/usr/local/bin/"
    chmod a+rx "${TARGET_ROOT}/usr/local/bin/${helper}" 2>/dev/null || true
  fi
}

for helper in install-extras.sh update-extras.sh seed-plasma-mactahoe.sh strip-plasma-showdesktop.sh sync-etc-skel-from-home.sh configure-installed-system.sh apply-installed-profile.sh prepare-installed-mkinitcpio.sh developer-os-welcome developer-os-update developer-os-bootstrap; do
  copy_if_present "/usr/local/share/developer-os/${helper}" "${TARGET_ROOT}/usr/local/share/developer-os/"
  chmod 0755 "${TARGET_ROOT}/usr/local/share/developer-os/${helper}" 2>/dev/null || true
done
copy_if_present /usr/local/share/developer-os/developer-os-welcome.qml "${TARGET_ROOT}/usr/local/share/developer-os/"
copy_if_present /usr/share/applications/developer-os-update.desktop "${TARGET_ROOT}/usr/share/applications/"
copy_if_present /usr/share/applications/developer-os-bootstrap.desktop "${TARGET_ROOT}/usr/share/applications/"
copy_if_present /etc/profile.d/developer-os-vfox.sh "${TARGET_ROOT}/etc/profile.d/developer-os-vfox.sh"

for helper in developer-os-install developer-os-welcome developer-os-zsh-welcome developer-os-update developer-os-bootstrap install-mactahoe-kde-theme.sh Installation_guide choose-mirror; do
  copy_executable_helper "${helper}"
done

copy_if_present /usr/local/share/developer-os/installer-packages.list "${TARGET_ROOT}/usr/local/share/developer-os/"

# Branded wallpaper (airootfs); not part of pacstrap package set.
if [[ -d /usr/share/wallpapers/DeveloperOS ]]; then
  install -d "${TARGET_ROOT}/usr/share/wallpapers"
  cp -a /usr/share/wallpapers/DeveloperOS "${TARGET_ROOT}/usr/share/wallpapers/"
elif [[ -f /usr/share/wallpapers/wallpaper.png ]]; then
  install -d "${TARGET_ROOT}/usr/share/wallpapers"
  cp -a /usr/share/wallpapers/wallpaper.png "${TARGET_ROOT}/usr/share/wallpapers/"
fi

if [[ -x "${TARGET_ROOT}/usr/local/share/developer-os/configure-installed-system.sh" ]]; then
  arch-chroot "${TARGET_ROOT}" env IN_USER="${IN_USER}" PW1="${PW1:-}" DEVELOPER_OS_CREATE_USER="${DEVELOPER_OS_CREATE_USER:-0}" DEVELOPER_OS_INSTALL_BOOTLOADER="${DEVELOPER_OS_INSTALL_BOOTLOADER:-0}" /usr/local/share/developer-os/configure-installed-system.sh
fi

if [[ "${EXTRAS_SELECTION}" == *extras* && -x "${TARGET_ROOT}/usr/local/share/developer-os/install-extras.sh" ]]; then
  set +e
  arch-chroot "${TARGET_ROOT}" /usr/local/share/developer-os/install-extras.sh
  _ex=$?
  set -e
  if ((_ex != 0)); then
    echo "[apply-installed-profile] WARNING: install-extras.sh exited ${_ex}." >&2
  fi
  if [[ ! -d "${TARGET_ROOT}/usr/share/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-Light" \
        && ! -d "${TARGET_ROOT}/usr/share/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-Dark" ]]; then
    echo "[apply-installed-profile] MacTahoe theme not on target; copying from live system if present..." >&2
    /usr/local/bin/install-mactahoe-kde-theme.sh --rsync-from-live "${TARGET_ROOT}" || true
  fi

  # Fallback when install-extras could not download during install.
  if [[ -x /usr/local/bin/vfox && ! -x "${TARGET_ROOT}/usr/local/bin/vfox" ]]; then
    cp -a /usr/local/bin/vfox "${TARGET_ROOT}/usr/local/bin/"
  fi
  if [[ -f /usr/local/share/bash-completion/completions/vfox && ! -f "${TARGET_ROOT}/usr/local/share/bash-completion/completions/vfox" ]]; then
    cp -a /usr/local/share/bash-completion/completions/vfox "${TARGET_ROOT}/usr/local/share/bash-completion/completions/"
  fi
  if [[ -f /usr/local/share/zsh/site-functions/_vfox && ! -f "${TARGET_ROOT}/usr/local/share/zsh/site-functions/_vfox" ]]; then
    cp -a /usr/local/share/zsh/site-functions/_vfox "${TARGET_ROOT}/usr/local/share/zsh/site-functions/"
  fi
  if [[ -d /opt/vfox ]]; then
    install -d "${TARGET_ROOT}/opt"
    rsync -a /opt/vfox/ "${TARGET_ROOT}/opt/vfox/"
    arch-chroot "${TARGET_ROOT}" bash -c 'getent group vfox >/dev/null 2>&1 || groupadd vfox; chown -R root:vfox /opt/vfox; chmod -R g+rwX /opt/vfox' 2>/dev/null || true
  fi
  if [[ -d /opt/jetbrains-toolbox && ! -d "${TARGET_ROOT}/opt/jetbrains-toolbox" ]]; then
    install -d "${TARGET_ROOT}/opt"
    cp -a /opt/jetbrains-toolbox "${TARGET_ROOT}/opt/"
    ln -sf /opt/jetbrains-toolbox/bin/jetbrains-toolbox "${TARGET_ROOT}/usr/local/bin/jetbrains-toolbox"
    copy_if_present /usr/share/applications/jetbrains-toolbox.desktop "${TARGET_ROOT}/usr/share/applications/"
  fi
fi

if [[ -d /home/liveuser/.config ]]; then
  install -d "${TARGET_ROOT}/home/${IN_USER}"
  rsync -a --exclude='.cache' /home/liveuser/.config/ "${TARGET_ROOT}/home/${IN_USER}/.config/"
  for f in .zshrc .zprofile; do
    copy_if_present "/home/liveuser/${f}" "${TARGET_ROOT}/home/${IN_USER}/${f}"
  done
  arch-chroot "${TARGET_ROOT}" chown -R "${IN_USER}:${IN_USER}" "/home/${IN_USER}" 2>/dev/null || true
fi

if [[ -d "${TARGET_ROOT}/home/${IN_USER}" && -x "${TARGET_ROOT}/usr/local/share/developer-os/seed-plasma-mactahoe.sh" ]]; then
  set +e
  arch-chroot "${TARGET_ROOT}" /usr/local/share/developer-os/seed-plasma-mactahoe.sh "${IN_USER}"
  _seed=$?
  set -e
  if ((_seed != 0)); then
    echo "[apply-installed-profile] WARNING: seed-plasma-mactahoe.sh exited ${_seed}." >&2
  fi
  arch-chroot "${TARGET_ROOT}" chown -R "${IN_USER}:${IN_USER}" "/home/${IN_USER}" 2>/dev/null || true
fi

if [[ -d "${TARGET_ROOT}/home/${IN_USER}" && -x /usr/local/share/developer-os/sync-etc-skel-from-home.sh ]]; then
  /usr/local/share/developer-os/sync-etc-skel-from-home.sh "${TARGET_ROOT}/home/${IN_USER}" "${TARGET_ROOT}"
fi

# Remove live-session behavior from installed systems.
rm -f "${TARGET_ROOT}/etc/sddm.conf.d/autologin.conf"
if ! grep -q '^VFOX_HOME=' "${TARGET_ROOT}/etc/environment" 2>/dev/null; then
  printf 'VFOX_HOME=/opt/vfox\n' >>"${TARGET_ROOT}/etc/environment"
fi
rm -rf "${TARGET_ROOT}/etc/calamares"
rm -f \
  "${TARGET_ROOT}/usr/share/applications/install-develop-os.desktop" \
  "${TARGET_ROOT}/usr/share/applications/developer-os-installer.desktop" \
  "${TARGET_ROOT}/usr/share/applications/calamares.desktop" \
  "${TARGET_ROOT}/usr/local/bin/developer-os-launch-installer" \
  "${TARGET_ROOT}/usr/local/share/developer-os/install-calamares.sh" \
  "${TARGET_ROOT}/etc/sudoers.d/20-calamares-env"
remove_live_only_user() {
  local name="$1"
  if arch-chroot "${TARGET_ROOT}" id -u "${name}" &>/dev/null; then
    arch-chroot "${TARGET_ROOT}" userdel -r "${name}" 2>/dev/null || \
      arch-chroot "${TARGET_ROOT}" userdel "${name}" 2>/dev/null || true
  fi
  rm -rf "${TARGET_ROOT}/home/${name}" "${TARGET_ROOT}/var/tmp/${name}"
}

# liveuser is the ISO session account. aurbuild/auruser are throwaway
# makepkg users created while building Calamares from the AUR.
remove_live_only_user liveuser
remove_live_only_user aurbuild
remove_live_only_user auruser
