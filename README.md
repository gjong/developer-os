# developer-os — custom Arch Linux live image

Reproducible **archiso** profile with **KDE Plasma (Wayland)** via **SDDM**, development tooling, **Flatpak** (Flathub), and a preconfigured **liveuser** session.

**Project docs:** [Documentation index](./docs/README.md) · [ADRs (decisions)](./docs/adr/README.md) · [How to extend docs](./docs/contributing.md)

## What you get

- **Boot**: BIOS (SYSLINUX) + UEFI (**systemd-boot**), matching upstream archiso releng layout.
- **Desktop**: Plasma (Wayland session), SDDM, NetworkManager applet (`plasma-nm`), Kitty, GTK/Qt portal stack (`xdg-desktop-portal-kde` + `-gtk`), **Kvantum**, and the **[MacTahoe-kde](https://github.com/vinceliuice/MacTahoe-kde)** look-and-feel (plus **[MacTahoe-icon-theme](https://github.com/vinceliuice/MacTahoe-icon-theme)** for icons/cursors) installed system-wide when **git** can reach GitHub during the ISO build or disk install; otherwise the installer tries to copy theme files from the live medium.
- **Apps**: Thunar, Firefox, screenshot tools (`grim` / `slurp`), `wl-clipboard`.
- **Dev**: Git, `base-devel`, **vfox** (pinned GitHub release → `/usr/local/bin`; see [ADR-0009](./docs/adr/0009-vfox-binary-from-github.md)), **JetBrains Toolbox** (pinned official Linux tarball → `/opt/jetbrains-toolbox`, menu entry; see [Toolbox App](https://www.jetbrains.com/toolbox-app/)).
- **Shell**: Zsh + Starship + autosuggestions + syntax highlighting (from distro packages).
- **Audio / BT**: PipeWire + WirePlumber, Bluetooth stack.
- **Flatpak**: `flathub` remote added at image build time.
- **Install to disk**: run **`sudo developer-os-install`** from the live session (UEFI, wipes target disk). See [Install to disk](#install-to-disk) and [ADR-0010](./docs/adr/0010-install-to-disk.md).

## Layout

All paths below live under **`developer-os/`** (the archiso profile directory).

| Path | Role |
|------|------|
| `profiledef.sh` | ISO metadata, boot modes, squashfs options (`install_dir` on the medium is **`devos`** — see [ADR-0006](./docs/adr/0006-rename-developer-os-and-install-dir.md)) |
| `packages.x86_64` | Packages installed into the live system |
| `pacman.conf` | Pacman config for the build chroot |
| `airootfs/` | Files overlaid before `pacstrap`; `etc/passwd` seeds `liveuser` |
| `airootfs/root/customize.sh` | Chroot hook (also linked as `customize_airootfs.sh` for mkarchiso) |
| `syslinux/`, `efiboot/`, `grub/` | Bootloader assets (from releng) |

## Local build (on Arch)

```bash
cd developer-os
sudo pacman -S --needed archiso
chmod +x build.sh
sudo ./build.sh
```

ISOs appear under `developer-os/out/`. The build uses a working directory under `developer-os/work/` by default.

## Local build (Docker, any host)

Privileged container recommended (mkarchiso uses mounts / loop devices):

```bash
cd developer-os
docker run --rm --privileged \
  -e SOURCE_DATE_EPOCH="$(git log -1 --format=%ct 2>/dev/null || date +%s)" \
  -v "$PWD:/profile" -w /profile \
  archlinux:latest bash -lc '
    set -euo pipefail
    pacman-key --init
    pacman-key --populate archlinux
    pacman -Sy --needed --noconfirm archiso arch-install-scripts sudo
    ./build.sh
  '
```

## Locally running the ISO in Qemu

On Windows systems:

```shell
qemu-system-x86_64.exe -m 4086 -accel whpx -smp cores=6 -M pc -device ich9-usb-ehci1 -device usb-tablet -cdrom out\developer-os-*.iso
```

## Install to disk

Requirements: **UEFI** firmware (this installer does not set up BIOS boot).

1. Boot the ISO and connect to the network (same as live use).
2. Run **`sudo developer-os-install`**.
3. Enter the target whole disk (e.g. `/dev/nvme0n1`), a username (default **`developer`**), and a **password** for that account.
4. Confirm with **`YES`** when prompted (the disk is erased).
5. When finished: **`sudo umount -R /mnt`**, reboot, and remove the USB stick.

The installed system receives the same **`liveuser`** dotfiles under **`.config`** (and shell rc files when present), **`vfox`** if it was on the ISO, and **Flathub**. **SDDM** is enabled with **`graphical.target`**; log in at the greeter (Plasma Wayland is the default session). See [ADR-0011](./docs/adr/0011-kde-plasma-wayland-session.md).

## Live session

- User **`liveuser`** (empty password, **sudo** via `wheel`).
- **SDDM** auto-logs **`liveuser`** into **Plasma (Wayland)** on boot (see **`airootfs/etc/sddm.conf.d/autologin.conf`**). Use the panel application launcher or **KRunner** (default shortcut is often **Meta** / Super).

## Reproducibility

- Pin **`SOURCE_DATE_EPOCH`** (e.g. from `git log -1 --format=%ct`) so timestamps embedded in the ISO stay stable for a given commit.
- Package versions still follow mirrors at build time; for stricter pinning, use a fixed mirror snapshot or a local repo (out of scope for this minimal profile).

## CI

GitHub Actions workflow: `.github/workflows/build.yml` — builds a cached Arch **builder** image from `docker/Dockerfile.ci`, runs `mkarchiso` in a privileged container, caches `/var/cache/pacman/pkg`, uploads the ISO artifact.

Rationale: [ADR-0002](./docs/adr/0002-ci-archlinux-container.md), [ADR-0006](./docs/adr/0006-rename-developer-os-and-install-dir.md).

## Troubleshooting

- **ISO unchanged after editing `airootfs/` or packages:** `mkarchiso` reuses `developer-os/work/` until you remove it; see [Rebuilding when you change the profile](#rebuilding-when-you-change-the-profile).
- **`invalid group liveuser` during build:** `customize.sh` creates the `liveuser` group before `chown`; see [ADR-0004](./docs/adr/0004-liveuser-and-customize-hook.md).
- **Black screen or SDDM loop:** confirm **`plasma-desktop`** is installed and try another session from the SDDM session menu. On current Arch Plasma, the Wayland session file is **`plasma.desktop`** under **`/usr/share/wayland-sessions/`** (see [ADR-0011](./docs/adr/0011-kde-plasma-wayland-session.md)).
- **MacTahoe missing or partial:** the theme is cloned during **`mkarchiso`** and during **`developer-os-install`** (needs **network**). Offline installs fall back to copying **`/usr/share/...`** from the live session if the ISO was built with the theme present. See [MacTahoe-kde](https://github.com/vinceliuice/MacTahoe-kde).
- **`vfox` missing:** installed from a **pinned GitHub release** in `customize.sh` (needs network). After boot, `vfox` is on `PATH`; zsh runs `eval "$(vfox activate zsh)"`. See [ADR-0009](./docs/adr/0009-vfox-binary-from-github.md).
- **Install script fails at `pacstrap`:** ensure mirrors work (`reflector` is not included by default); use `pacman -Sy` on the live system first or edit `pacman.conf` / mirrorlist.
