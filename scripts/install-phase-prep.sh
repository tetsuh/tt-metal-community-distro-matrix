#!/usr/bin/env bash
# Generate two install.sh variants for the install-phase verification:
#
#   /tmp/install-vanilla.sh   exact released install.sh (pristine upstream)
#   /tmp/install-patched.sh   released install.sh with the
#                             install_tt_repos block replaced by the
#                             patched version regenerated from
#                             install.m4 via argbash (the rest of the
#                             released install.sh, including the
#                             build-time-inlined ttis.sh helpers, is
#                             preserved verbatim)
#
# Usage:
#   scripts/install-phase-prep.sh <distro> <installer_version> \
#       <installer_sha256> <installer_m4_sha256> [<patches_root>]
#
# Emits to GITHUB_OUTPUT:
#   install_patch_count   integer count of *.patch files applied
#   argbash_version       runtime argbash version (empty if no patches)
#
# Requires the runner to have apt-get available (ubuntu-latest does).

set -euo pipefail

distro="${1:?distro required}"
installer_version="${2:?installer_version required}"
installer_sha256="${3:?installer_sha256 required}"
installer_m4_sha256="${4:?installer_m4_sha256 required}"
patches_root="${5:-patches}"

stage="${RUNNER_TEMP:-/tmp}/install-phase-prep"
out_dir="${RUNNER_TEMP:-/tmp}"
rm -rf "${stage}"
mkdir -p "${stage}"

base_url="https://github.com/tenstorrent/tt-installer/releases/download/${installer_version}"
m4_url="https://raw.githubusercontent.com/tenstorrent/tt-installer/refs/tags/${installer_version}/install.m4"

echo "::group::Download released install.sh (${installer_version})"
curl -fL --retry 3 --retry-delay 5 -o "${stage}/install.sh" \
  "${base_url}/install.sh"
got=$(sha256sum "${stage}/install.sh" | awk '{print $1}')
if [ "${got}" != "${installer_sha256}" ]; then
  echo "::error::install.sh sha256 mismatch: got ${got}, expected ${installer_sha256}"
  exit 1
fi
echo "install.sh sha256 OK (${got})"
cp "${stage}/install.sh" "${out_dir}/install-vanilla.sh"
chmod +x "${out_dir}/install-vanilla.sh"
echo "::endgroup::"

patch_dir="${patches_root}/${distro}/installer"
patch_count=0
argbash_version=""
if [ -d "${patch_dir}" ]; then
  patch_count=$(find "${patch_dir}" -maxdepth 1 -name '*.patch' -type f | wc -l | tr -d ' ')
fi

if [ "${patch_count}" -eq 0 ]; then
  echo "No installer patches for ${distro}; skipping argbash regeneration."
else
  echo "::group::Install argbash (release tarball) + m4/patch (apt)"
  # argbash is not in ubuntu-latest's default apt sources, so pull a
  # pinned release tarball directly from GitHub. argbash itself is a
  # pure bash script; it just needs m4 + patch from apt.
  argbash_release="${ARGBASH_VERSION:-2.10.0}"
  argbash_tarball_url="https://github.com/matejak/argbash/archive/refs/tags/${argbash_release}.tar.gz"
  curl -fL --retry 3 --retry-delay 5 -o "${stage}/argbash.tar.gz" "${argbash_tarball_url}"
  tar -xzf "${stage}/argbash.tar.gz" -C "${stage}"
  argbash_bin="${stage}/argbash-${argbash_release}/bin/argbash"
  if [ ! -x "${argbash_bin}" ]; then
    echo "::error::argbash binary not found at ${argbash_bin} after extracting ${argbash_tarball_url}"
    exit 1
  fi
  sudo DEBIAN_FRONTEND=noninteractive apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    m4 patch
  argbash_version="$("${argbash_bin}" --version 2>&1 | head -n1)"
  echo "argbash: ${argbash_version}"
  echo "::endgroup::"

  echo "::group::Download install.m4 (${installer_version})"
  curl -fL --retry 3 --retry-delay 5 -o "${stage}/install.m4" "${m4_url}"
  got_m4=$(sha256sum "${stage}/install.m4" | awk '{print $1}')
  if [ "${got_m4}" != "${installer_m4_sha256}" ]; then
    echo "::error::install.m4 sha256 mismatch: got ${got_m4}, expected ${installer_m4_sha256}"
    exit 1
  fi
  echo "install.m4 sha256 OK (${got_m4})"
  echo "::endgroup::"

  echo "::group::Pristine argbash regeneration sanity check"
  # Regenerate install.sh from the *unpatched* install.m4 and confirm
  # that the install_tt_repos function (which is what our patches
  # target) is byte-for-byte identical to the released install.sh.
  # This bounds argbash drift: we accept differences anywhere else
  # in install.sh but require parity in the block we patch.
  "${argbash_bin}" "${stage}/install.m4" -o "${stage}/install.regen.sh"
  python3 - "${stage}/install.sh" "${stage}/install.regen.sh" <<'PY'
import re
import sys

def extract(path):
    text = open(path, encoding="utf-8").read()
    m = re.search(
        r"^install_tt_repos \(\) \{.*?^\}\n",
        text,
        re.DOTALL | re.MULTILINE,
    )
    if not m:
        print(f"::error::install_tt_repos function not found in {path}", file=sys.stderr)
        sys.exit(2)
    return m.group(0)

released, regen = sys.argv[1], sys.argv[2]
a = extract(released)
b = extract(regen)
if a != b:
    print("::error::install_tt_repos block differs between released install.sh and pristine argbash regeneration", file=sys.stderr)
    print("--- released ---", file=sys.stderr)
    print(a, file=sys.stderr)
    print("--- regen ---", file=sys.stderr)
    print(b, file=sys.stderr)
    sys.exit(1)
print("install_tt_repos block parity OK")
PY
  echo "::endgroup::"

  echo "::group::Apply ${patch_count} patch(es) from ${patch_dir}"
  # Apply patches sequentially in lexicographic order onto the staged
  # install.m4. The patches are git format-patch output, so we use
  # ``git apply`` (which understands the ``index 0000000..0000001``
  # header) rather than GNU ``patch`` (which mis-reads that as a
  # /dev/null source and treats the diff as a file-creation patch).
  while IFS= read -r p; do
    echo "Applying $(basename "${p}")"
    abs_patch=$(realpath "${p}")
    ( cd "${stage}" && git apply --whitespace=nowarn -p1 "${abs_patch}" ) || {
      echo "::error::failed to apply ${p}"
      exit 1
    }
  done < <(find "${patch_dir}" -maxdepth 1 -name '*.patch' -type f | sort)
  cp "${stage}/install.m4" "${stage}/install.m4.patched"
  echo "::endgroup::"

  echo "::group::Splice patched install_tt_repos into released install.sh"
  # tt-installer v3.1.0+ inlines ttis.sh into install.sh at build time
  # (upstream scripts/inline-ttis.sh), so install.m4 alone can no longer
  # reproduce a working install.sh via argbash -- a fully regenerated
  # script lacks the inlined helpers (e.g. ttis_import_versions) and
  # aborts with rc=127 once the installer reaches the golden-versions
  # fetch. Keep the released install.sh (helpers already inlined) and
  # replace only the install_tt_repos block -- the sole function our
  # patches touch -- with the patched version produced from the patched
  # install.m4. The pristine parity check above guarantees argbash
  # reproduces that block byte-for-byte, so splicing it back into the
  # released script is exact.
  "${argbash_bin}" "${stage}/install.m4.patched" -o "${stage}/install.regen.patched.sh"
  python3 - \
    "${stage}/install.sh" \
    "${stage}/install.regen.patched.sh" \
    "${out_dir}/install-patched.sh" <<'PY'
import re
import sys

_BLOCK = re.compile(
    r"^install_tt_repos \(\) \{.*?^^\}\n",
    re.DOTALL | re.MULTILINE,
)

def locate(text, path):
    m = _BLOCK.search(text)
    if not m:
        print(f"::error::install_tt_repos block not found in {path}", file=sys.stderr)
        sys.exit(2)
    return m.span()

released_path, patched_regen_path, out_path = sys.argv[1:4]
released = open(released_path, encoding="utf-8").read()
patched_regen = open(patched_regen_path, encoding="utf-8").read()

r_start, r_end = locate(released, released_path)
p_start, p_end = locate(patched_regen, patched_regen_path)

spliced = released[:r_start] + patched_regen[p_start:p_end] + released[r_end:]
open(out_path, "w", encoding="utf-8").write(spliced)
print(
    f"spliced install_tt_repos: released[{r_start}:{r_end}] "
    f"<- patched_regen[{p_start}:{p_end}]"
)
PY
  chmod +x "${out_dir}/install-patched.sh"
  # Syntax-check the spliced script before handing it to the leg runner.
  if ! bash -n "${out_dir}/install-patched.sh"; then
    echo "::error::spliced install-patched.sh failed bash -n syntax check"
    exit 1
  fi
  echo "patched install.sh size: $(wc -c <"${out_dir}/install-patched.sh") bytes"
  echo "::endgroup::"
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "install_patch_count=${patch_count}"
    echo "argbash_version=${argbash_version}"
    echo "patch_dir=${patch_dir}"
    echo "install_sh_vanilla=${out_dir}/install-vanilla.sh"
    echo "install_sh_patched=${out_dir}/install-patched.sh"
  } >> "${GITHUB_OUTPUT}"
fi

echo "install_patch_count=${patch_count}"
echo "argbash_version=${argbash_version}"
