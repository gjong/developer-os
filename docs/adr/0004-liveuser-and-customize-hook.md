# ADR-0004: Seed `liveuser` in passwd and run `customize.sh` via mkarchiso hook

## Status

Accepted

## Context

We need a non-root live account with a pre-populated home for dotfiles. `mkarchiso` copies `/etc/skel` into homes for users listed in **`airootfs/etc/passwd`** before running the customize script. Current `mkarchiso` invokes **`/root/customize.sh`** inside the chroot.

We also hit a real failure: **`passwd` listed GID 1000 for `liveuser` but no `liveuser` group existed** in `/etc/group` after pacstrap, so `chown liveuser:liveuser` failed in CI.

## Decision

1. Add **`liveuser`** to **`airootfs/etc/passwd`** and **`airootfs/etc/shadow`** so mkarchiso creates `/home/liveuser` and merges the profile tree.
2. Keep the profile customization entry point at **`airootfs/root/customize.sh`** and mark it executable through **`profiledef.sh`**.
3. In **`customize.sh`**, ensure a **`liveuser` group** exists (create GID 1000 when free, or fall back and align the user) **before** any `chown` using `liveuser:liveuser`.

## Consequences

**Positive:** Home layout stays declarative in git; customize step enables services, sudo, Flatpak, and fixes group ownership deterministically.

**Negative / trade-offs:** Duplication between `passwd` and `customize.sh` logic must stay consistent if UID/GID policy changes.

**Follow-up:** When archiso changes the customization hook contract again, update `profiledef.sh`, the hook file name, and this ADR together.
