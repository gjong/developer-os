# ADR-0001: Base the ISO on upstream archiso releng

## Status

Accepted

## Context

We need a maintainable custom Arch live image. Reinventing boot layout, initcpio hooks, and ISO structure duplicates work that the Arch project already tests on every release.

## Decision

Use the **archiso `releng` profile** as the structural base: `profiledef.sh` boot modes (`bios.syslinux`, `uefi.systemd-boot`), `syslinux/`, `efiboot/`, `grub/`, and the standard `airootfs` overlay model. Customize by trimming packages, editing `airootfs`, and extending `packages.x86_64`.

## Consequences

**Positive:** Compatibility with `mkarchiso` and Arch documentation; fewer bespoke boot bugs.

**Negative / trade-offs:** The tree includes bootloader assets we rarely edit; upstream profile changes may require occasional merges.

**Follow-up:** When archiso changes boot mode names or hooks, update this profile in lockstep.
