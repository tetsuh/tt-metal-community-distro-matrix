# `os/` — Distribution build environments

Each subdirectory holds the artifacts needed to reproduce a build environment for a single
distribution release. The CI matrix iterates over every leaf directory and runs the
upstream `tt-metal` (and, from Burst 2 onward, `tt-installer`) build inside the resulting
container image.

## Layout

```
os/
└── <distro>/
    └── <version>/
        └── Dockerfile        # builds the base image for that release
```

`<distro>` uses lowercase, hyphen-free names (`linuxmint`, `ubuntu`, `rocky`,
`debian`, ...). `<version>` is the upstream marketing version (`22.2`, `26.04`, `9`, ...).
This layout is intentionally flat so that a glob like `os/*/*/Dockerfile` enumerates the
full matrix.

## Currently onboarded

| Distribution | Codename | Base image |
|---|---|---|
| Linux Mint 22.3 | Zena | `ubuntu:24.04` (noble) |
| Linux Mint 22.2 | Zara   | `ubuntu:24.04` (noble) |
| Linux Mint 22.1 | Xia    | `ubuntu:24.04` (noble) |
| Linux Mint 21.3 | Virginia | `ubuntu:22.04` (jammy) |
| Ubuntu 26.04 | Resolute Raccoon | `ubuntu:26.04` |
| Debian 13 | Trixie | `debian:13` |
| Debian 12 | Bookworm | `debian:12` |
| Rocky Linux 10 | - | `quay.io/rockylinux/rockylinux:10` |
| Rocky Linux 9 | - | `quay.io/rockylinux/rockylinux:9` |

## Adding a new release

See [`docs/adding-a-new-os.md`](../docs/adding-a-new-os.md) for the full
workflow. In short:

1. Pick the closest existing Dockerfile and copy it to
   `os/<distro>/<version>/Dockerfile`.
2. Update the base image and bootstrap packages.
3. Wire the target into `.github/workflows/build-tt-metal.yaml` and
   `scripts/update_compat_table.py`.
4. Add build or installer patches only when the vanilla upstream flow fails.
