cd developer-os
docker run --rm --privileged \
  -e SOURCE_DATE_EPOCH="$(git log -1 --format=%ct 2>/dev/null || date +%s)" \
  -e WORK=/tmp/work \
  -v "$PWD:/profile" -w /profile \
  archlinux:latest bash -lc '
    set -euo pipefail
    pacman-key --init
    pacman-key --populate archlinux
    pacman -Sy --needed --noconfirm archiso arch-install-scripts sudo
    ./build.sh
  '