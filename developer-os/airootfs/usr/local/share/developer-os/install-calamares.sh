#!/usr/bin/env bash
#
# Developer OS — install Calamares into the live image.
# Calamares is distributed through AUR for Arch, so it cannot be listed in
# packages.x86_64 where mkarchiso only resolves enabled pacman repositories.
#
set -euo pipefail

[[ "$(id -u)" -eq 0 ]] || { echo "Run as root." >&2; exit 1; }

if command -v calamares >/dev/null 2>&1; then
  echo "[install-calamares] Calamares already installed."
  exit 0
fi

if ! command -v makepkg >/dev/null 2>&1; then
  echo "[install-calamares] ERROR: makepkg is missing; install base-devel first." >&2
  exit 1
fi

repo_deps=(
  kpmcore
  yaml-cpp
  libpwquality
  cmake
  ninja
  extra-cmake-modules
)

# mkarchiso workspace can be space-constrained; keep pacman cache small first.
pacman -Scc --noconfirm >/dev/null 2>&1 || true

echo "[install-calamares] Installing repository/build dependencies..."
pacman -Sy --needed --noconfirm "${repo_deps[@]}"

build_user="aurbuild"
build_home="/var/tmp/${build_user}"
build_dir="${build_home}/calamares"
sudoers_tmp="/etc/sudoers.d/90-calamares-build"
pacman_conf="/etc/pacman.conf"
pacman_conf_backup="/tmp/pacman.conf.calamares.bak"

cleanup() {
  rm -f "${sudoers_tmp}"
  rm -rf "${build_dir}"
  if [[ -f "${pacman_conf_backup}" ]]; then
    mv -f "${pacman_conf_backup}" "${pacman_conf}"
  fi
}
trap cleanup EXIT

if ! id -u "${build_user}" >/dev/null 2>&1; then
  useradd -m -d "${build_home}" -s /bin/bash "${build_user}"
fi

install -d -o "${build_user}" -g "${build_user}" "${build_home}"
rm -rf "${build_dir}"

sudo -u "${build_user}" git clone --depth=1 https://aur.archlinux.org/calamares.git "${build_dir}"

# makepkg needs pacman privileges for dependencies and package installation.
printf '%s ALL=(ALL:ALL) NOPASSWD: /usr/bin/pacman\n' "${build_user}" >"${sudoers_tmp}"
chmod 0440 "${sudoers_tmp}"

# mkarchiso chroot can confuse pacman's CheckSpace mountpoint check.
cp "${pacman_conf}" "${pacman_conf_backup}"
sed -i 's/^[[:space:]]*CheckSpace/#CheckSpace/' "${pacman_conf}"

sudo -u "${build_user}" bash -lc "cd '${build_dir}' && makepkg -si --needed --noconfirm --rmdeps"

echo "[install-calamares] Calamares installed."
