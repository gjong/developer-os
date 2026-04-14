# ADR-0008: Ship hyprbars via hyprpm at image build time

## Status

Accepted

## Context

**Hyprbars** is a **Hyprland plugin** from [hyprland-plugins](https://github.com/hyprwm/hyprland-plugins). It is **not** published as a first-party package in Arch `[core]/[extra]` under a name like `hyprbars`. The live config used `plugin { hyprbars { ... } }` without ever loading the `.so`, so Hyprland warned or ignored the block.

## Decision

1. Install **hyprpm build dependencies** in the ISO (`cmake`, `meson`, `ninja`, `cpio`, `glaze`, `hyprland-protocols`; `git` and `base-devel` are already present).
2. In **`customize.sh`**, as **`liveuser`**, run **`hyprpm update`**, **`hyprpm add`** the official plugins repo, **`hyprpm enable hyprbars`**, then **`hyprpm update`** again to compile against the installed Hyprland headers. This requires **network during `mkarchiso`** (same as `pacstrap`).
3. In **`hyprland.conf`**, add **`exec-once = hyprpm reload`** so the built plugin loads on session start.

## Consequences

**Positive:** Title bars and configured buttons work on the live image without relying on the AUR.

**Negative / trade-offs:** ISO build time and size increase; plugin build can fail if GitHub is unreachable or Hyprland/plugins ABI drift (logged as a warning, image still builds).

**Follow-up:** If upstream splits packaging (e.g. official `hyprland-plugin-hyprbars` in extra), prefer that over `hyprpm` in chroot.
