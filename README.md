# deverloper-arch

Custom **Arch Linux** live image sources (**MyOS**) built with **archiso**: Hyprland desktop, development tooling, Flatpak, and CI that produces bootable ISO artifacts.

## Documentation

- **[docs/README.md](docs/README.md)** — documentation index
- **[myos/README.md](myos/README.md)** — build and run the ISO profile
- **[Architecture Decision Records](docs/adr/README.md)** — design rationale (ADRs)
- **[Contributing docs](docs/contributing.md)** — when and how to add ADRs

## Quick start

```bash
cd myos
# On Arch: install archiso, then sudo ./build.sh
# Else: see myos/README.md for Docker
```

Continuous integration: `.github/workflows/build.yml`.
