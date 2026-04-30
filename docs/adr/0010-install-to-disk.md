# ADR-0010: Install Developer OS to disk from the live session

## Status

Accepted

## Context

The ISO is a **live** environment. Users need a supported path to **persist** Developer OS on a machine: partition, `pacstrap`, fstab, bootloader, and a non-empty-password user.

Official **archinstall** is interactive and opinionated; a small **guided script** keeps the profile self-contained and matches our package set. Developer OS now also ships a Calamares GUI installer as the primary desktop install path; this ADR records the CLI fallback and shared package/profile decisions behind both install flows.

## Decision

1. Ship **`arch-install-scripts`**, **`parted`**, **`dosfstools`**, **`efibootmgr`**, and **`rsync`** on the ISO.
2. Maintain **`/usr/local/share/developer-os/installer-packages.list`**: same user-facing stack as the live image minus **ISO-only** packages (`mkinitcpio-archiso`, `syslinux`, `edk2-shell`, `mtools`, `squashfs-tools`) while keeping installed-system essentials such as `mkinitcpio` and `e2fsprogs`.
3. Provide **`/usr/local/bin/developer-os-install`** (root): **UEFI + GPT** only, **550 MiB ESP** + **ext4 root**, **`systemd-boot`**, **`pacstrap`** from the list, **`genfstab`**, enable **NetworkManager** / bluetooth / PipeWire user units, **wheel sudo**, create **`developer`** user (or chosen name) with **password**, **Flathub** remote, copy **`vfox`** binary + completions from live if present, **rsync** `liveuser` dotfiles (`.config`, `.zshrc`, `.zprofile`) to the new user excluding `.cache`.
4. Document in **README**: launch the Calamares GUI installer from Plasma for the normal install path, or run **`sudo developer-os-install`** for the CLI fallback. The guided CLI quick install requires **UEFI**, and installed systems use **SDDM** with **Plasma Wayland** (see [ADR-0011](0011-kde-plasma-wayland-session.md)).

## Consequences

**Positive:** One command flow; reproducible package set; no AUR for install path.

**Negative / trade-offs:** **BIOS-only** machines unsupported by this script; **whole-disk wipe** only; **no** full-disk encryption in the script (users use Arch guide or manual partitioning).

**Follow-up:** Consider an `archinstall` preset or encryption support if the CLI path needs to cover more advanced installs. Calamares is covered separately in [ADR-0012](0012-calamares-gui-installer.md).
