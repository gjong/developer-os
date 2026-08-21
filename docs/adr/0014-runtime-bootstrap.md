# ADR-0014: Shared vfox home and first-hour runtime bootstrap

## Status

Accepted

## Context

Developer OS targets Java, .NET, and web developers who should start real work soon after a disk install. Shipping full JDKs, Node, and .NET SDKs in the ISO would inflate the image and pin stale LTS builds. [ADR-0009](0009-vfox-binary-from-github.md) already ships **vfox**, but plugins were not pre-added, so the first commands were still `vfox add` plus several `vfox install` lines. CLI staples such as OpenSSH, `unzip`, and `jq` were also missing from the package lists.

## Decision

1. Keep runtimes **out of the ISO**. Pre-add vfox plugins **`java`**, **`maven`**, **`gradle`**, **`nodejs`**, and **`dotnet`** during `install-extras.sh` into a shared **`VFOX_HOME=/opt/vfox`** (group `vfox`, mode `2775`).
2. Export **`VFOX_HOME`** from `/etc/profile.d/developer-os-vfox.sh`, `/etc/environment`, and `~/.zshrc` so shells and GUI apps see the same plugin/SDK cache.
3. Add the installed user (and liveuser) to the **`vfox`** group so `developer-os-bootstrap` can write SDKs without root.
4. Ship **`developer-os-bootstrap`**: run as the login user (not sudo); install Java 21, Maven, Gradle, Node LTS, and .NET LTS; `vfox use -g` those versions; enable pnpm via corepack when Node is present.
5. Add day-one CLI packages to both package lists: `openssh`, `wget`, `unzip`, `zip`, `jq`, `python`, `git-lfs`, `ripgrep`, `fd`, `tree`, `man-db`, `htop`.
6. Point the welcome tour at bootstrap, then Java / .NET / web follow-ups.

## Consequences

**Positive:** One command after install gets a working toolchain; ISO size stays bounded; all users share plugin definitions.

**Negative / trade-offs:** First hour still needs **network**; group membership requires a new login before `/opt/vfox` is writable; plugin `add` during image build also needs network (same as vfox itself).

**Follow-up:** VS Code (Code - OSS) and Plasma-native Dolphin/Spectacle are [ADR-0015](0015-vscode-and-plasma-apps.md). If vfox lands in `[extra]`, keep this shared-home layout.
