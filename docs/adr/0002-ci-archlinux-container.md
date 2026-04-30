# ADR-0002: Build ISO in CI with a privileged Arch container

## Status

Accepted

## Context

GitHub-hosted runners use Ubuntu. `mkarchiso` expects an Arch environment (pacstrap, arch-chroot, tooling) and typically needs **privileged** operations (bind mounts, loop devices, filesystem images).

## Decision

Run CI builds using a **cached Docker image** built from `docker/Dockerfile.ci` (Arch + `archiso`), then **`docker run --privileged`** with that image. The workflow runs `developer-os/build.sh`, mounts a host pacman cache, and uploads `developer-os/out/*.iso` as a workflow artifact.

## Consequences

**Positive:** No assumption that Arch is installed on the runner; matches local Docker workflows.

**Negative / trade-offs:** Privileged containers are a larger security surface on the runner (acceptable for controlled CI, not for arbitrary third-party PRs without review).

**Follow-up:** If GitHub adds stricter defaults for privileged jobs, document any required org settings.
