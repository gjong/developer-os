# ADR-0016: First-party Developer OS Plasma theme

## Status

Accepted

## Context

ADR-0011 defaulted the desktop to **MacTahoe-kde** cloned from GitHub during `customize.sh` and disk install. That made the look depend on network access to GitHub, left third-party branding on a product named Developer OS, and produced a known failure mode (stock Breeze) when the clone failed. The welcome tour, zsh banner, and Calamares branding already used a first-party violet/slate palette that the desktop did not share.

## Decision

1. Vendor a first-party **Developer OS** look-and-feel (dark default + light variant, violet accent `#7c3aed`) under `airootfs/usr/share/` so the ISO and disk install work offline.
2. IDs: look-and-feel `com.developeros.plasma.dark` / `.light`; color schemes `DeveloperOSDark` / `DeveloperOSLight`; Plasma desktop theme and Aurorae decoration `DeveloperOS-Dark` / `DeveloperOS-Light`.
3. Use **Breeze** as the widget style (honours the color scheme, no Kvantum assets). Keep the `kvantum` package installed for users who want it.
4. Default icons to **Papirus** (`papirus-icon-theme` from extra). MacTahoe icons remain an optional `install-developer-os-theme.sh --with-mac-icons` download. Cursors stay Breeze.
5. Seed a macOS-inspired layout: traffic-light buttons on the left, 26px top menu bar, floating centered dock with Kitty / Code - OSS / Dolphin / Firefox / Toolbox / System Settings pinned, named virtual desktops (Code, Web, Comms, Ops), `Meta+Space` for KRunner, Inter + JetBrains Mono fonts.
6. Carry the same 16-color palette into kitty, Starship, Code - OSS, the SDDM greeter (`developer-os` theme), and Calamares sidebar colors.
7. Replace `install-mactahoe-kde-theme.sh` / `seed-plasma-mactahoe.sh` with `install-developer-os-theme.sh` / `seed-plasma-theme.sh`. Disk install always rsyncs the vendored trees from the live medium.

This supersedes the MacTahoe appearance decision in [ADR-0011](0011-kde-plasma-wayland-session.md). Plasma-on-Wayland via SDDM is unchanged.

## Consequences

**Positive:** Deterministic, offline, first-party appearance; one palette across desktop, terminal, editor, installer, and login; no GitHub dependency for the default look.

**Negative / trade-offs:** Aurorae SVG decorations are simpler than a C++ KDecoration plugin; panel chrome falls back to Breeze for any missing SVG; MacTahoe icons are no longer the default.

**Follow-up:** If a C++ decoration or a fuller SVG desktop theme is needed later, keep the same IDs and color schemes so user config does not change.
