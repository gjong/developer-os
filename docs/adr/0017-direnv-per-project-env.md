# ADR-0017: direnv for per-project environments

## Status

Accepted

## Context

[ADR-0015](0015-vscode-and-plasma-apps.md) parked `direnv` as a Phase 3 workflow extra. Projects on this image routinely need per-directory state — API endpoints, credentials read from a `.env`, a project-local `PATH`, and the SDK versions that [ADR-0014](0014-runtime-bootstrap.md)'s vfox setup manages. Without a loader, developers hand-source scripts or leak that state into `~/.zshrc`.

`direnv` is in Arch `[extra]`, so unlike vfox ([ADR-0009](0009-vfox-binary-from-github.md)) it needs no pinned GitHub tarball or custom installer. It is only useful when the shell hook is active, and a hook that developers must discover and enable themselves is a hook most of them never get.

## Decision

1. Ship **`direnv`** from `[extra]` in both `packages.x86_64` (live ISO) and `installer-packages.list` (disk installs).
2. Enable the zsh hook by default in the `liveuser` `.zshrc`, guarded by `command -v direnv` and placed **after** vfox activation so `.envrc` files can use vfox-managed SDKs.
3. Ship defaults under the `liveuser` home (`~/.config/direnv/`), which is the source of truth propagated to `/etc/skel` and to installed systems: a `direnv.toml` with `hide_env_diff = true` and a `warn_timeout`, and a `direnvrc` with a `use vfox` helper plus pointers to `dotenv` / `layout`.

## Consequences

**Positive:** `.envrc` files work after a single `direnv allow`, on the live session and on disk installs alike; per-project SDKs compose with vfox; no third-party download in the build.

**Negative / trade-offs:** One more package on the ISO, and an extra `eval` at zsh startup; `direnv allow` is still a manual step per project (by design — `.envrc` is executable code).

**Follow-up:** Remaining Phase 3 workflow extras (mkcert, HTTP/DB clients) are still open.
