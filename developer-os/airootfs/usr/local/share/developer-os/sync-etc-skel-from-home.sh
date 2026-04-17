#!/usr/bin/env bash
#
# Populate /etc/skel from a reference home so "useradd -m newuser" matches Developer OS / liveuser.
# Usage: sync-etc-skel-from-home.sh SOURCE_HOME TARGET_ROOT
#   SOURCE_HOME  e.g. /home/liveuser or /mnt/home/developer
#   TARGET_ROOT  e.g. / or /mnt  (creates TARGET_ROOT/etc/skel)
#
set -euo pipefail

[[ "$(id -u)" -eq 0 ]] || { echo "Run as root." >&2; exit 1; }

src_home="${1:?source home directory}"
target_root="${2:?target filesystem root}"
target_root="${target_root%/}"
skel="${target_root}/etc/skel"

[[ -d "${src_home}" ]] || {
  echo "[sync-etc-skel] Not a directory: ${src_home}" >&2
  exit 1
}

install -d -m 0755 "${skel}"

for f in .zshrc .zprofile .bash_profile .bash_logout .bashrc; do
  if [[ -f "${src_home}/${f}" ]]; then
    install -m 0644 "${src_home}/${f}" "${skel}/${f}"
  fi
done

if [[ -d "${src_home}/.config" ]]; then
  install -d -m 0755 "${skel}/.config"
  rsync -a --delete --exclude='.cache' "${src_home}/.config/" "${skel}/.config/"
fi

install -d -m 0755 "${skel}/Pictures"

chown -R root:root "${skel}"
chmod -R go+rX "${skel}"

echo "[sync-etc-skel] Updated ${skel} from ${src_home}."
