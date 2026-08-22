# ADR-0013: User-facing updates for post-install extras

## Status

Accepted

## Context

Disk install (Calamares / `developer-os-install`) applies **`install-extras.sh`**: Flathub + Brave Flatpak, and pinned **vfox** and **JetBrains Toolbox** tarballs. The first-party Plasma theme is vendored (see [ADR-0016](0016-first-party-plasma-theme.md)) and is not refreshed from Git. Official packages stay on **pacman**; Flatpaks and the pinned GitHub/JetBrains binaries do not update themselves when the user later runs a normal Arch upgrade.

Users need a single, documented way to refresh those extras to upstream latest after the OS is installed.

## Decision

1. Keep **ISO-build pins** in `install-extras.sh` (via default env values) for reproducible images.
2. Allow **`VFOX_VERSION`** / **`TOOLBOX_BUILD`** overrides so the same installer can install newer releases.
3. Ship **`update-extras.sh`** plus **`developer-os-update`**: resolve latest vfox (GitHub `releases/latest`) and Toolbox (JetBrains TBA products API), run **`flatpak update`**, re-run **`install-extras.sh`** with those versions, and by default also **`pacman -Syu`**.
4. Expose **`--check`** (no root) and **`--extras-only`**, plus a Plasma **Update Developer OS apps** desktop entry that opens Kitty.

## Consequences

**Positive:** One command after install; Flatpak + binary extras + optional full system update; ISO pins unchanged until the image is rebuilt.

**Negative / trade-offs:** Needs network; JetBrains/GitHub APIs must stay reachable.

**Follow-up:** If vfox lands in `[extra]`, prefer pacman and drop the GitHub path for that component.
