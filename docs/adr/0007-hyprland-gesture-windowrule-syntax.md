# ADR-0007: Hyprland gesture and window rule syntax for current releases

## Status

Superseded by [ADR-0011](0011-kde-plasma-wayland-session.md)

## Context

Recent Hyprland releases removed the **`gestures { workspace_swipe = on }`** block (the option no longer exists) and deprecated then removed **`windowrulev2`** in favor of a unified **`windowrule`** syntax using explicit **`match:class`** (and related) props.

This records maintenance for the previous Hyprland configuration. Developer OS now uses KDE Plasma on Wayland via SDDM; see [ADR-0011](0011-kde-plasma-wayland-session.md).

## Decision

- Replace workspace swipe with a top-level gesture line: **`gesture = 3, horizontal, workspace`** (see [Gestures](https://wiki.hypr.land/Configuring/Gestures/)).
- Replace **`windowrulev2`** with **`windowrule = float on, match:class ^(…)$`** (see [Window Rules](https://wiki.hypr.land/Configuring/Window-Rules/)).

## Consequences

**Positive:** Clean boot without deprecation warnings; config aligned with current wiki.

**Negative / trade-offs:** Users on very old Hyprland would need the inverse migration (not targeted by this ISO).

**Follow-up:** Re-check wiki if Hyprland changes gesture or windowrule grammar again.
