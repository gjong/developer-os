# ADR-0003: Start Hyprland from TTY autologin (no display manager)

## Status

Superseded by [ADR-0011](0011-kde-plasma-wayland-session.md)

## Context

Hyprland is a Wayland compositor. Live images often use a display manager (GDM, SDDM) or a `.xinitrc`-style flow. We want a small stack and a session that starts reliably on first boot without extra services.

This records the original Hyprland live-session choice. Developer OS now uses KDE Plasma on Wayland via SDDM; see [ADR-0011](0011-kde-plasma-wayland-session.md).

## Decision

Enable **systemd getty autologin** for `liveuser` on **tty1**. In `~/.zprofile`, when the login shell is on `/dev/tty1` and no `WAYLAND_DISPLAY`/`DISPLAY` is set, **`exec Hyprland`**.

## Consequences

**Positive:** Fewer moving parts than a DM; predictable for a dedicated live user.

**Negative / trade-offs:** Users who expect a greeter or multi-user consoles need to change this; autologin is weaker than password-protected login (acceptable for a live ISO with documented empty password).

**Follow-up:** If Hyprland changes session requirements, revisit environment imports in `hyprland.conf` and login shell startup order.
