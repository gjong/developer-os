# ADR-0005: Use NetworkManager on the live image

## Status

Accepted

## Context

The stock releng profile includes systemd-networkd configuration fragments. This profile installs **NetworkManager** for a desktop-friendly Wi-Fi and Ethernet experience and enables it in `customize.sh`.

## Decision

Ship **NetworkManager** and enable **`NetworkManager.service`** in the image. Do not commit releng-style `multi-user.target.wants` overlays that enable **systemd-networkd** or **systemd-networkd-wait-online** for the live session, so NetworkManager owns desktop networking at boot.

## Consequences

**Positive:** Matches user expectations for a laptop-first live desktop; GUI-friendly.

**Negative / trade-offs:** Slightly different from minimal-server Arch defaults; advanced users who want systemd-networkd must re-enable it manually.

**Follow-up:** If we add a headless variant profile, consider keeping systemd-networkd there instead.
