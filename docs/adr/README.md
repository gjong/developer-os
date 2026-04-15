# Architecture Decision Records

ADRs record **why** we made non-obvious choices. They complement the root `README.md`, which explains **how** to build and run the image.

## Index

| ADR | Title | Status |
|-----|--------|--------|
| [0001](0001-releng-archiso-profile.md) | Base the ISO on upstream archiso releng | Accepted |
| [0002](0002-ci-archlinux-container.md) | Build ISO in CI with a privileged Arch container | Accepted |
| [0003](0003-hyprland-tty-session.md) | Start Hyprland from TTY autologin (no display manager) | Accepted |
| [0004](0004-liveuser-and-customize-hook.md) | Seed `liveuser` in passwd and run `customize.sh` via mkarchiso hook | Accepted |
| [0005](0005-networkmanager-live-image.md) | Use NetworkManager on the live image | Accepted |
| [0006](0006-rename-developer-os-and-install-dir.md) | Rename product to developer-os; ISO path `devos/` | Accepted |
| [0007](0007-hyprland-gesture-windowrule-syntax.md) | Hyprland: gesture line + `windowrule` / `match:` syntax | Accepted |
| [0008](0008-hyprbars-via-hyprpm.md) | Hyprbars via `hyprpm` at image build + `exec-once` reload | Accepted |
| [0009](0009-vfox-binary-from-github.md) | vfox from pinned GitHub release + zsh `vfox activate` | Accepted |
| [0010](0010-install-to-disk.md) | Guided `developer-os-install` + installer package list | Accepted |

## Creating a new ADR

1. Copy [0000-template.md](0000-template.md) to the next number, e.g. `0006-my-topic.md`.
2. Fill in Status, Context, Decision, Consequences.
3. Add a row to the table above.
