#!/usr/bin/env bash
#
# Replace live-image mkinitcpio (archiso) config with a normal installed-system preset.
# Used by Calamares before the initcpio module; safe to run from apply-installed-profile too.
#
# Usage: prepare-installed-mkinitcpio.sh [TARGET_ROOT]
#   TARGET_ROOT defaults to / (when already chrooted into the installed system).
#
set -euo pipefail

TARGET_ROOT="${1:-/}"
if [[ "${TARGET_ROOT}" != "/" ]]; then
  TARGET_ROOT="${TARGET_ROOT%/}"
fi

[[ -d "${TARGET_ROOT}/etc" ]] || {
  echo "[prepare-installed-mkinitcpio] Missing target root: ${TARGET_ROOT}" >&2
  exit 1
}

install -d "${TARGET_ROOT}/etc/mkinitcpio.d" "${TARGET_ROOT}/etc/mkinitcpio.conf.d"

# Drop live-only mkinitcpio fragment shipped in airootfs.
rm -f "${TARGET_ROOT}/etc/mkinitcpio.conf.d/archiso.conf"

# Stock linux package preset (default + fallback) — not the archiso-only preset.
cat >"${TARGET_ROOT}/etc/mkinitcpio.d/linux.preset" <<'EOF'
# mkinitcpio preset file for the 'linux' package on an installed Developer OS system

ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default' 'fallback')

default_config="/etc/mkinitcpio.conf"
default_image="/boot/initramfs-linux.img"

fallback_config="/etc/mkinitcpio.conf"
fallback_image="/boot/initramfs-linux-fallback.img"
fallback_options="-S autodetect"
EOF

# Ensure the kernel is on the target ESP/boot (unpackfs may omit ISO boot files).
if [[ ! -f "${TARGET_ROOT}/boot/vmlinuz-linux" ]]; then
  for src in \
    /run/archiso/bootmnt/devos/boot/x86_64/vmlinuz-linux \
    /run/archiso/bootmnt/arch/boot/x86_64/vmlinuz-linux \
    /boot/vmlinuz-linux; do
    if [[ -f "${src}" ]]; then
      install -d "${TARGET_ROOT}/boot"
      cp -a "${src}" "${TARGET_ROOT}/boot/vmlinuz-linux"
      echo "[prepare-installed-mkinitcpio] Copied kernel from ${src}"
      break
    fi
  done
fi

if [[ ! -f "${TARGET_ROOT}/boot/vmlinuz-linux" ]]; then
  echo "[prepare-installed-mkinitcpio] ERROR: /boot/vmlinuz-linux missing on target." >&2
  exit 1
fi

# Remove live-only mkinitcpio hooks package if present (non-fatal if already gone).
run_pacman_remove() {
  if [[ "${TARGET_ROOT}" == "/" ]]; then
    pacman -Rns --noconfirm mkinitcpio-archiso "$@" 2>/dev/null || true
  elif command -v arch-chroot >/dev/null 2>&1; then
    arch-chroot "${TARGET_ROOT}" pacman -Rns --noconfirm mkinitcpio-archiso "$@" 2>/dev/null || true
  fi
}
run_pacman_remove

echo "[prepare-installed-mkinitcpio] Installed-system mkinitcpio preset ready under ${TARGET_ROOT}."
