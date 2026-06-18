# Ubuntu build environments

This directory hosts the container definition(s) for vanilla Ubuntu used
by the `build-tt-metal.yaml` workflow.  Ubuntu 22.04 / 24.04 are already
covered indirectly via Linux Mint 21.3 / 22.x (Mint rebases on Ubuntu);
we add Ubuntu rows here only when there is signal that is not
reproducible from the Mint matrix.

## Why Ubuntu 26.04 is in the matrix

Ubuntu 26.04 LTS ("Resolute Raccoon") is the next LTS after 24.04 noble.
At the time it was added to this matrix the Tenstorrent apt repository
(`https://ppa.tenstorrent.com/ubuntu/<codename>`) only publishes
`jammy` and `noble` pockets; the upstream `tt-installer` derives the
pocket name from `VERSION_CODENAME=resolute` and so fails with a 404 on
26.04.  Adding 26.04 here gives us:

* an early signal when Tenstorrent publishes the 26.04 codename
  (we can drop the patch and the row will go ✅ Vanilla);
* a place to exercise `install_dependencies.sh` and the tt-metal build
  against the 26.04 toolchain (gcc-15 / glibc 2.41 / Python 3.13) ahead
  of upstream officially supporting it.

The 24.04 row is intentionally omitted: Linux Mint 22.x already
exercises the noble base.

## Workarounds for gaps in `install.sh` / `install_dependencies.sh`

Patches live in two places, mirroring the two phases of the workflow:

* [`patches/ubuntu/`](../../patches/ubuntu) — patches applied by the
  build-phase step to the **tt-metal** source tree (in particular
  `install_dependencies.sh`) before `build_metal.sh` is invoked.
* [`patches/ubuntu/installer/`](../../patches/ubuntu/installer) —
  patches applied by the install-phase prep step to the
  **tt-installer** source (`install.sh` / `install.m4`).

Each patch is written so it can be sent upstream as-is — see
[`patches/README.md`](../../patches/README.md) for the policy.

| # | Path | Title | Why it is needed |
|---|---|---|---|
| `0001` | `./` | `prep_ubuntu_system: use gpg --dearmor instead of apt-key` | `apt-key` was removed entirely from Ubuntu 26.04 (resolute), so `install_dependencies.sh` line 275 fails with `apt-key: command not found` (exit 127) before the build can even start. Replace the legacy `apt-key add -` invocation with a `gpg --dearmor` write into `/etc/apt/trusted.gpg.d/`, which works identically on Ubuntu 22.04+ and Debian 12/13. **Upstream tracking:** [tenstorrent/tt-metal#38833](https://github.com/tenstorrent/tt-metal/pull/38833) (open) addresses the same issue for Debian 12; once that PR lands the codepath will already be modern on `main`. Distro-Scope: `ubuntu, debian-12, debian-13`. |
| `0002` | `./` | `prep_ubuntu_system: install distro LLVM and CMake on Ubuntu 26.04 (resolute)` | Ubuntu 26.04 already ships `clang-17`, `clang-20`, `llvm-20-dev` (1:20.1.8) and `cmake` (>= 4.2) in main/universe, so the third-party `apt.llvm.org` repository and the GitHub CMake installer that `prep_ubuntu_system` uses for older Ubuntu releases are redundant. Worse, `apt.llvm.org` has not yet published a `resolute` pocket, so adding it forces `apt-get update` to fail with a 404. Wrap the repository/CMake setup in a `case "$OS_CODENAME"` guard that opts out on `resolute` and installs the distro toolchain (`clang-17 clang-20 llvm-20-dev cmake`) instead. The Dockerfile pre-installs `clang-20` so `install_llvm`'s `command -v clang-20` short-circuits its `apt.llvm.org/llvm.sh 20` call as well. Distro-Scope: `ubuntu-26.04`. |
| `0001` | `installer/` | `installer: map Ubuntu 26.04 (resolute) to noble for the Tenstorrent PPA` | `ppa.tenstorrent.com` does not yet publish a `resolute` pocket; the 24.04 (`noble`) packages are ABI-compatible enough for the installer's purposes (driver / firmware tooling), so we override the codename used for the apt sources entry. The patch is intended to be temporary and should be dropped once Tenstorrent ships a 26.04 pocket.  Distro-Scope: `ubuntu-26.04`. |

## Future improvements

* Drop the apt-key patch once
  [tenstorrent/tt-metal#38833](https://github.com/tenstorrent/tt-metal/pull/38833)
  (or an equivalent fix) lands on `main`.
* Drop the third-party-repo skip patch as soon as the older Ubuntu
  releases in the matrix also have clang-20 and a recent CMake in
  distro (so the upstream code can use distro packages
  unconditionally).
* Drop the codename mapping patch as soon as `ppa.tenstorrent.com`
  exposes a 26.04 pocket.
* Add `ubuntu-24.04` only if a regression appears that is not visible on
  Mint 22.x.
