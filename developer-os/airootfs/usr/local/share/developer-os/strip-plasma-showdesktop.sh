#!/usr/bin/env bash
#
# Remove Plasma "Peek at Desktop" (org.kde.plasma.showdesktop) from panel layout
# templates and optional user appletsrc so it does not appear on the application bar.
#
# Usage:
#   strip-plasma-showdesktop.sh [ROOT]
#   strip-plasma-showdesktop.sh --appletsrc PATH
#
set -euo pipefail

strip_layouts() {
  local root="${1:-/}"
  root="${root%/}"
  [[ -z "${root}" ]] && root="/"

  local f count=0
  shopt -s nullglob
  for f in \
    "${root}/usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/layout.js" \
    "${root}/usr/share/plasma/layout-templates/org.github.desktop.MacOSPanel/contents/layout.js" \
    "${root}/usr/share/plasma/look-and-feel/"*/contents/layouts/org.kde.plasma.desktop-layout.js; do
    [[ -f "${f}" ]] || continue
    if grep -q 'org\.kde\.plasma\.showdesktop' "${f}"; then
      sed -i '/org\.kde\.plasma\.showdesktop/d' "${f}"
      echo "[strip-plasma-showdesktop] Removed showdesktop from ${f}"
      count=$((count + 1))
    fi
  done
  shopt -u nullglob

  if ((count == 0)); then
    echo "[strip-plasma-showdesktop] No showdesktop layout entries found under ${root}."
  fi
}

strip_appletsrc() {
  local appletsrc="${1:?path to plasma-org.kde.plasma.desktop-appletsrc}"
  [[ -f "${appletsrc}" ]] || return 0
  if ! grep -q 'org\.kde\.plasma\.showdesktop' "${appletsrc}"; then
    return 0
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "[strip-plasma-showdesktop] WARNING: python3 missing; cannot scrub ${appletsrc}." >&2
    return 0
  fi

  python3 - "${appletsrc}" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()

# Map containment id -> applet ids that are Peek at Desktop.
showdesktop = {}
for m in re.finditer(
    r"^\[Containments\]\[(\d+)\]\[Applets\]\[(\d+)\]\s*$", text, re.M
):
    cont, applet = m.group(1), m.group(2)
    start = m.end()
    nxt = re.search(r"^\[", text[start:], re.M)
    end = start + nxt.start() if nxt else len(text)
    body = text[start:end]
    if re.search(r"^plugin=org\.kde\.plasma\.showdesktop\s*$", body, re.M):
        showdesktop.setdefault(cont, set()).add(applet)

if not showdesktop:
    sys.exit(0)

out = []
skip = False
current_cont = None
for line in text.splitlines(keepends=True):
    header = re.match(r"^\[Containments\]\[(\d+)\]", line)
    if header:
        current_cont = header.group(1)

    applet_hdr = re.match(
        r"^\[Containments\]\[(\d+)\]\[Applets\]\[(\d+)\]\s*$", line
    )
    if applet_hdr and applet_hdr.group(2) in showdesktop.get(
        applet_hdr.group(1), set()
    ):
        skip = True
        continue

    if skip:
        if line.startswith("["):
            skip = False
        else:
            continue

    if line.startswith("AppletOrder=") and current_cont in showdesktop:
        raw = line.split("=", 1)[1].strip()
        keep = [
            p
            for p in raw.split(";")
            if p and p not in showdesktop[current_cont]
        ]
        nl = "\n" if line.endswith("\n") else ""
        line = "AppletOrder=" + ";".join(keep) + nl

    out.append(line)

path.write_text("".join(out))
print(f"[strip-plasma-showdesktop] Scrubbed showdesktop from {path}")
PY
}

case "${1:-}" in
--appletsrc)
  strip_appletsrc "${2:?appletsrc path}"
  ;;
-h | --help)
  echo "Usage: $0 [ROOT] | $0 --appletsrc PATH" >&2
  exit 0
  ;;
*)
  strip_layouts "${1:-/}"
  ;;
esac
