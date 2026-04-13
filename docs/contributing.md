# Contributing documentation

## When to update docs

- **User-facing behavior** changes (packages, login flow, keybinds): update `myos/README.md`.
- **Repository-wide** context (what this repo is): update the root `README.md` and, if needed, `docs/README.md`.

## When to add an ADR

Add a new Architecture Decision Record when the change is **significant and hard to reverse**, for example:

- Choice of toolchain, base profile, or CI strategy.
- How the live session starts (display manager vs TTY).
- Security posture (sudo, autologin, networking stack).

Skip an ADR for trivial fixes (typos, one-line bugfixes) unless they encode a new policy.

## ADR format and location

- Path: `docs/adr/NNNN-short-title.md` (four-digit number, sequential).
- Register it in `docs/adr/README.md` in the decision log table.
- Use the template in `docs/adr/0000-template.md`.

## Review

Prefer one commit that includes **code + docs + ADR** together so history stays traceable.
