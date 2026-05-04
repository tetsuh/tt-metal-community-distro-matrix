# Linux Mint build environments

This directory hosts container definitions for **Linux Mint 22.3** (and the
older 21.x line, kept for reference) used by the `build-tt-metal.yaml`
workflow.  Linux Mint 22.x rebases on Ubuntu 24.04 (noble), so the bootstrap
mirrors the Ubuntu noble base; we add only what `tt-metal/install_dependencies.sh`
expects to be present.

## Workarounds for gaps in `install_dependencies.sh`

Patches live under [`patches/linuxmint/`](../../patches/linuxmint) and are
applied automatically by the workflow's `Build tt-metal inside container`
step before `install_dependencies.sh` runs.  Each patch is written so it
can be sent upstream as-is — see [`patches/README.md`](../../patches/README.md)
for the policy.

The Linux Mint patches currently in this repo:

| # | Title | Why it is needed |
|---|---|---|
| `0001` | `prep_ubuntu_system: skip ubuntu-toolchain-r PPA when g++-14 already available` | Upstream unconditionally calls `add-apt-repository -y ppa:ubuntu-toolchain-r/test` on Ubuntu 24.04 (noble) and Mint 22.x.  `g++-14` already ships in the noble main pocket, but the PPA add reaches `launchpad.net`, whose IPv4 endpoint frequently times out from GitHub-hosted runners and other restricted networks (`Cannot add PPA: 'Connection timed out, ...'`).  The patch probes `apt-cache show g++-14` first and only adds the PPA when the package isn't already reachable from the configured repositories.  Distro-Scope: `linuxmint-22.3`, `ubuntu-24.04`. |

## Future improvements

* Land the patches above upstream in tt-metal so `install_dependencies.sh`
  natively handles the launchpad-unreachable path, after which we can
  delete `patches/linuxmint/`.
