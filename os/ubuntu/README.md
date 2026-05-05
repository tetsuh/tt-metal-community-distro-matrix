# Ubuntu build environments

This directory hosts the container definition(s) for vanilla Ubuntu used
by the `build-tt-metal.yaml` workflow.  Ubuntu 22.04 / 24.04 are already
covered indirectly via Linux Mint 21.3 / 22.x (Mint rebases on Ubuntu);
we add Ubuntu rows here only when there is signal that is not
reproducible from the Mint matrix.

## Why Ubuntu 26.04 is in the matrix

Ubuntu 26.04 LTS ("Resolute Wombat") is the next LTS after 24.04 noble.
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

Patches live under [`patches/ubuntu/installer/`](../../patches/ubuntu/installer)
(installer-side) and are applied automatically by the workflow's
install-phase prep step.  Each patch is written so it can be sent
upstream as-is — see [`patches/README.md`](../../patches/README.md) for
the policy.

| # | Path | Title | Why it is needed |
|---|---|---|---|
| `0001` | `installer/` | `installer: map Ubuntu 26.04 (resolute) to noble for the Tenstorrent PPA` | `ppa.tenstorrent.com` does not yet publish a `resolute` pocket; the 24.04 (`noble`) packages are ABI-compatible enough for the installer's purposes (driver / firmware tooling), so we override the codename used for the apt sources entry. The patch is intended to be temporary and should be dropped once Tenstorrent ships a 26.04 pocket.  Distro-Scope: `ubuntu-26.04`. |

## Future improvements

* Drop the codename mapping patch as soon as `ppa.tenstorrent.com`
  exposes a 26.04 pocket.
* Add `ubuntu-24.04` only if a regression appears that is not visible on
  Mint 22.x.
