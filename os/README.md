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

`<distro>` uses lowercase, hyphen-free names (`linuxmint`, `ubuntu`, `rockylinux`,
`debian`, ...). `<version>` is the upstream marketing version (`22.2`, `26.04`, `9`, ...).
This layout is intentionally flat so that a glob like `os/*/*/Dockerfile` enumerates the
full matrix.

## Currently onboarded

| Distribution | Codename | Base image |
|---|---|---|
| Linux Mint 22.2 | Zara   | `ubuntu:24.04` (noble) |
| Linux Mint 22.1 | Xia    | `ubuntu:24.04` (noble) |
| Linux Mint 21.3 | Virginia | `ubuntu:22.04` (jammy) |

Pending Burst 2: Ubuntu 26.04, Rocky Linux 9, plus one of Rocky 10 / Debian 12.

## Adding a new release

A formal contribution guide lands in Burst 3.2 (`docs/adding-a-new-os.md`). Until then the
shortcut is:

1. Pick the closest existing Dockerfile (e.g. another Mint release) and copy it to
   `os/<distro>/<version>/Dockerfile`.
2. Update the `ARG` values, base image, and any keyring/repo URLs.
3. Open a PR. The matrix workflow will pick the new directory up automatically.
