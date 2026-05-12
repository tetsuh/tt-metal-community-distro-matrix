# Adding a new OS

This guide describes how to add a new distribution or release to the
community compatibility matrix. The matrix is a container-based guardrail:
success means the `tt-metal` deps/build pipeline and, where enabled, the
`tt-installer` install phase complete in CI without Tenstorrent hardware.

Keep hardwareless `ttsim` smoke checks separate from this flow. `ttsim`
validates a small simulator-backed workload on a reference Ubuntu host; it is
not a per-distro compatibility result.

## Before you start

Pick a target identifier in the form:

```text
<distro>-<version>
```

Examples: `debian-13`, `ubuntu-26.04`, `rocky-10`,
`linuxmint-22.3`.

The workflow splits the identifier at the first `-`:

- `<distro>` maps to `os/<distro>/`.
- `<version>` maps to `os/<distro>/<version>/`.
- `<distro>` should be lowercase, hyphen-free, and match the OS `ID`.

The patch directory is different: build patches are applied from
`patches/<ID>/`, where `<ID>` is the `ID=` value from `/etc/os-release`
inside the container. Keeping `<distro>` aligned with that value avoids broken
patch links in the generated README tables.

## 1. Add the Dockerfile

Create:

```text
os/<distro>/<version>/Dockerfile
```

Start from the closest existing Dockerfile:

| Family | Good starting point |
|---|---|
| Ubuntu-like | `os/ubuntu/26.04/Dockerfile` or a Linux Mint Dockerfile |
| Debian | `os/debian/12/Dockerfile` |
| RHEL-family | `os/rocky/9/Dockerfile` |

Keep the image small and focused on prerequisites that the upstream scripts
assume are already present. Common bootstrap packages are:

- `sudo`, `git`, `curl`, `ca-certificates`
- locale data with `en_US.UTF-8`
- distro-specific repository tools such as `gnupg`, `gpg`, `lsb-release`,
  `dnf-plugins-core`, or `epel-release`

The workflow verifies the image identity by reading `/etc/os-release` from the
built image. If the Dockerfile is easy to mispoint at the wrong base image, add
a cheap check such as:

```Dockerfile
RUN grep '^ID=ubuntu$' /etc/os-release
```

Do not copy this repository's compatibility patches into the image. The
workflow applies patches at runtime so the vanilla and patched results remain
observable separately.

## 2. Wire the workflow matrix

Update `.github/workflows/build-tt-metal.yaml` in three places.

1. Add the target to the `workflow_dispatch.inputs.target_os.options` list.
2. Add the target to the `setup` job's `all` matrix JSON.
3. Add the target to the `--require-os` list in the `Update README
   compatibility table` step, but only when the target should be required for
   full-matrix history publication.

If the OS should run the `tt-installer` install phase, also add it to the
`if:` expression on the `Prepare install.sh variants` step.

## 3. Add table ordering

Update `ROW_ORDER` in `scripts/update_compat_table.py`.

```python
ROW_ORDER: list[tuple[str, str]] = [
    # ...
    ("newdistro-1", "New Distro 1"),
]
```

This controls display order and the human-readable name in the README tables.
Unknown OSes found in artifacts are intentionally warned about rather than
rendered silently, so keep this list in sync with the workflow matrix.

## 4. Decide whether patches are needed

The build job records two results:

- **Vanilla**: upstream `install_dependencies.sh` without local patches.
- **With patches**: the full deps/build pipeline after applying
  `patches/<ID>/*.patch`.

If the new OS builds cleanly without patches, do not create a patch directory.
The README will show `(no patches)`.

If patches are needed:

1. Reproduce the failure in CI or locally.
2. Fix it in an upstream `tt-metal` checkout.
3. Export the fix with `git format-patch`.
4. Add it under `patches/<ID>/NNNN-short-summary.patch`.
5. Include `Upstream-Status:` and `Distro-Scope:` trailers as described in
   `patches/README.md`.

Prefer one upstream-ready patch per logical fix. If multiple versions of the
same distro need the same change, keep the version split inside the patch
rather than duplicating patch files per version.

## 5. Decide whether installer patches are needed

Installer patches are separate from build patches:

```text
patches/<ID>/installer/*.patch
```

The install phase uses the pinned `tt-installer` release in
`.github/workflows/build-tt-metal.yaml`, downloads the released `install.sh`,
and, when installer patches exist, regenerates `install.sh` from the pinned
`install.m4`.

Only add installer patches when the released installer cannot configure the
Tenstorrent package repository correctly on the target OS. Hardware-bound
installer steps are intentionally disabled in CI.

## 6. Run validation

For a single target:

1. Open the **Build tt-metal on community distros** workflow.
2. Run `workflow_dispatch`.
3. Set `target_os` to the new target.
4. Keep `tt_metal_repo` as `tenstorrent/tt-metal` unless testing a fork.
5. Keep `tt_metal_ref` as `main` unless validating a specific upstream PR.

Review the build artifact:

```text
build-<target_os>-<run_id>/
  os-release.txt
  logs/
    build.log
    build-vanilla.log
    install-vanilla.log
    install-patched.log
    status.json
```

`logs/status.json` is the source of truth for README rendering and history
snapshots.

Before merging, the PR should show:

- the new Dockerfile and any README notes;
- workflow matrix wiring;
- `ROW_ORDER` wiring;
- patch files, if required;
- a linked single-target validation run.

## 7. Publish a full-matrix snapshot

After the OS-specific PR is merged, run the build workflow with
`target_os=all`. The workflow will open a bot PR that refreshes:

- the compatibility tables in `README.md`;
- `history/latest.json`;
- `history/index.json`;
- raw per-OS JSON under `history/runs/<run_id>/`.

Review the workflow result and the README/history diff before merging the bot
PR. Bot PRs are not auto-merged.

## PR checklist

- [ ] `os/<distro>/<version>/Dockerfile` exists and verifies `/etc/os-release`.
- [ ] `build-tt-metal.yaml` includes the target in dispatch options and the
      full matrix.
- [ ] `ROW_ORDER` in `scripts/update_compat_table.py` includes the target.
- [ ] Install-phase wiring is added or intentionally omitted.
- [ ] Build patches are under `patches/<ID>/` only if needed.
- [ ] Installer patches are under `patches/<ID>/installer/` only if needed.
- [ ] A single-target validation run is linked in the PR.
- [ ] The PR explains any known vanilla failures and why patches are needed.
- [ ] `ttsim` expectations are documented separately from distro compatibility.
