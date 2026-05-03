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

These patches live in the workflow's `Build tt-metal inside container` step
rather than in the Docker image so the image itself stays free of
project-specific code.

### Kitware apt repository (`apt.kitware.com/ubuntu/<codename>`)

`prep_ubuntu_system` adds `https://apt.kitware.com/ubuntu/<codename> main`
using `OS_CODENAME` (which on Debian resolves to `bookworm` or `trixie`).
Kitware only publishes packages under Ubuntu codenames (`focal`, `jammy`,
`noble`, ...); a request for `bookworm` or `trixie` returns 404, the
subsequent `apt-get update` aborts with
"E: The repository '...' does not have a Release file", and the script
exits.

Both Debian 12 (CMake 3.25) and Debian 13 (CMake 3.31) already ship a CMake
new enough for tt-metal's `cmake_minimum_required(3.24)`, so the Kitware
upgrade is not strictly necessary. The workflow strips the Kitware-related
lines from `install_dependencies.sh` before invoking it on Debian.

### `software-properties-common` not in Debian 13

`prep_ubuntu_system` always installs `software-properties-common` to obtain
`add-apt-repository`. On Debian 13 (trixie) the package has been dropped
from `main` and `apt-get install` fails with "Unable to locate package".

The only PPA `install_dependencies.sh` adds (`ubuntu-toolchain-r/test`) is
gated on `UBUNTU_CODENAME == noble`, which never matches on Debian. The
workflow removes `software-properties-common` from the install line.

## Future improvements

* Send a PR to upstream tt-metal that branches `prep_ubuntu_system` on
  `OS_ID` (or just on whether `OS_CODENAME` is an Ubuntu codename) so the
  Kitware step is only run on Ubuntu-family systems and
  `software-properties-common` is only installed where available. That
  would let us delete both workarounds here.
* Pin both `debian:12` and `debian:13` by digest once we have a baseline
  green run we want to lock in for reproducibility.
