# Debian build environments

This directory hosts container definitions for **Debian 12 (bookworm)** and
**Debian 13 (trixie)** used by the `build-tt-metal.yaml` workflow.

## Policy

Identical to the Rocky Linux directory: we use the **official upstream
container images** (`debian:12`, `debian:13`) and add the smallest possible
bootstrap layer needed to make `tt-metal/install_dependencies.sh` succeed.

We do *not* maintain a hand-rolled minimal Debian image. Doing so would
duplicate work that the Debian project already does well, and would obscure
which gaps are genuinely tt-metal's vs. our container.

## Bootstrap contents and rationale

The Dockerfiles install a short list of packages that
`install_dependencies.sh` (specifically `prep_ubuntu_system`, which is shared
between Ubuntu and Debian) expects to already exist:

| Package | Why |
|---|---|
| `ca-certificates`, `curl`, `wget`, `gnupg`, `gpg`, `jq`, `lsb-release`, `software-properties-common` | Preconditions of `prep_ubuntu_system` (LLVM/Kitware key fetches, `add-apt-repository`). |
| `git`, `sudo` | Used by `install_dependencies.sh` and `tt-installer/install.sh`; not in the base image. |
| `locales` | Base image ships only POSIX/C; CMake/Python warn or fail under `LC_ALL=en_US.UTF-8` without the locale generated. |
| `equivs` | Used in the same layer to build the `kitware-archive-keyring` stub described below. |

## Workarounds for gaps in `install_dependencies.sh`

So far the only Debian-specific gap we have encountered is the **Kitware
apt repository**.

`prep_ubuntu_system` adds `https://apt.kitware.com/ubuntu/<codename> main`
using `OS_CODENAME` (which on Debian resolves to `bookworm` or `trixie`).
Kitware only publishes packages under Ubuntu codenames (`focal`, `jammy`,
`noble`, ...); a request for `bookworm` or `trixie` returns 404 and the
subsequent `apt-get install -y kitware-archive-keyring` fails with
"Unable to locate package".

Both Debian 12 (CMake 3.25) and Debian 13 (CMake 3.31) already ship a CMake
new enough for tt-metal's `cmake_minimum_required(VERSION 3.24)`, so the
Kitware upgrade is not strictly necessary. We pre-register an empty stub
`kitware-archive-keyring` package via `equivs` in the same layer so the
unmodified upstream script's `apt-get install` line is satisfied. The
404s emitted by `apt-get update` from the Kitware sources entry are
treated as warnings by apt, not errors.

## Future improvements

* Once we are confident the Debian build is stable, we should send a PR to
  upstream tt-metal that branches `prep_ubuntu_system` on `OS_ID` so the
  Kitware step is only run on Ubuntu-family systems. That would let us
  delete the stub here.
* Pin both `debian:12` and `debian:13` by digest once we have a baseline
  green run we want to lock in for reproducibility.
