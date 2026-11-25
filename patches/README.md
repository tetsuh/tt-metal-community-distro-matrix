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
| `debian/0001-...sfpi...patch` | Pending |
| `debian/0002-...install_llvm...patch` | Pending |
| `debian/0003-...software-properties...patch` | Pending |
| `debian/0005-...software-properties...trixie...patch` | Pending |
| `linuxmint/0001-...toolchain-ppa.patch`      | Pending |
| `linuxmint/0003-...bound-llvm-wget.patch` | Pending |
| `rocky/0001-...detect-package-manager...patch` | Pending |
| `rocky/0002-...unversioned-clang...patch` | Pending |
| `ubuntu/0001-...use-distro-cmake-on-resolute.patch` | Pending |
| `ubuntu/0002-...cmake4...patch`          | Pending     |

The compatibility table in the top-level `README.md` shows, for each
distro, both the *vanilla* result (no patches) and the *with-patches*
result, so readers can see at a glance which distros require local
patches and how many.

## LLVM setup patch refresh

The Debian, Linux Mint, and Ubuntu `prep_ubuntu_system` changes were refreshed
against tt-metal `26c3782109cf219ea9d61b9ba5c6ab945e06290d` for issue #102.
Upstream now installs LLVM with apt rather than `llvm.sh`, so the old key
preseed and `install_llvm` download workarounds were retired. Debian and Mint
still use IPv4 and bounded retries for the remaining apt.llvm.org wget calls.

## Runtime ttsim patches construction pin

The runtime ttsim failure patches below were constructed against tt-metal
`d04395ed862b4c65eb6877000c40200f456cb74e`:

- `rocky/0001-setup_external_testing_env-detect-package-manager.patch`
- `debian/0005-setup_external_testing_env-drop-software-properties-common-on-trixie.patch`

The retired `0001-tt-llk-tests-accept-python-3.10-and-newer.patch` bundles contained both
the Python version relaxation and dnf/yum detection; upstream `d515a8631fde`
(#53948) merged only the former, so the package manager detection half was
re-introduced here standalone. Same narrow-context rules as above apply.
