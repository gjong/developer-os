# ADR-0010: Install Developer OS to disk from the live session

## Status

Accepted

## Context

The ISO is a **live** environment. Users need a supported path to **persist** Developer OS on a machine: partition, `pacstrap`, fstab, bootloader, and a non-empty-password user.

Official **archinstall** is interactive and opinionated; a small **guided script** keeps the profile self-contained and matches our package set.

## Decision

1. Ship **`arch-install-scripts`**, **`parted`**, **`dosfstools`**, **`efibootmgr`**, and **`rsync`** on the ISO.
2. Maintain **`/usr/local/share/developer-os/installer-packages.list`**: same stack as the live image minus **ISO-only** packages (`mkinitcpio-archiso`, `syslinux`, `edk2-shell`, `mtools`, `squashfs-tools`, `e2fsprogs` for ISO layout — `e2fsprogs` stays on disk for ext4 tools; actually we have mkinitcpio for initramfs on installed system - good).
3. Provide **`/usr/local/bin/developer-os-install`** (root): **UEFI + GPT** only, **550 MiB ESP** + **ext4 root**, **`systemd-boot`**, **`pacstrap`** from the list, **`genfstab`**, enable **NetworkManager** / bluetooth / PipeWire user units, **wheel sudo**, create **`developer`** user (or chosen name) with **password**, **Flathub** remote, copy **`vfox`** binary + completions from live if present, **rsync** `liveuser` dotfiles (`.config`, `.zshrc`, `.zprofile`) to the new user excluding `.cache`.
4. Document in **README**: run **`sudo developer-os-install`**, requirements (**UEFI**), and that **hyprbars** must be rebuilt on first boot with network (`hyprpm`).

## Consequences

**Positive:** One command flow; reproducible package set; no AUR for install path.

**Negative / trade-offs:** **BIOS-only** machines unsupported by this script; **whole-disk wipe** only; **no** full-disk encryption in the script (users use Arch guide or manual partitioning).

**Follow-up:** Optional `archinstall` preset or Calamares if demand grows.
