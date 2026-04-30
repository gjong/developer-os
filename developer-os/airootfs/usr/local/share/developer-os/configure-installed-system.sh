#!/usr/bin/env bash
#
# Developer OS target-system configuration.
# Run inside the installed system, either via arch-chroot or Calamares.
#
set -euo pipefail

IN_USER="${IN_USER:-}"
PW1="${PW1:-}"
DEVELOPER_OS_INSTALL_BOOTLOADER="${DEVELOPER_OS_INSTALL_BOOTLOADER:-0}"
DEVELOPER_OS_CREATE_USER="${DEVELOPER_OS_CREATE_USER:-0}"

if [[ "${DEVELOPER_OS_INSTALL_BOOTLOADER}" == "1" ]]; then
  bootctl install --esp-path=/boot --no-variables
fi

systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable sddm.service
systemctl set-default graphical.target
systemctl --global enable pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true

install -d -m 0750 /etc/sudoers.d
printf '%%wheel ALL=(ALL:ALL) ALL\n' >/etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel

if [[ -n "${IN_USER}" ]]; then
  if ! id -u "${IN_USER}" &>/dev/null; then
    if [[ "${DEVELOPER_OS_CREATE_USER}" != "1" ]]; then
      echo "User ${IN_USER} does not exist and DEVELOPER_OS_CREATE_USER is not enabled." >&2
      exit 1
    fi
    useradd -m -G wheel,video,input,audio,storage -s /usr/bin/zsh "${IN_USER}"
  else
    usermod -aG wheel,video,input,audio,storage -s /usr/bin/zsh "${IN_USER}"
  fi

  if [[ -n "${PW1}" ]]; then
    printf '%s\n' "${IN_USER}:${PW1}" | chpasswd
  fi
fi
