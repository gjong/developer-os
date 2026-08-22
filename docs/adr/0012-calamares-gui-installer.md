# ADR-0012: Calamares GUI installer for Developer OS

## Status

Accepted

## Context

Developer OS already had a root-only `developer-os-install` script for quick installs from the live session. That path was useful but only exposed a small set of prompts: disk, username, password, and final wipe confirmation.

The live image now ships a full Plasma desktop, so users should be able to install from a graphical flow and configure the same system settings normally expected from a desktop installer: locale, keyboard, hostname, user account, partitioning, swap, and Developer OS profile defaults.

## Decision

Ship **Calamares** on the live ISO as the primary graphical installer. Since Calamares is not available from the official Arch repositories enabled in `pacman.conf`, install it during `customize.sh` from the AUR package instead of listing it in `packages.x86_64`. The Calamares module graph unpacks the live `airootfs.sfs` onto the target, removes live-only packages and autologin behavior from the installed system, configures system settings through standard modules, and calls shared Developer OS post-install scripts for services, sudo, dotfiles, `/etc/skel`, Flathub/Brave, vfox, JetBrains Toolbox, and the first-party Plasma theme.

Before **`initcpio`**, run **`prepare-installed-mkinitcpio.sh`**: replace the live-only `linux.preset` (`PRESETS=('archiso')`) and remove `mkinitcpio.conf.d/archiso.conf` / `mkinitcpio-archiso`, so the installed system builds normal `default`/`fallback` initramfs images.

Keep **`developer-os-install`** as the CLI fallback, but make it call the same shared post-install/profile scripts so GUI and CLI installs stay aligned.

## Consequences

**Positive:** Users get a familiar graphical installer with configurable locale, keyboard, hostname, account, disk layout, and swap while preserving the live session profile and Developer OS extras on disk installs.

**Negative / trade-offs:** Calamares becomes a live-only AUR dependency and adds module configuration that must be validated with real ISO boots. The GUI path installs by unpacking the live squashfs rather than using `pacstrap`, so cleanup must remove live-only artifacts from the installed system.

**Follow-up:** Add a QEMU-based smoke test for the Calamares module graph and revisit encrypted installs once the bootloader and mkinitcpio hooks are configured end-to-end.
