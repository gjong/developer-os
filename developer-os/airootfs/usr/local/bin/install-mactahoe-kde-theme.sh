#!/usr/bin/env bash
# Install MacTahoe-kde + MacTahoe-icon-theme (vinceliuice GitHub) system-wide under /usr/share.
# Used from mkarchiso customize (chroot) and from developer-os-install (target root).
# With --rsync-from-live DEST: copy theme trees from this system's /usr into DEST (e.g. /mnt) when git is unavailable.

set -euo pipefail

MAC_KDE_REPO="${MAC_KDE_REPO:-https://github.com/vinceliuice/MacTahoe-kde.git}"
MAC_ICON_REPO="${MAC_ICON_REPO:-https://github.com/vinceliuice/MacTahoe-icon-theme.git}"

install_from_git() {
  command -v git >/dev/null 2>&1 || {
    echo "[install-mactahoe-kde-theme] ERROR: git not installed." >&2
    return 1
  }
  local tmp
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp}'" EXIT

  if ! git clone --depth 1 "${MAC_KDE_REPO}" "${tmp}/MacTahoe-kde"; then
    echo "[install-mactahoe-kde-theme] ERROR: git clone MacTahoe-kde failed." >&2
    trap - EXIT
    rm -rf "${tmp}"
    return 1
  fi
  (cd "${tmp}/MacTahoe-kde" && chmod +x install.sh && ./install.sh)

  set +e
  git clone --depth 1 "${MAC_ICON_REPO}" "${tmp}/MacTahoe-icon-theme"
  _ic=$?
  set -e
  if ((_ic == 0)); then
    (cd "${tmp}/MacTahoe-icon-theme" && chmod +x install.sh && ./install.sh)
  else
    echo "[install-mactahoe-kde-theme] WARNING: MacTahoe-icon-theme clone failed (${_ic}); icons/cursors may be missing." >&2
  fi

  trap - EXIT
  rm -rf "${tmp}"
  echo "[install-mactahoe-kde-theme] Installed from GitHub."
}

# Copy theme assets from the running (live) system into DEST (disk install target).
rsync_from_live() {
  local dest="${1:?destination root, e.g. /mnt}"
  dest="${dest%/}"
  local f

  shopt -s nullglob

  install -d "${dest}/usr/share/color-schemes" \
    "${dest}/usr/share/plasma/desktoptheme" \
    "${dest}/usr/share/plasma/look-and-feel" \
    "${dest}/usr/share/plasma/layout-templates" \
    "${dest}/usr/share/wallpapers" \
    "${dest}/usr/share/Kvantum" \
    "${dest}/usr/share/aurorae/themes" \
    "${dest}/usr/share/icons"

  for f in /usr/share/color-schemes/MacTahoe*.colors; do
    cp -a "$f" "${dest}/usr/share/color-schemes/"
  done
  for f in /usr/share/plasma/desktoptheme/MacTahoe-*; do
    cp -a "$f" "${dest}/usr/share/plasma/desktoptheme/"
  done
  for f in /usr/share/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-*; do
    cp -a "$f" "${dest}/usr/share/plasma/look-and-feel/"
  done
  for f in /usr/share/plasma/layout-templates/org.github.desktop.MacOS*; do
    cp -a "$f" "${dest}/usr/share/plasma/layout-templates/"
  done
  for f in /usr/share/wallpapers/MacTahoe*; do
    cp -a "$f" "${dest}/usr/share/wallpapers/"
  done
  if [[ -d /usr/share/Kvantum/MacTahoe ]]; then
    cp -a /usr/share/Kvantum/MacTahoe "${dest}/usr/share/Kvantum/"
  fi
  for f in /usr/share/aurorae/themes/MacTahoe*; do
    cp -a "$f" "${dest}/usr/share/aurorae/themes/"
  done
  for f in /usr/share/icons/MacTahoe*; do
    cp -a "$f" "${dest}/usr/share/icons/"
  done

  shopt -u nullglob
  if [[ ! -d "${dest}/usr/share/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-Light" ]]; then
    echo "[install-mactahoe-kde-theme] ERROR: --rsync-from-live found no MacTahoe files on the live system." >&2
    return 1
  fi
  echo "[install-mactahoe-kde-theme] Copied MacTahoe theme from live medium into ${dest}."
}

case "${1:-}" in
--rsync-from-live)
  rsync_from_live "${2:-}"
  ;;
-h | --help)
  echo "Usage: $0 | $0 --rsync-from-live /mnt" >&2
  exit 0
  ;;
*)
  install_from_git
  ;;
esac
