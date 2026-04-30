# ADR-0006: Rename product to developer-os; ISO install directory `devos`

## Status

Accepted

## Context

The live image was previously branded **MyOS** with profile directory `myos/` and `install_dir=myos`. The product name should be **developer-os** for consistency with the repository.

`mkarchiso` restricts **`install_dir`** to **at most 8 characters** and **only `[a-z0-9]`**. The string `developer-os` is therefore invalid as `install_dir`; a short on-ISO path is required for kernel/initramfs and bootloader substitution (`%INSTALL_DIR%`).

## Decision

- Rename the archiso profile directory to **`developer-os/`** (repository path).
- Set human-facing metadata to **Developer OS** / **developer-os** (`iso_name`, `iso_application`, boot menu strings, GECOS).
- Set **`install_dir="devos"`** in `profiledef.sh` so the ISO layout remains valid (`/devos/boot/...` on the medium).
- Use ISO volume label prefix **`DEVOS_`** (fits typical label length limits).

## Consequences

**Positive:** Clear product name in git and docs; compliant `install_dir`.

**Negative / trade-offs:** The on-disk directory name inside the ISO (`devos`) differs from the marketing/repo folder name (`developer-os`); document this for anyone grepping ISO contents.

**Follow-up:** If we need a longer `install_dir` in the future, we must wait for archiso to relax limits or fork tooling — prefer keeping `devos` unless requirements change.
