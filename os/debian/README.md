# Debian build environments

This directory hosts container definitions for **Debian 12 (bookworm)** and
**Debian 13 (trixie)** used by the `build-tt-metal.yaml` workflow.

## Policy

Identical to the Rocky Linux directory: we use the **official upstream
container images** (`debian:12`, `debian:13`) and add the smallest possible
bootstrap layer needed to satisfy `tt-metal/install_dependencies.sh`'s
preconditions (the `prep_ubuntu_system` function, which is shared between
Ubuntu and Debian).

We do *not* maintain a hand-rolled minimal Debian image. Doing so would
duplicate work that the Debian project already does well, and would obscure
which gaps are genuinely tt-metal's vs. our container.

## Bootstrap contents

| Package | Why |
|---|---|
| `ca-certificates`, `curl`, `wget`, `gnupg`, `gpg`, `jq`, `lsb-release` | Preconditions of `prep_ubuntu_system` (LLVM key fetches, status reporting). |
| `git`, `sudo` | Used by `install_dependencies.sh` and `tt-installer/install.sh`; not in the base image. |
| `locales` | Base image ships only POSIX/C; CMake/Python warn or fail under `LC_ALL=en_US.UTF-8` without the locale generated. |

Notably absent: `software-properties-common`. It is no longer in Debian 13
trixie main, and we do not need `add-apt-repository` on Debian (see below).

## Workarounds for gaps in `install_dependencies.sh`

These workarounds are kept as standalone `git format-patch` files under
[`patches/debian/`](../../patches/debian) at the top of the repo and are
applied automatically by the workflow's `Build tt-metal inside container`
step before `install_dependencies.sh` runs.  Keeping them as patch files
(rather than as inline `sed` rewrites in the workflow) makes them easier
to review, extend, and ultimately submit upstream — see
[`patches/README.md`](../../patches/README.md) for the policy.

The Debian patches currently in this repo:

| # | Title | Why it is needed |
|---|---|---|
| `0001` | `prep_ubuntu_system: use gpg --dearmor instead of apt-key` | `apt-key` is deprecated on Debian 12 and **removed** on Debian 13. The patch writes the LLVM signing key directly into `/etc/apt/trusted.gpg.d/`. |
| `0002` | `prep_ubuntu_system: skip Kitware repo on non-Ubuntu (Debian)` | Kitware only publishes apt repos for Ubuntu codenames; adding it on Debian causes `apt-get update` to 404. Debian 12 (CMake 3.25) and Debian 13 (CMake 3.31) already meet tt-metal's `cmake_minimum_required(3.24)`, so the upgrade is unnecessary. |
| `0003` | `install_sfpi: use dpkg --force-depends on Debian 12` | The upstream `sfpi` `.deb` declares `Depends: libstdc++6 (>= 12.3.0)`, but Debian 12 (bookworm) ships `libstdc++6 12.2.0` and `bookworm-backports` does not republish `libstdc++6` (or `gcc-13`). The patch relaxes the install to `dpkg -i --force-depends` only on Debian 12. Debian 13 ships `libstdc++6 14.x` and goes through the normal apt path. |
| `0004` | `install_dependencies: run install_llvm before install_sfpi` | `dpkg --force-depends` leaves apt in a broken-packages state, which causes the next apt-driven step (`llvm.sh` installing `clang-N`) to fail with `Unable to correct problems, you have held broken packages`. Reordering the calls keeps the apt resolver clean while LLVM is installed. This is a no-op on distros where sfpi installs cleanly. |
| `0005` | `prep_ubuntu_system: don't install software-properties-common on Debian 13` | The package was dropped from Debian 13 (trixie) main; apt fails with `Unable to locate package software-properties-common`. On Debian 12 (bookworm) the bundled `apt.llvm.org/llvm.sh` still hard-requires `add-apt-repository`, so we keep the package there and skip it only on Debian 13+ (gated on `VERSION_CODENAME=trixie`). |

Each patch carries an `Upstream-Status:` trailer in its commit message
and is intended to be sent upstream as-is.  Use
[`scripts/extract-upstream-pr.sh debian`](../../scripts/extract-upstream-pr.sh)
to assemble them into a tt-metal branch ready for a PR.

## Future improvements

* Land the patches above upstream in tt-metal so `install_dependencies.sh`
  natively handles Debian 12/13 and we can delete the `patches/debian/`
  directory.
* Pin both `debian:12` and `debian:13` by digest once we have a baseline
  green run we want to lock in for reproducibility.

## Upstream context

Upstream issue: https://github.com/tenstorrent/tt-metal/issues/18297 (Bounty: closed/paid)
Reference PR: https://github.com/tenstorrent/tt-metal/pull/25922 (closed without merge; bounty awarded but the proposed install_tt-debian.sh was not landed in main).

As of tt-metal main, install_dependencies.sh has no Debian-specific path; it falls into prep_ubuntu_system. Our workflow patches it in-line for Debian 12/13.

