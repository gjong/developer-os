# ADR-0009: Ship vfox from pinned GitHub release tarball

## Status

Accepted

## Context

**vfox** ([version-fox/vfox](https://github.com/version-fox/vfox)) is a cross-runtime version manager. It is **not** in Arch Linux `[core]/[extra]`, only the **AUR**. Official **prebuilt** `linux_x86_64.tar.gz` assets ship on GitHub releases with `checksums.txt`.

## Decision

1. Add **`curl`** to `packages.x86_64` (used by shared install helpers; also generally useful).
2. In **`install-extras.sh`**, download **`checksums.txt`** and the pinned **`vfox_<ver>_linux_x86_64.tar.gz`**, verify with **`sha256sum -c`**, install **`vfox`** to **`/usr/local/bin/vfox`**, and install **bash** and **zsh** completions under **`/usr/local/share/...`**.
3. In **`~/.zshrc`**, **`eval "$(vfox activate zsh)"`** when `vfox` is on `PATH`.

Version is pinned as **`VFOX_VERSION`** (default in `install-extras.sh`); bump when upgrading the image. Override **`VFOX_VERSION`** to install another release (used by **`developer-os-update`** / [ADR-0013](0013-post-install-app-updates.md)). The live image runs this helper from **`customize.sh`**, and GUI/CLI disk installs use the same helper through the shared installed-profile flow.

## Consequences

**Positive:** Works in `pacstrap` without AUR helpers; checksum-verified; matches our x86_64 ISO only.

**Negative / trade-offs:** Requires **network** during `mkarchiso` customize (same class as Flatpak remote setup). Other arches would need different tarball names.

**Follow-up:** If vfox enters `[extra]`, prefer `pacman -S vfox` and drop the script. Shared plugin/SDK layout is [ADR-0014](0014-runtime-bootstrap.md).
