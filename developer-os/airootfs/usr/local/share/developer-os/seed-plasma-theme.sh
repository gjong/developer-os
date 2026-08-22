#!/usr/bin/env bash
#
# Seed Plasma user config for the first-party Developer OS look-and-feel.
# Run as root. Usage: seed-plasma-theme.sh USERNAME
#
set -euo pipefail

[[ "$(id -u)" -eq 0 ]] || { echo "Run as root." >&2; exit 1; }

user="${1:?login name}"
home=$(getent passwd "$user" | cut -d: -f6)
[[ -n "${home}" && -d "${home}" ]] || {
  echo "[seed-plasma-theme] No home for user: ${user}" >&2
  exit 1
}

if [[ -x /usr/local/share/developer-os/strip-plasma-showdesktop.sh ]]; then
  /usr/local/share/developer-os/strip-plasma-showdesktop.sh /
fi

if [[ ! -d /usr/share/plasma/look-and-feel/com.developeros.plasma.dark \
      && ! -d /usr/share/plasma/look-and-feel/com.developeros.plasma.light ]]; then
  echo "[seed-plasma-theme] Developer OS look-and-feel not found under /usr/share; skipping." >&2
  exit 0
fi

LNF_ID=com.developeros.plasma.dark
if [[ ! -d "/usr/share/plasma/look-and-feel/${LNF_ID}" ]]; then
  LNF_ID=com.developeros.plasma.light
fi

if [[ "${LNF_ID}" == *dark ]]; then
  _colorscheme='DeveloperOSDark'
  _desktop='DeveloperOS-Dark'
  _aurorae='__aurorae__svg__DeveloperOS-Dark'
  _icons='Papirus-Dark'
  _gtk_prefer_dark='true'
else
  _colorscheme='DeveloperOSLight'
  _desktop='DeveloperOS-Light'
  _aurorae='__aurorae__svg__DeveloperOS-Light'
  _icons='Papirus-Light'
  _gtk_prefer_dark='false'
fi
_cursor='breeze_cursors'
_widget='Breeze'

_resolve_wallpaper() {
  local f
  shopt -s nullglob
  for f in \
    /usr/share/wallpapers/DeveloperOS/contents/images/*.{jpeg,jpg,JPEG,JPG,png,PNG} \
    /usr/share/wallpapers/DeveloperOS/contents/images_dark/*.{jpeg,jpg,JPEG,JPG,png,PNG}; do
    if [[ -f "$f" ]]; then
      printf '%s' "$f"
      shopt -u nullglob
      return 0
    fi
  done
  if [[ -f /usr/share/wallpapers/wallpaper.png ]]; then
    printf '%s' /usr/share/wallpapers/wallpaper.png
    shopt -u nullglob
    return 0
  fi
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
  echo "[seed-plasma-theme] WARNING: No wallpaper image found under /usr/share/wallpapers." >&2
fi

install -d -m 0755 -o "${user}" -g "${user}" \
  "${home}/.config" \
  "${home}/.config/gtk-3.0" \
  "${home}/.config/gtk-4.0"

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
fixed=JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
font=Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
menuFont=Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
smallestReadableFont=Inter,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1
toolBarFont=Inter,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

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
[Desktops]
Number=4
Rows=1
Name_1=Code
Name_2=Web
Name_3=Comms
Name_4=Ops

[Effect-blur]
BlurStrength=8
NoiseStrength=0

[Plugins]
blurEnabled=true

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
[kwin]
_k_friendly_name=KWin
Switch to Desktop 1=Meta+1,none,Switch to Desktop 1
Switch to Desktop 2=Meta+2,none,Switch to Desktop 2
Switch to Desktop 3=Meta+3,none,Switch to Desktop 3
Switch to Desktop 4=Meta+4,none,Switch to Desktop 4
Window Quick Tile Left=Meta+Left,none,Quick Tile Window to the Left
Window Quick Tile Right=Meta+Right,none,Quick Tile Window to the Right
Window Quick Tile Top=Meta+Up,none,Quick Tile Window to the Top
Window Quick Tile Bottom=Meta+Down,none,Quick Tile Window to the Bottom
Window Quick Tile Top Left=Meta+Alt+Left,none,Quick Tile Window to the Top Left
Window Quick Tile Top Right=Meta+Alt+Right,none,Quick Tile Window to the Top Right
Window Quick Tile Bottom Left=Meta+Alt+Down,none,Quick Tile Window to the Bottom Left
Window Quick Tile Bottom Right=Meta+Ctrl+Down,none,Quick Tile Window to the Bottom Right
Window Maximize=Meta+PgUp,none,Maximize Window

[org.kde.krunner.desktop]
_k_friendly_name=KRunner
_launch=Meta+Space\tAlt+Space\tAlt+F2,Alt+Space\tAlt+F2\tSearch,KRunner
EOF
install -m 0644 -o "${user}" -g "${user}" "${_tmp}" "${home}/.config/kglobalshortcutsrc"

cat >"${_tmp}" <<EOF
[Settings]
gtk-theme-name=Breeze
gtk-icon-theme-name=${_icons}
gtk-font-name=Inter 10
gtk-application-prefer-dark-theme=${_gtk_prefer_dark}
gtk-cursor-theme-name=${_cursor}
EOF
install -m 0644 -o "${user}" -g "${user}" "${_tmp}" "${home}/.config/gtk-3.0/settings.ini"
install -m 0644 -o "${user}" -g "${user}" "${_tmp}" "${home}/.config/gtk-4.0/settings.ini"

if [[ -n "${_wallpaper_path}" ]]; then
  if [[ -d /usr/share/wallpapers/DeveloperOS ]]; then
    _img_url="file:///usr/share/wallpapers/DeveloperOS"
  else
    _img_url="file://${_wallpaper_path}"
  fi

  _appletsrc="${home}/.config/plasma-org.kde.plasma.desktop-appletsrc"
  _uid="$(id -u "${user}" 2>/dev/null || true)"
  _applied=0

  if [[ -n "${_uid}" ]] && command -v plasma-apply-wallpaperimage &>/dev/null; then
    install -d -m 0700 -o "${user}" -g "${user}" "/run/user/${_uid}" 2>/dev/null || true
    set +e
    runuser -u "${user}" -- env \
      HOME="${home}" \
      XDG_RUNTIME_DIR="/run/user/${_uid}" \
      plasma-apply-wallpaperimage "${_wallpaper_path}"
    _pw=$?
    set -e
    if ((_pw == 0)); then
      _applied=1
    fi
  fi

  if ((_applied == 0)); then
    if [[ -f "${_appletsrc}" ]] && grep -q 'org.kde.image' "${_appletsrc}"; then
      sed -i -E \
        "s|^Image=.*$|Image=${_img_url}|g; s|^PreviewImage=.*$|PreviewImage=${_img_url}|g" \
        "${_appletsrc}"
      chown "${user}:${user}" "${_appletsrc}"
    else
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
PreviewImage=${_img_url}
SlidePaths=/usr/share/wallpapers
EOF
      install -m 0644 -o "${user}" -g "${user}" "${_tmp}" "${_appletsrc}"
    fi
  fi
fi

if [[ -x /usr/local/share/developer-os/strip-plasma-showdesktop.sh ]]; then
  /usr/local/share/developer-os/strip-plasma-showdesktop.sh --appletsrc \
    "${home}/.config/plasma-org.kde.plasma.desktop-appletsrc"
fi

trap - EXIT
rm -f "${_tmp}"

echo "[seed-plasma-theme] Seeded Plasma for ${user} (${LNF_ID})."
