# ADR-0011: KDE Plasma (Wayland) via SDDM instead of Hyprland on TTY

## Status

Accepted (appearance superseded by [ADR-0016](0016-first-party-plasma-theme.md))

## Context

Hyprland was the default compositor; the profile switched to KDE Plasma on Wayland for a conventional desktop (floating windows, panel, system settings) and mature integration with NetworkManager, XDG portals, and Polkit.

## Decision

- Ship **`plasma-desktop`**, **`plasma-nm`**, **`sddm`**, **`breeze-gtk`**, **`kde-gtk-config`**, **`kvantum`**, **`xdg-desktop-portal-kde`** (and keep **`xdg-desktop-portal-gtk`**).
- Default appearance was **[MacTahoe-kde](https://github.com/vinceliuice/MacTahoe-kde)** at the time of this ADR. That is superseded by the first-party **Developer OS** look-and-feel in [ADR-0016](0016-first-party-plasma-theme.md).
- Enable **`sddm.service`** and set **`graphical.target`** as the default in **`customize.sh`** and in **`developer-os-install`** chroot steps.
- **Live session:** **`/etc/sddm.conf.d/autologin.conf`** logs **`liveuser`** into **`plasma.desktop`** (Wayland session from **`plasma-workspace`**; not copied to disk installs, which use SDDM with a password).
- Remove TTY getty autologin, **`exec Hyprland`** profile hooks, **`hyprpm` / hyprbars** build logic, and Hyprland-specific dotfiles from **`airootfs/home/liveuser/.config`**.

## Consequences

**Positive:** Familiar desktop UX; no plugin build step; solid Wayland session from distro packages.

**Negative / trade-offs:** Larger ISO and image than the Hyprland stack; historical ADRs about Hyprland (0003, 0007, 0008) describe superseded behavior but remain as archive.

**Follow-up:** If SDDM or Plasma renames the Wayland session desktop file again (the old **`plasma-wayland-session`** package was merged into **`plasma-workspace`**), adjust **`Session=`** in **`autologin.conf`**. Appearance is documented in [ADR-0016](0016-first-party-plasma-theme.md).
