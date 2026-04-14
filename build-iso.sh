#!/bin/bash

docker build -t developer-os-iso-builder -f docker/Dockerfile.ci ./docker

mdir -p ~/.cache/pacman/pkg

cd developer-os
docker run --rm --privileged \
  -e SOURCE_DATE_EPOCH="$(git log -1 --format=%ct 2>/dev/null || date +%s)" \
  -e WORK=/tmp/work \
  -v "$PWD:/profile" -w /profile \
  -v "$HOME/.cache/pacman/pkg:/var/cache/pacman/pkg:rw" \
  developer-os-iso-builder bash -lc '
    set -euo pipefail
    ./build.sh
  '