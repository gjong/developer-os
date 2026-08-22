#!/usr/bin/env bash
# Install / validate the first-party Developer OS Plasma theme.
# Used from install-extras.sh (live + disk), developer-os-install, and mkarchiso customize.
# With --rsync-from-live DEST: copy theme trees from this system's /usr into DEST (e.g. /mnt).
# With --with-mac-icons: optionally clone MacTahoe-icon-theme from GitHub.
#
set -euo pipefail

MAC_ICON_REPO="${MAC_ICON_REPO:-https://github.com/vinceliuice/MacTahoe-icon-theme.git}"

THEME_LNF_DARK=/usr/share/plasma/look-and-feel/com.developeros.plasma.dark
THEME_LNF_LIGHT=/usr/share/plasma/look-and-feel/com.developeros.plasma.light

install_mac_icons() {
  command -v git >/dev/null 2>&1 || {
    echo "[install-developer-os-theme] WARNING: git not installed; cannot fetch MacTahoe icons." >&2
    return 1
  }
  local tmp
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '${tmp}'" EXIT

  set +e
  git clone --depth 1 "${MAC_ICON_REPO}" "${tmp}/MacTahoe-icon-theme"
  _ic=$?
  set -e
  if ((_ic == 0)); then
    (cd "${tmp}/MacTahoe-icon-theme" && chmod +x install.sh && ./install.sh)
    echo "[install-developer-os-theme] MacTahoe icon theme installed."
  else
    echo "[install-developer-os-theme] WARNING: MacTahoe-icon-theme clone failed (${_ic})." >&2
  fi

  trap - EXIT
  rm -rf "${tmp}"
}

refresh_caches() {
  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    for d in /usr/share/icons/hicolor /usr/share/icons/Papirus /usr/share/icons/Papirus-Dark /usr/share/icons/Papirus-Light /usr/share/icons/MacTahoe-dark /usr/share/icons/MacTahoe-light; do
      [[ -d "${d}" ]] && gtk-update-icon-cache -f "${d}" >/dev/null 2>&1 || true
    done
  fi
  if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
  fi
}

validate_theme() {
  if [[ ! -d "${THEME_LNF_DARK}" && ! -d "${THEME_LNF_LIGHT}" ]]; then
    echo "[install-developer-os-theme] ERROR: Developer OS look-and-feel missing under /usr/share/plasma/look-and-feel." >&2
    return 1
  fi
  if [[ ! -f /usr/share/color-schemes/DeveloperOSDark.colors \
        && ! -f /usr/share/color-schemes/DeveloperOSLight.colors ]]; then
    echo "[install-developer-os-theme] ERROR: Developer OS color schemes missing." >&2
    return 1
  fi
  if [[ -x /usr/local/share/developer-os/strip-plasma-showdesktop.sh ]]; then
    /usr/local/share/developer-os/strip-plasma-showdesktop.sh /
  fi
  refresh_caches
  echo "[install-developer-os-theme] First-party theme is present under /usr/share."
}

rsync_from_live() {
  local dest="${1:?destination root, e.g. /mnt}"
  dest="${dest%/}"
  local f

  shopt -s nullglob

  install -d "${dest}/usr/share/color-schemes" \
    "${dest}/usr/share/plasma/desktoptheme" \
    "${dest}/usr/share/plasma/look-and-feel" \
    "${dest}/usr/share/wallpapers" \
    "${dest}/usr/share/aurorae/themes" \
    "${dest}/usr/share/sddm/themes" \
    "${dest}/usr/share/icons" \
    "${dest}/usr/share/konsole" \
    "${dest}/etc/sddm.conf.d"

  for f in /usr/share/color-schemes/DeveloperOS*.colors; do
    cp -a "$f" "${dest}/usr/share/color-schemes/"
  done
  for f in /usr/share/plasma/desktoptheme/DeveloperOS-*; do
    cp -a "$f" "${dest}/usr/share/plasma/desktoptheme/"
  done
  for f in /usr/share/plasma/look-and-feel/com.developeros.plasma.*; do
    cp -a "$f" "${dest}/usr/share/plasma/look-and-feel/"
  done
  if [[ -d /usr/share/wallpapers/DeveloperOS ]]; then
    cp -a /usr/share/wallpapers/DeveloperOS "${dest}/usr/share/wallpapers/"
  fi
  for f in /usr/share/aurorae/themes/DeveloperOS-*; do
    cp -a "$f" "${dest}/usr/share/aurorae/themes/"
  done
  if [[ -d /usr/share/sddm/themes/developer-os ]]; then
    cp -a /usr/share/sddm/themes/developer-os "${dest}/usr/share/sddm/themes/"
  fi
  if [[ -f /etc/sddm.conf.d/10-theme.conf ]]; then
    cp -a /etc/sddm.conf.d/10-theme.conf "${dest}/etc/sddm.conf.d/"
  fi
  if [[ -f /usr/share/konsole/DeveloperOS.colorscheme ]]; then
    cp -a /usr/share/konsole/DeveloperOS.colorscheme "${dest}/usr/share/konsole/"
  fi
  if [[ -f /usr/share/icons/hicolor/scalable/apps/developer-os-launcher.svg ]]; then
    install -d "${dest}/usr/share/icons/hicolor/scalable/apps"
    cp -a /usr/share/icons/hicolor/scalable/apps/developer-os-launcher.svg \
      "${dest}/usr/share/icons/hicolor/scalable/apps/"
  fi
  for f in /usr/share/icons/MacTahoe*; do
    cp -a "$f" "${dest}/usr/share/icons/"
  done

  shopt -u nullglob
  if [[ ! -d "${dest}/usr/share/plasma/look-and-feel/com.developeros.plasma.dark" \
        && ! -d "${dest}/usr/share/plasma/look-and-feel/com.developeros.plasma.light" ]]; then
    echo "[install-developer-os-theme] ERROR: --rsync-from-live found no Developer OS look-and-feel on the live system." >&2
    return 1
  fi

  if [[ -x /usr/local/share/developer-os/strip-plasma-showdesktop.sh ]]; then
    /usr/local/share/developer-os/strip-plasma-showdesktop.sh "${dest}"
  fi

  echo "[install-developer-os-theme] Copied Developer OS theme from live medium into ${dest}."
}

WITH_MAC_ICONS=0
ACTION=validate
DEST=""

while [[ $# -gt 0 ]]; do
  case "${1}" in
    --rsync-from-live)
      ACTION=rsync
      DEST="${2:-}"
      shift
      ;;
    --with-mac-icons)
      WITH_MAC_ICONS=1
      ;;
    -h | --help)
      echo "Usage: $0 [--with-mac-icons] | $0 --rsync-from-live /mnt [--with-mac-icons]" >&2
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

case "${ACTION}" in
  rsync)
    rsync_from_live "${DEST}"
    ;;
  *)
    validate_theme
    ;;
esac

if (( WITH_MAC_ICONS )); then
  set +e
  install_mac_icons
  set -e
fi
