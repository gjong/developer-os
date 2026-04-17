# ADR-0009: Ship vfox from pinned GitHub release tarball

## Status

Accepted

## Context

**vfox** ([version-fox/vfox](https://github.com/version-fox/vfox)) is a cross-runtime version manager. It is **not** in Arch Linux `[core]/[extra]`, only the **AUR**. Official **prebuilt** `linux_x86_64.tar.gz` assets ship on GitHub releases with `checksums.txt`.

## Decision

1. Add **`curl`** to `packages.x86_64` (used only for this download in `customize.sh`; also generally useful).
2. In **`customize.sh`**, download **`checksums.txt`** and the pinned **`vfox_<ver>_linux_x86_64.tar.gz`**, verify with **`sha256sum -c`**, install **`vfox`** to **`/usr/local/bin/vfox`**, and install **bash** and **zsh** completions under **`/usr/local/share/...`**.
3. In **`~/.zshrc`**, **`eval "$(vfox activate zsh)"`** when `vfox` is on `PATH`.

Version is pinned as **`VFOX_VERSION`** in `customize.sh`; bump when upgrading the image.

## Consequences

**Positive:** Works in `pacstrap` without AUR helpers; checksum-verified; matches our x86_64 ISO only.

**Negative / trade-offs:** Requires **network** during `mkarchiso` customize (same class as Flatpak remote setup). Other arches would need different tarball names.

**Follow-up:** If vfox enters `[extra]`, prefer `pacman -S vfox` and drop the script.
