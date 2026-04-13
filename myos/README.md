# MyOS — custom Arch Linux live image

Reproducible **archiso** profile with **Hyprland**, development tooling, **Flatpak** (Flathub), and a preconfigured **liveuser** session.

**Project docs:** [Documentation index](../docs/README.md) · [ADRs (decisions)](../docs/adr/README.md) · [How to extend docs](../docs/contributing.md)

## What you get

- **Boot**: BIOS (SYSLINUX) + UEFI (**systemd-boot**), matching upstream archiso releng layout.
- **Desktop**: Hyprland, Waybar, Rofi (Wayland), Mako, Kitty, Polkit GNOME agent.
- **Apps**: Thunar, Firefox, screenshot tools (`grim` / `slurp`), `wl-clipboard`.
- **Dev**: Git, OpenJDK (`jdk-openjdk`), `base-devel`.
- **Shell**: Zsh + Starship + autosuggestions + syntax highlighting (from distro packages).
- **Audio / BT**: PipeWire + WirePlumber, Bluetooth stack.
- **Flatpak**: `flathub` remote added at image build time.

## Layout

| Path | Role |
|------|------|
| `profiledef.sh` | ISO metadata, boot modes, squashfs options |
| `packages.x86_64` | Packages installed into the live system |
| `pacman.conf` | Pacman config for the build chroot |
| `airootfs/` | Files overlaid before `pacstrap`; `etc/passwd` seeds `liveuser` |
| `airootfs/root/customize.sh` | Chroot hook (also linked as `customize_airootfs.sh` for mkarchiso) |
| `syslinux/`, `efiboot/`, `grub/` | Bootloader assets (from releng) |

## Local build (on Arch)

```bash
cd myos
sudo pacman -S --needed archiso
chmod +x build.sh
sudo ./build.sh
```

ISOs appear under `myos/out/`. The build uses a working directory under `myos/work/` by default.

## Local build (Docker, any host)

Privileged container recommended (mkarchiso uses mounts / loop devices):

```bash
cd myos
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

## Live session

- User **`liveuser`** (empty password, **sudo** via `wheel`).
- **TTY1** auto-login starts a zsh login shell; `~/.zprofile` runs **`Hyprland`** when on `/dev/tty1`.
- Keybinds: **Super+Enter** terminal, **Super+D** launcher, **Super+Q** close window.

## Reproducibility

- Pin **`SOURCE_DATE_EPOCH`** (e.g. from `git log -1 --format=%ct`) so timestamps embedded in the ISO stay stable for a given commit.
- Package versions still follow mirrors at build time; for stricter pinning, use a fixed mirror snapshot or a local repo (out of scope for this minimal profile).

## CI

GitHub Actions workflow: `.github/workflows/build.yml` — builds inside `archlinux:latest`, caches `/var/cache/pacman/pkg`, uploads the ISO artifact.

Rationale is recorded in [ADR-0002: CI Arch container](../docs/adr/0002-ci-archlinux-container.md).

## Troubleshooting

- **`invalid group liveuser` during build:** `customize.sh` creates the `liveuser` group before `chown`; see [ADR-0004](../docs/adr/0004-liveuser-and-customize-hook.md).
