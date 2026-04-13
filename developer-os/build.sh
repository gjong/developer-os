#!/usr/bin/env bash
# Wrapper for mkarchiso. Run on Arch Linux (or in the archlinux container used in CI).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if ! command -v mkarchiso >/dev/null 2>&1; then
  echo "mkarchiso not found. Install the 'archiso' package on Arch Linux, or build inside:" >&2
  echo "  docker run --rm -it -v \"\$PWD:/profile\" archlinux:latest bash" >&2
  exit 1
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck source=/dev/null
  . /etc/os-release
  if [[ "${ID:-}" != "arch" ]]; then
    echo "This script expects an Arch Linux environment (found ID=${ID:-unknown})." >&2
    echo "Use Docker: docker run --privileged --rm -v \"\$PWD:/profile\" -w /profile archlinux:latest ./build.sh" >&2
    exit 1
  fi
else
  echo "Cannot read /etc/os-release; refusing to run." >&2
  exit 1
fi

OUT="${OUT:-$ROOT/out}"
WORK="${WORK:-$ROOT/work}"

mkdir -p "$OUT" "$WORK"

echo "Profile:  $ROOT"
echo "Output:   $OUT"
echo "Work dir: $WORK"
echo

exec mkarchiso -v -w "$WORK" -o "$OUT" "$ROOT"
