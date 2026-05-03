#!/usr/bin/env bash
# Assemble patches/<distro>/*.patch into a branch in a fresh tt-metal
# clone, ready to be opened as an upstream pull request.
#
# Usage:
#   scripts/extract-upstream-pr.sh <distro> [<tt-metal-ref>] [<work-dir>]
#
# Example:
#   scripts/extract-upstream-pr.sh debian main /tmp/tt-metal-pr-debian
#
# The script will:
#   1. Clone (or reuse) tenstorrent/tt-metal at <tt-metal-ref>.
#   2. Create a branch named "ttossj1/<distro>-support".
#   3. git am every patches/<distro>/*.patch on top.
#   4. Print the next-step commands for pushing to a fork and opening
#      a PR.
#
# It does *not* push or open a PR itself; it only stages a clean tree
# you can review with `git log -p` and ship.

set -euo pipefail

distro="${1:-}"
ref="${2:-main}"
workdir="${3:-${TMPDIR:-/tmp}/tt-metal-pr-${1:-unknown}}"

if [ -z "$distro" ]; then
    echo "usage: $0 <distro> [<tt-metal-ref>] [<work-dir>]" >&2
    exit 2
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
patch_dir="$repo_root/patches/$distro"

if [ ! -d "$patch_dir" ]; then
    echo "no patch directory: $patch_dir" >&2
    exit 1
fi

shopt -s nullglob
patches=("$patch_dir"/*.patch)
if [ ${#patches[@]} -eq 0 ]; then
    echo "no patches in $patch_dir" >&2
    exit 1
fi

branch="ttossj1/${distro}-support"

if [ ! -d "$workdir/.git" ]; then
    echo "==> cloning tt-metal into $workdir"
    git clone --depth 50 --branch "$ref" \
        https://github.com/tenstorrent/tt-metal.git "$workdir"
else
    echo "==> reusing existing clone at $workdir"
    git -C "$workdir" fetch origin "$ref"
    git -C "$workdir" checkout "$ref"
    git -C "$workdir" reset --hard "origin/$ref"
fi

cd "$workdir"

if git rev-parse --verify "$branch" >/dev/null 2>&1; then
    git checkout "$branch"
    git reset --hard "origin/$ref"
else
    git checkout -b "$branch"
fi

echo "==> applying ${#patches[@]} patch(es) with git am"
git am "${patches[@]}"

echo
echo "==> ready"
echo "    workdir: $workdir"
echo "    branch:  $branch"
echo
echo "Review with:"
echo "    git -C $workdir log --oneline origin/$ref..$branch"
echo "    git -C $workdir log -p origin/$ref..$branch"
echo
echo "When ready to ship:"
echo "    git -C $workdir remote add fork git@github.com:<you>/tt-metal.git"
echo "    git -C $workdir push -u fork $branch"
echo "    gh pr create --repo tenstorrent/tt-metal --base $ref --head <you>:$branch"
