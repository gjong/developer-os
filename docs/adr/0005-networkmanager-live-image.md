# ADR-0005: Use NetworkManager on the live image

## Status

Accepted

## Context

The stock releng `airootfs` enables **systemd-networkd** and related units. This profile installs **NetworkManager** for a desktop-friendly Wi‑Fi and Ethernet experience and enables it in `customize.sh`.

## Decision

Ship **NetworkManager**, enable **`NetworkManager.service`** in the image, and **remove** `multi-user.target.wants` symlinks for **systemd-networkd** and **systemd-networkd-wait-online** from the overlaid `airootfs` so two managers do not fight on the live session.

## Consequences

**Positive:** Matches user expectations for a laptop-first live desktop; GUI-friendly.

**Negative / trade-offs:** Slightly different from minimal-server Arch defaults; advanced users who want systemd-networkd must re-enable it manually.

**Follow-up:** If we add a headless variant profile, consider keeping systemd-networkd there instead.
