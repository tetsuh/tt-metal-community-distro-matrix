#!/usr/bin/env bash
# Generate two install.sh variants for the install-phase verification:
#
#   /tmp/install-vanilla.sh   exact released install.sh (pristine upstream)
#   /tmp/install-patched.sh   regenerated from install.m4 with this
#                             repo's patches/<distro>/installer/*.patch
#                             applied
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
cp "${stage}/install.sh" /tmp/install-vanilla.sh
chmod +x /tmp/install-vanilla.sh
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
  echo "::group::Install argbash + m4 (host)"
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    argbash m4 patch
  argbash_version="$(argbash --version 2>&1 | head -n1)"
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
  argbash "${stage}/install.m4" -o "${stage}/install.regen.sh"
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
  # install.m4. Each patch's diff path is "a/install.m4" -> "b/install.m4"
  # so -p1 strips the a/b/ prefix and targets the file in -d.
  while IFS= read -r p; do
    echo "Applying $(basename "${p}")"
    patch -p1 -d "${stage}" -i "$(realpath "${p}")" --forward --silent || {
      echo "::error::failed to apply ${p}"
      exit 1
    }
  done < <(find "${patch_dir}" -maxdepth 1 -name '*.patch' -type f | sort)
  cp "${stage}/install.m4" "${stage}/install.m4.patched"
  echo "::endgroup::"

  echo "::group::Regenerate install-patched.sh"
  argbash "${stage}/install.m4.patched" -o /tmp/install-patched.sh
  chmod +x /tmp/install-patched.sh
  echo "patched install.sh size: $(wc -c </tmp/install-patched.sh) bytes"
  echo "::endgroup::"
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "install_patch_count=${patch_count}"
    echo "argbash_version=${argbash_version}"
    echo "patch_dir=${patch_dir}"
  } >> "${GITHUB_OUTPUT}"
fi

echo "install_patch_count=${patch_count}"
echo "argbash_version=${argbash_version}"
