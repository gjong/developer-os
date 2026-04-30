#!/usr/bin/env bash
#
# Seed Plasma user config for MacTahoe (matches MacTahoe-kde look-and-feel defaults + wallpaper).
# Run as root. Usage: seed-plasma-mactahoe.sh USERNAME
# Expects MacTahoe installed under /usr/share (install-mactahoe-kde-theme.sh -c dark installs …MacTahoe-Dark).
#
set -euo pipefail

[[ "$(id -u)" -eq 0 ]] || { echo "Run as root." >&2; exit 1; }

user="${1:?login name}"
home=$(getent passwd "$user" | cut -d: -f6)
[[ -n "${home}" && -d "${home}" ]] || {
  echo "[seed-plasma-mactahoe] No home for user: ${user}" >&2
  exit 1
}

if [[ ! -d /usr/share/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-Dark \
      && ! -d /usr/share/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-Light ]]; then
  echo "[seed-plasma-mactahoe] MacTahoe look-and-feel not found under /usr/share; skipping." >&2
  exit 0
fi

LNF_ID=com.github.vinceliuice.MacTahoe-Dark
if [[ ! -d "/usr/share/plasma/look-and-feel/${LNF_ID}" ]]; then
  LNF_ID=com.github.vinceliuice.MacTahoe-Light
fi

if [[ "${LNF_ID}" == *Dark ]]; then
  _colorscheme='MacTahoeDark'
  _desktop='MacTahoe-Dark'
  _aurorae='__aurorae__svg__MacTahoe-Dark'
  _icons='MacTahoe-dark'
  _cursor='MacTahoe-dark'
  _widget='kvantum-dark'
else
  _colorscheme='MacTahoeLight'
  _desktop='MacTahoe-Light'
  _aurorae='__aurorae__svg__MacTahoe-Light'
  _icons='MacTahoe-light'
  _cursor='MacTahoe-light'
  _widget='kvantum'
fi

_resolve_wallpaper() {
  local f
  shopt -s nullglob
  for f in \
    /usr/share/wallpapers/MacTahoe-Dark/contents/images/*.{jpeg,jpg,JPEG,JPG,png,PNG} \
    /usr/share/wallpapers/MacTahoe/contents/images/*.{jpeg,jpg,JPEG,JPG,png,PNG} \
    /usr/share/wallpapers/MacTahoe-Light/contents/images/*.{jpeg,jpg,JPEG,JPG,png,PNG}; do
    if [[ -f "$f" ]]; then
      printf '%s' "$f"
      shopt -u nullglob
      return 0
    fi
  done
  for f in /usr/share/wallpapers/*/contents/images/*.{jpeg,jpg,JPEG,JPG,png,PNG}; do
    if [[ -f "$f" ]]; then
      printf '%s' "$f"
      shopt -u nullglob
      return 0
    fi
  done
  shopt -u nullglob
  return 1
}

_wallpaper_path="$(_resolve_wallpaper)" || _wallpaper_path=''
if [[ -z "${_wallpaper_path}" ]]; then
  echo "[seed-plasma-mactahoe] WARNING: No wallpaper image found under /usr/share/wallpapers." >&2
fi

install -d -m 0755 -o "${user}" -g "${user}" "${home}/.config/Kvantum"

_tmp="$(mktemp)"
trap 'rm -f "${_tmp}"' EXIT

if command -v plasma-apply-lookandfeel &>/dev/null; then
  _uid="$(id -u "${user}" 2>/dev/null || true)"
  if [[ -n "${_uid}" ]]; then
    install -d -m 0700 -o "${user}" -g "${user}" "/run/user/${_uid}" 2>/dev/null || true
    set +e
    runuser -u "${user}" -- env \
      HOME="${home}" \
      XDG_RUNTIME_DIR="/run/user/${_uid}" \
      plasma-apply-lookandfeel --apply "${LNF_ID}" --platform offscreen
    set -e
  fi
fi

cat >"${_tmp}" <<EOF
[KDE]
LookAndFeelPackage=${LNF_ID}
widgetStyle=${_widget}

[General]
ColorScheme=${_colorscheme}

[Icons]
Theme=${_icons}
EOF
install -m 0644 -o "${user}" -g "${user}" "${_tmp}" "${home}/.config/kdeglobals"

cat >"${_tmp}" <<EOF
[Theme]
name=${_desktop}
EOF
install -m 0644 -o "${user}" -g "${user}" "${_tmp}" "${home}/.config/plasmarc"

cat >"${_tmp}" <<EOF
[DesktopSwitcher]
LayoutName=org.kde.breeze.desktop

[WindowSwitcher]
LayoutName=org.kde.breeze.desktop

[org.kde.kdecoration2]
ButtonsOnLeft=XAI
ButtonsOnRight=
library=org.kde.kwin.aurorae
theme=${_aurorae}
EOF
install -m 0644 -o "${user}" -g "${user}" "${_tmp}" "${home}/.config/kwinrc"

cat >"${_tmp}" <<EOF
[Mouse]
cursorTheme=${_cursor}
EOF
install -m 0644 -o "${user}" -g "${user}" "${_tmp}" "${home}/.config/kcminputrc"

cat >"${_tmp}" <<'EOF'
[General]
theme=MacTahoe
EOF
install -m 0644 -o "${user}" -g "${user}" "${_tmp}" "${home}/.config/Kvantum/kvantum.kvconfig"

if [[ -n "${_wallpaper_path}" ]]; then
  _img_url="file://${_wallpaper_path}"
  cat >"${_tmp}" <<EOF
[Containments][1]
activityId=
formfactor=0
immutability=1
lastScreen=0
location=0
plugin=org.kde.plasma.folder
wallpaperplugin=org.kde.image

[Containments][1][Wallpaper][org.kde.image][General]
Image=${_img_url}
SlidePaths=/usr/share/wallpapers
EOF
  install -m 0644 -o "${user}" -g "${user}" "${_tmp}" "${home}/.config/plasma-org.kde.plasma.desktop-appletsrc"
fi

trap - EXIT
rm -f "${_tmp}"

echo "[seed-plasma-mactahoe] Seeded Plasma for ${user} (${LNF_ID})."
