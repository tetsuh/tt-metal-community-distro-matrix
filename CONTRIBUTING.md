# Contributing

Thanks for helping improve the tt-metal community distribution matrix. This is
an unofficial compatibility tracker for build and install behavior on community
Linux distributions that are not covered by Tenstorrent's official CI.

## Scope

Good contributions for this repository include:

- adding or updating a distro container under `os/<distro>/<version>/`;
- fixing CI or Dockerfile behavior needed to reproduce matrix results;
- adding upstreamable `tt-metal` or `tt-installer` patches under `patches/`;
- improving generated compatibility/history output;
- clarifying contributor or maintainer documentation.

Out of scope:

- hardware bring-up, driver, firmware, BIOS/IOMMU, or performance issues;
- claims that a distro is supported on real Tenstorrent hardware;
- general vendor support requests for `tt-metal` or `tt-installer`;
- user-specific installation failures without a reproducible CI/container path.

For upstream product bugs or support requests, use the upstream
[`tenstorrent/tt-metal`](https://github.com/tenstorrent/tt-metal) or
[`tenstorrent/tt-installer`](https://github.com/tenstorrent/tt-installer)
repositories.

## Adding a distro or release

Follow [`docs/adding-a-new-os.md`](docs/adding-a-new-os.md). In short:

1. Add `os/<distro>/<version>/Dockerfile`.
2. Add the target to `.github/workflows/build-tt-metal.yaml`.
3. Add or update patch documentation when local patches are needed.
4. Run a single-target workflow first, then publish full-matrix results through
   the generated bot PR.

Use the `/etc/os-release` `ID` value as `<distro>` so patch discovery stays
consistent.

## Generated files

Do not hand-edit generated compatibility results:

- the `README.md` compatibility and history summary blocks;
- `history/latest.json`, `history/index.json`, and `history/runs/**`;
- `history/compatibility-history.svg`.

Those files are refreshed by `scripts/update_compat_table.py` from workflow
artifacts. Generated bot PRs are reviewed and squash-merged manually.

## Patches

Patches in `patches/` should be upstreamable when possible. Follow
[`patches/README.md`](patches/README.md), including the `Upstream-Status:` and
`Distro-Scope:` trailers.

If a PR adds a local patch, state whether it is:

- not applicable because no patch is added;
- pending upstream submission;
- submitted upstream, with a link;
- local-only, with a short justification.

## Pull requests

Keep PRs focused. Include:

- the distro/release or workflow path affected;
- validation performed, such as a workflow run link or local script smoke test;
- documentation updates when behavior or contributor workflow changes;
- generated README/history changes only when they come from the generator.

All repository PRs are merged through squash merge after review.
