#!/usr/bin/env bash
# Run a single tt-installer "leg" (vanilla or patched) inside a fresh
# container of the target distro and emit GITHUB_OUTPUT entries that
# capture the post-condition.
#
# Usage:
#   scripts/install-phase-leg.sh <leg> <image_tag> <install_sh_path> <log_path> <installer_version>
#
# Where:
#   <leg>               "vanilla" | "patched" -- used as the suffix for
#                       the GITHUB_OUTPUT keys (install_status_<leg>,
#                       install_repo_present_<leg>, etc.).
#   <image_tag>         Docker image to run (already built by an earlier
#                       step).
#   <install_sh_path>   Path on the runner host to install.sh that should
#                       be mounted into the container as /tmp/install.sh
#                       and invoked.
#   <log_path>          Where to tee the captured output for upload as a
#                       workflow artifact.
#   <installer_version> Pinned tt-installer release name (recorded only;
#                       the actual install.sh comes from <install_sh_path>).
#
# The script never `exit 1`s on installer failure -- it always records
# the result in GITHUB_OUTPUT so the matrix continues. It only exits
# non-zero on its own argument / docker invocation errors.

set -o pipefail

leg="${1:?leg required (vanilla|patched)}"
image_tag="${2:?image_tag required}"
install_sh_path="${3:?install_sh_path required}"
log_path="${4:?log_path required}"
installer_version="${5:?installer_version required}"

if [ ! -f "${install_sh_path}" ]; then
  echo "::error::install.sh not found at ${install_sh_path}"
  exit 2
fi

mkdir -p "$(dirname "${log_path}")"

echo "::group::tt-installer ${installer_version} (${leg}) on ${image_tag}"
set +e
docker run --rm \
  -v "${install_sh_path}:/tmp/install.sh:ro" \
  -e INSTALLER_VERSION="${installer_version}" \
  -e INSTALL_LEG="${leg}" \
  "${image_tag}" \
  bash -lc '
    set -u
    cat /etc/os-release
    # On Ubuntu derivatives the installer needs UBUNTU_CODENAME; we
    # log it here so failures are easier to diagnose without
    # re-running the matrix.
    if grep -q "^UBUNTU_CODENAME=" /etc/os-release 2>/dev/null; then
      echo "UBUNTU_CODENAME present: $(grep ^UBUNTU_CODENAME= /etc/os-release)"
    else
      echo "UBUNTU_CODENAME absent"
    fi

    # Bring the base image up to a state where tt-installer can
    # operate (curl/sudo/ca-certificates). Detect the package
    # manager rather than branching on the matrix target so each
    # base image is handled by its own family.
    if command -v apt-get >/dev/null 2>&1; then
      apt-get update
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        curl ca-certificates sudo
    elif command -v dnf >/dev/null 2>&1; then
      dnf install -y --allowerasing curl ca-certificates sudo
    else
      echo "::error::no supported package manager (apt-get/dnf) found" >&2
      exit 1
    fi

    cp /tmp/install.sh /tmp/install.sh.run
    chmod +x /tmp/install.sh.run

    set +e
    # Skip everything that needs hardware, kernel headers, or
    # external image pulls; we only validate that the installer
    # registers the Tenstorrent package repository.
    /tmp/install.sh.run \
      --mode-non-interactive \
      --no-install-kmd \
      --no-install-hugepages \
      --install-container-runtime=no \
      --no-install-tt-flash \
      --no-install-tt-smi \
      --no-install-tt-topology \
      --no-install-sfpi \
      --no-install-inference-server \
      --no-install-studio \
      --no-install-metalium-container \
      --no-install-forge-container \
      --update-firmware=off \
      --reboot-option=never
    installer_rc=$?
    set -e

    # Post-condition: the installer must register the Tenstorrent
    # package source. Search by content (not filename) across all
    # the locations apt and yum/dnf look at. `grep -R` would exit 2
    # on missing paths so we use find | xargs grep -l instead.
    : > /tmp/repo-hits
    find /etc/apt/sources.list \
         /etc/apt/sources.list.d \
         /etc/yum.repos.d \
         -type f 2>/dev/null \
      | xargs -r grep -li "tenstorrent" 2>/dev/null \
      > /tmp/repo-hits || true
    if [ -s /tmp/repo-hits ]; then
      repo_files=$(tr "\n" "," < /tmp/repo-hits | sed "s/,$//")
      repo_present=true
    else
      repo_files=""
      repo_present=false
    fi

    echo "INSTALLER_RC=${installer_rc}"
    echo "REPO_PRESENT=${repo_present}"
    echo "REPO_FILES=${repo_files}"
    exit "${installer_rc}"
  ' 2>&1 | tee "${log_path}"
overall_rc=${PIPESTATUS[0]}
set -e
echo "::endgroup::"

# Parse the structured markers from the captured log so the workflow
# step output reflects the in-container state even after --rm.
repo_present=$(grep -E '^REPO_PRESENT=' "${log_path}" | tail -n1 | cut -d= -f2)
repo_files=$(grep -E '^REPO_FILES='   "${log_path}" | tail -n1 | cut -d= -f2-)
repo_present=${repo_present:-false}

if [ "${overall_rc}" -eq 0 ] && [ "${repo_present}" = "true" ]; then
  install_status=success
else
  install_status=failure
fi

if [ -z "${GITHUB_OUTPUT:-}" ]; then
  echo "::warning::GITHUB_OUTPUT not set; emitting to stdout instead"
  out=/dev/stdout
else
  out="${GITHUB_OUTPUT}"
fi

{
  echo "install_status_${leg}=${install_status}"
  echo "install_repo_present_${leg}=${repo_present}"
  echo "install_repo_files_${leg}=${repo_files}"
  echo "install_installer_rc_${leg}=${overall_rc}"
} >> "${out}"

echo "tt-installer ${installer_version} ${leg}: ${install_status} (rc=${overall_rc}, repo_present=${repo_present})"
