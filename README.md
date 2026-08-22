# developer-os — custom Arch Linux live image

Reproducible **archiso** profile with **KDE Plasma (Wayland)** via **SDDM**, development tooling, **Flatpak** (Flathub), and a preconfigured **liveuser** session.

**Project docs:** [Documentation index](./docs/README.md) · [ADRs (decisions)](./docs/adr/README.md) · [How to extend docs](./docs/contributing.md)

## What you get

- **Boot**: BIOS (SYSLINUX) + UEFI (**systemd-boot**), matching upstream archiso releng layout.
- **Desktop**: Plasma (Wayland session), SDDM, NetworkManager applet (`plasma-nm`), Kitty, GTK/Qt portal stack (`xdg-desktop-portal-kde` + `-gtk`), **Kvantum** (available, not the default widget style), and the first-party **Developer OS** look-and-feel (dark default + light variant, violet accent, Papirus icons, Inter + JetBrains Mono) vendored under `/usr/share` so it works offline — see [ADR-0016](./docs/adr/0016-first-party-plasma-theme.md). Optional MacTahoe icons can be fetched later with `sudo install-developer-os-theme.sh --with-mac-icons`. The default desktop wallpaper is the branded **Developer OS** package under `/usr/share/wallpapers/DeveloperOS`.
- **Apps**: Dolphin, Spectacle, Firefox, **Brave** (Flatpak from [Flathub](https://flathub.org/apps/com.brave.Browser)), `wl-clipboard`.
- **Dev**: Git, `git-lfs`, `base-devel`, **cmake** / **ninja**, **Docker** (service enabled; user in `docker` group), **Ollama**, **AWS CLI v2**, **Azure CLI**, **vfox** (pinned GitHub release → `/usr/local/bin`; plugins for Java, Maven, Gradle, Node, and .NET pre-added under `/opt/vfox` — see [ADR-0009](./docs/adr/0009-vfox-binary-from-github.md) and [ADR-0014](./docs/adr/0014-runtime-bootstrap.md)), **Code - OSS** (`code` from extra; see [ADR-0015](./docs/adr/0015-vscode-and-plasma-apps.md)), **JetBrains Toolbox** (pinned official Linux tarball → `/opt/jetbrains-toolbox`, menu entry; install IntelliJ IDEA, **Rider**, WebStorm, and other JetBrains IDEs from there — see [Toolbox App](https://www.jetbrains.com/toolbox-app/)).
- **CLI staples**: OpenSSH, wget, unzip/zip, jq, Python, ripgrep, fd, tree, man-db, htop.
- **First-hour runtimes**: after install, run **`developer-os-bootstrap`** (your user, not sudo) to download Java 21, Node LTS, .NET LTS, Maven, and Gradle. See [Language runtimes](#language-runtimes).
- **Shell**: Zsh + Starship + autosuggestions + syntax highlighting (from distro packages).
- **Audio / BT**: PipeWire + WirePlumber, Bluetooth stack.
- **Flatpak**: `flathub` remote added at image build time.
- **Install to disk**: launch **Install Developer OS** for the Calamares GUI installer, or run **`sudo developer-os-install`** for the CLI fallback with quick install, **`archinstall`**, or the wiki guide. See [Install to disk](#install-to-disk), [ADR-0010](./docs/adr/0010-install-to-disk.md), and [ADR-0012](./docs/adr/0012-calamares-gui-installer.md).

## Layout

All paths below live under **`developer-os/`** (the archiso profile directory).

| Path | Role |
|------|------|
| `profiledef.sh` | ISO metadata, boot modes, squashfs options (`install_dir` on the medium is **`devos`** — see [ADR-0006](./docs/adr/0006-rename-developer-os-and-install-dir.md)) |
| `packages.x86_64` | Packages installed into the live system |
| `pacman.conf` | Pacman config for the build chroot |
| `airootfs/` | Files overlaid before `pacstrap`; `etc/passwd` seeds `liveuser` |
| `airootfs/root/customize.sh` | Chroot hook invoked by mkarchiso; enables services and runs shared Developer OS install helpers |
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
sh ./build-iso.sh
```

## Locally running the ISO in Qemu

On Windows systems:

```shell
qemu-system-x86_64.exe -m 4086 -accel whpx -smp cores=6 -M pc -device ich9-usb-ehci1 -device usb-tablet -cdrom out\developer-os-*.iso
```

## Install to disk

The live desktop includes a **Calamares** graphical installer. It exposes the same Developer OS defaults as the live session while letting you choose locale, keyboard, hostname, user account, disk layout, and swap. The installed-profile step applies Developer OS extras such as Flathub/Brave, vfox, and JetBrains Toolbox through the shared helper scripts, and copies the first-party Plasma theme from the live medium.

1. Boot the ISO and connect to the network (same as live use).
2. From Plasma, open **Install Developer OS** from the application launcher.
3. Review and choose locale, keyboard, user, hostname, target disk/partitioning, and swap.
4. Confirm the summary page; Calamares writes the target system and removes live-only autologin behavior.
5. Reboot when finished and remove the USB stick.

**CLI fallback:** run **`sudo developer-os-install`**. Quick install (menu option 1) still requires **UEFI** firmware, wipes a whole target disk, and uses the same Developer OS profile scripts as the GUI. **`archinstall`** (option 2) supports the usual Arch choices, including BIOS setups, depending on what you configure there.

The installed system receives the same **`liveuser`** dotfiles under **`.config`** (and shell rc files when present), **`vfox`** if it was on the ISO, **Flathub**, and the Developer OS Plasma theme. **SDDM** is enabled with **`graphical.target`**; log in at the greeter (Plasma Wayland is the default session). See [ADR-0011](./docs/adr/0011-kde-plasma-wayland-session.md) and [ADR-0016](./docs/adr/0016-first-party-plasma-theme.md).

## Language runtimes

Java, Node, and .NET SDKs are **not** baked into the ISO. After you log into the installed system (with network):

```bash
developer-os-bootstrap
```

That command uses **vfox** (plugins already registered) to install **Java 21**, **Maven**, **Gradle**, **Node.js LTS** (and pnpm via corepack when possible), and **.NET LTS**, then sets them as your global versions. Open a new terminal afterwards. From Plasma you can also launch **Install language runtimes**.

Do **not** run it with `sudo`; SDKs must belong to your user. If `/opt/vfox` is not writable, log out and back in so the `vfox` group applies. See [ADR-0014](./docs/adr/0014-runtime-bootstrap.md).

Then open **VS Code** (`code`) or install an IDE from **JetBrains Toolbox**: IntelliJ IDEA (Java), Rider (.NET), or WebStorm (web). Microsoft C# Dev Kit needs Microsoft VS Code from Flathub (`flatpak install flathub com.visualstudio.code`).

## Updating apps after install

Extras installed by **`install-extras.sh`** (Brave Flatpak, **vfox**, **JetBrains Toolbox**) are pinned at image-build / install time and are not covered by a normal `pacman -Syu` alone. To refresh them to upstream latest (and update Arch packages by default):

```bash
sudo developer-os-update
```

Useful variants:

```bash
developer-os-update --check          # compare installed vs latest (no root)
sudo developer-os-update --extras-only   # Flatpak + vfox + Toolbox only
```

From Plasma, open **Update Developer OS apps** in the application launcher (runs the same flow in Kitty). See [ADR-0013](./docs/adr/0013-post-install-app-updates.md).

## Live session

- User **`liveuser`** (empty password, **sudo** via `wheel`).
- **SDDM** auto-logs **`liveuser`** into **Plasma (Wayland)** on boot (see **`airootfs/etc/sddm.conf.d/autologin.conf`**). Use the panel application launcher or **KRunner** (default shortcut is often **Meta** / Super).
- Interactive **Zsh** shows a system welcome banner (session, kernel, memory, disk, network, Java/Node/.NET/Docker, and first-hour commands). Hide it with `export DEVELOPER_OS_NO_ZSH_WELCOME=1`.

## Reproducibility

- Pin **`SOURCE_DATE_EPOCH`** (e.g. from `git log -1 --format=%ct`) so timestamps embedded in the ISO stay stable for a given commit.
- Package versions still follow mirrors at build time; for stricter pinning, use a fixed mirror snapshot or a local repo (out of scope for this minimal profile).

## CI

GitHub Actions workflow: `.github/workflows/build.yml` — currently runs on manual **`workflow_dispatch`**, builds a cached Arch **builder** image from `docker/Dockerfile.ci`, runs `mkarchiso` in a privileged container, caches `/var/cache/pacman/pkg`, and uploads the ISO artifact.

Rationale: [ADR-0002](./docs/adr/0002-ci-archlinux-container.md), [ADR-0006](./docs/adr/0006-rename-developer-os-and-install-dir.md).

## Troubleshooting

- **ISO unchanged after editing `airootfs/` or packages:** `mkarchiso` reuses `developer-os/work/` until you remove it; see [Rebuilding when you change the profile](#rebuilding-when-you-change-the-profile).
- **`invalid group liveuser` during build:** `customize.sh` creates the `liveuser` group before `chown`; see [ADR-0004](./docs/adr/0004-liveuser-and-customize-hook.md).
- **Black screen or SDDM loop:** confirm **`plasma-desktop`** is installed and try another session from the SDDM session menu. On current Arch Plasma, the Wayland session file is **`plasma.desktop`** under **`/usr/share/wayland-sessions/`** (see [ADR-0011](./docs/adr/0011-kde-plasma-wayland-session.md)).
- **Theme missing on a disk install:** the first-party Developer OS look-and-feel is vendored in the ISO and copied from the live medium by **`install-developer-os-theme.sh --rsync-from-live`**. No network is required. See [ADR-0016](./docs/adr/0016-first-party-plasma-theme.md).
- **`vfox` missing:** installed from a **pinned GitHub release** by `install-extras.sh`, which `customize.sh` runs during the ISO build (needs network). After boot, `vfox` is on `PATH`; zsh runs `eval "$(vfox activate zsh)"` with **`VFOX_HOME=/opt/vfox`**. See [ADR-0009](./docs/adr/0009-vfox-binary-from-github.md) and [ADR-0014](./docs/adr/0014-runtime-bootstrap.md). To refresh to the latest release after install, run **`sudo developer-os-update`** (see [Updating apps after install](#updating-apps-after-install)).
- **`java` / `node` / `dotnet` missing after install:** expected until you run **`developer-os-bootstrap`** as your user. If it cannot write `/opt/vfox`, log out and back in (membership in the `vfox` group).
- **Calamares missing from the live session:** Calamares is built from its AUR package during `customize.sh` because it is not available from the official Arch repositories enabled in `pacman.conf`; the ISO build needs network access to `aur.archlinux.org`.
- **Install script fails at `pacstrap`:** ensure mirrors work (`reflector` is not included by default); use `pacman -Sy` on the live system first or edit `pacman.conf` / mirrorlist.
- **Calamares does not start:** from a terminal in the live session, run `sudo -E calamares -d` to see module/config errors.
- **Calamares fails at mkinitcpio / `archiso` preset:** the live image ships an archiso-only `linux.preset`. The installer runs `prepare-installed-mkinitcpio.sh` before `initcpio` to switch to normal `default`/`fallback` presets. Rebuild the ISO if you still see `Building image from preset: … 'archiso'`.
