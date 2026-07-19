#!/usr/bin/env bash
#
# Developer OS — update apps installed outside pacman (and optionally the system).
# Updates: Flatpak apps, vfox (latest GitHub release), JetBrains Toolbox (latest),
# MacTahoe theme (git tip). Optionally runs pacman -Syu.
#
# Run as root for apply. Prefer: sudo developer-os-update
#
set -euo pipefail

DO_SYSTEM=1
CHECK_ONLY=0
EXTRAS_ONLY=0

usage() {
  cat <<'EOF'
Usage: developer-os-update [options]

Update Developer OS extras (and optionally Arch packages) to the latest versions.

Options:
  --check         Show installed vs latest versions; do not change anything
  --extras-only   Skip pacman -Syu (Flatpak + vfox + Toolbox + MacTahoe only)
  --system        Include pacman -Syu (default)
  -h, --help      Show this help

Examples:
  sudo developer-os-update
  sudo developer-os-update --extras-only
  developer-os-update --check
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      CHECK_ONLY=1
      ;;
    --extras-only)
      EXTRAS_ONLY=1
      DO_SYSTEM=0
      ;;
    --system)
      DO_SYSTEM=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if (( ! CHECK_ONLY )) && [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root (try: sudo developer-os-update)." >&2
  exit 1
fi

command -v curl >/dev/null 2>&1 || {
  echo "[update-extras] ERROR: curl is required." >&2
  exit 1
}

installed_vfox() {
  if [[ -f /usr/local/share/developer-os/vfox.version ]]; then
    tr -d '[:space:]' </usr/local/share/developer-os/vfox.version
    return 0
  fi
  if command -v vfox >/dev/null 2>&1; then
    # e.g. "vfox version 1.0.11"
    vfox --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1
    return 0
  fi
  printf 'none'
}

installed_toolbox() {
  if [[ -f /usr/local/share/developer-os/jetbrains-toolbox.version ]]; then
    tr -d '[:space:]' </usr/local/share/developer-os/jetbrains-toolbox.version
    return 0
  fi
  if [[ -x /opt/jetbrains-toolbox/bin/jetbrains-toolbox ]]; then
    printf 'present'
    return 0
  fi
  printf 'none'
}

resolve_latest_vfox() {
  local url tag
  url="$(curl -fsSL -o /dev/null -w '%{url_effective}' https://github.com/version-fox/vfox/releases/latest)"
  tag="${url##*/}"
  tag="${tag#v}"
  [[ -n "${tag}" && "${tag}" != "${url}" ]] || {
    echo "[update-extras] ERROR: could not resolve latest vfox release." >&2
    return 1
  }
  printf '%s\n' "${tag}"
}

resolve_latest_toolbox() {
  local json link name build
  json="$(curl -fsSL 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release')"
  link="$(printf '%s' "${json}" | grep -oE 'https://download\.jetbrains\.com/toolbox/jetbrains-toolbox-[0-9.]+\.tar\.gz' | head -n1 || true)"
  [[ -n "${link}" ]] || {
    echo "[update-extras] ERROR: could not resolve latest JetBrains Toolbox release." >&2
    return 1
  }
  name="${link##*/}"
  build="${name#jetbrains-toolbox-}"
  build="${build%.tar.gz}"
  printf '%s\n' "${build}"
}

echo "[update-extras] Resolving latest versions…"
LATEST_VFOX="$(resolve_latest_vfox)"
LATEST_TOOLBOX="$(resolve_latest_toolbox)"
CUR_VFOX="$(installed_vfox)"
CUR_TOOLBOX="$(installed_toolbox)"

echo "  vfox:              installed=${CUR_VFOX}  latest=${LATEST_VFOX}"
echo "  JetBrains Toolbox: installed=${CUR_TOOLBOX}  latest=${LATEST_TOOLBOX}"
if command -v flatpak >/dev/null 2>&1; then
  echo "  Flatpak:           $(flatpak --version 2>/dev/null | head -n1 || echo present)"
else
  echo "  Flatpak:           not installed"
fi

if (( CHECK_ONLY )); then
  echo "[update-extras] Check only; no changes made."
  exit 0
fi

status=0

if (( DO_SYSTEM )) && (( ! EXTRAS_ONLY )); then
  echo "[update-extras] Updating Arch packages (pacman -Syu)…"
  set +e
  pacman -Syu --noconfirm
  _pm=$?
  set -e
  if ((_pm != 0)); then
    echo "[update-extras] WARNING: pacman -Syu failed (${_pm})." >&2
    status=1
  fi
fi

if command -v flatpak >/dev/null 2>&1; then
  echo "[update-extras] Updating Flatpak apps…"
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
  set +e
  flatpak update -y --system
  _fp=$?
  set -e
  if ((_fp != 0)); then
    echo "[update-extras] WARNING: flatpak update failed (${_fp})." >&2
    status=1
  fi
else
  echo "[update-extras] WARNING: flatpak not installed; skipping Flatpak updates." >&2
fi

if [[ ! -x /usr/local/share/developer-os/install-extras.sh ]]; then
  echo "[update-extras] ERROR: install-extras.sh missing; cannot refresh vfox/Toolbox/MacTahoe." >&2
  exit 1
fi

echo "[update-extras] Refreshing vfox ${LATEST_VFOX}, JetBrains Toolbox ${LATEST_TOOLBOX}, and MacTahoe…"
set +e
env VFOX_VERSION="${LATEST_VFOX}" TOOLBOX_BUILD="${LATEST_TOOLBOX}" \
  /usr/local/share/developer-os/install-extras.sh
_ex=$?
set -e
if ((_ex != 0)); then
  echo "[update-extras] WARNING: install-extras.sh exited ${_ex}." >&2
  status=1
fi

if (( status == 0 )); then
  echo "[update-extras] Done."
else
  echo "[update-extras] Finished with warnings (see above)." >&2
fi
exit "${status}"
