# Patches against tt-metal

This directory holds patches that this repository applies on top of an
otherwise vanilla [`tenstorrent/tt-metal`](https://github.com/tenstorrent/tt-metal)
checkout when building on distros that are not yet officially supported
upstream.

The intent is **not** to maintain a long-running fork.  Each patch is
written so it can be sent upstream as-is, and the goal is to keep
`patches/` as small as possible.

## Layout

```
patches/
  <distro-id>/
    NNNN-short-summary.patch
    NNNN-short-summary.patch
    ...
```

`<distro-id>` is the value of the `ID=` field from `/etc/os-release` on
the target distro (e.g. `debian`).  The CI workflow looks at
`/etc/os-release` inside the build container and applies every
`*.patch` it finds in `patches/${ID}/` before running
`install_dependencies.sh`.

When multiple versions of the same distro family share a patch (e.g.
Debian 12 and Debian 13), the patch should make the version split
internal (e.g. `if [ "${VERSION_ID}" = "12" ]; then ... fi`) rather
than being duplicated under per-version subdirectories.  This keeps
the patch upstream-ready: a single file that can be reviewed and
landed without further restructuring.

## Patch format

Patches are produced with `git format-patch` against an upstream
tt-metal commit:

```sh
# inside a tt-metal clone
git format-patch -1 HEAD
```

This produces a file with a `Subject:`, a free-form body, and a
unified diff.  The body should explain **why** the patch is needed,
not just what it changes.

In addition we use two informal trailers in the body:

| Trailer            | Meaning                                                 |
|--------------------|---------------------------------------------------------|
| `Upstream-Status:` | `Pending` / `Submitted (<PR url>)` / `Merged (<sha>)` / `Inappropriate` |
| `Distro-Scope:`    | comma-separated list of distros / versions the patch targets |

## Lifecycle

1. **Add** — a new compatibility issue is reproduced in CI; the fix is
   developed against an upstream tt-metal checkout and exported as a
   numbered patch under `patches/<distro>/`.
2. **Apply** — CI applies the patch automatically (see
   `.github/workflows/build-tt-metal.yaml`).
3. **Submit upstream** — once the fix is stable, run
   [`scripts/extract-upstream-pr.sh`](../scripts/extract-upstream-pr.sh)
   to assemble the patches into a branch suitable for a tt-metal PR.
   Update `Upstream-Status:` to `Submitted (<PR url>)`.
4. **Retire** — once the upstream PR is merged and present in the
   tt-metal ref this repo builds against, delete the patch file (the
   commit message in this repo records the upstream sha).

## Current patches

| Path                         | Status      |
|------------------------------|-------------|
| `debian/0001-...sfpi...patch`            | Pending     |
| `debian/0002-...install_llvm...patch`    | Pending     |
| `debian/0003-...software-properties...patch` | Pending |
| `debian/0004-...python-3.10-and-newer...patch` | Pending |
| `linuxmint/0001-...toolchain-ppa.patch`      | Pending |
| `linuxmint/0002-...python-3.10-and-newer...patch` | Pending |
| `rocky/0001-...python-3.10-and-newer...patch` | Pending |
| `rocky/0002-...unversioned-clang...patch` | Pending |
| `ubuntu/0001-...skip-llvm-kitware-on-resolute...patch` | Pending |
| `ubuntu/0002-...cmake4...patch`          | Pending     |
| `ubuntu/0003-...python-3.10-and-newer...patch` | Pending |

The compatibility table in the top-level `README.md` shows, for each
distro, both the *vanilla* result (no patches) and the *with-patches*
result, so readers can see at a glance which distros require local
patches and how many.
