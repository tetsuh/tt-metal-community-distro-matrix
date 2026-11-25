#!/usr/bin/env bash

set -euo pipefail

TT_METAL_DIR="${1:-tt-metal}"
LLK_TESTS_DIR="${TT_METAL_DIR}/tt_metal/tt-llk/tests"

if [[ ! -d "${LLK_TESTS_DIR}" ]]; then
    echo "ERROR: LLK tests directory not found: ${LLK_TESTS_DIR}" >&2
    exit 1
fi

ARCHITECTURE="${TTSIM_ARCHITECTURE:-blackhole}"
TIMEOUT_SECONDS="${TTSIM_TIMEOUT_SECONDS:-300}"
# TTSIM_TEST_TARGET is the pytest file or node id. Keep pytest options in
# dedicated env vars so filters are passed as arguments, not shell-evaled text.
TEST_TARGET="${TTSIM_TEST_TARGET:-test_risc_compute.py::test_risc_compute}"
PYTEST_K_EXPR="${TTSIM_PYTEST_K_EXPR:-}"
REPORT_NAME="${TTSIM_REPORT_NAME:-ttsim-smoke}"

if [[ ! "${REPORT_NAME}" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "ERROR: TTSIM_REPORT_NAME contains unsupported characters: ${REPORT_NAME}" >&2
    exit 1
fi

echo "tt-metal directory : ${TT_METAL_DIR}"
echo "LLK tests directory: ${LLK_TESTS_DIR}"
echo "ttsim architecture : ${ARCHITECTURE}"
echo "test target        : ${TEST_TARGET}"
echo "pytest -k expr     : ${PYTEST_K_EXPR:-<none>}"
echo "timeout seconds    : ${TIMEOUT_SECONDS}"
echo "report name        : ${REPORT_NAME}"

# Upstream pins a release tag; the release asset metadata supplies its SHA-256.
ttsim_repo=tenstorrent/ttsim
version_file="${TT_METAL_DIR}/tt_metal/ttsim-version"
if [[ ! -f "${version_file}" ]]; then
    echo "ERROR: ttsim pin file not found: ${version_file}" >&2
    exit 1
fi
ttsim_tag="$(tr -d '[:space:]' < "${version_file}")"
if [[ -z "${ttsim_tag}" ]]; then
    echo "ERROR: ${version_file} is empty; expected a ${ttsim_repo} release tag" >&2
    exit 1
fi
echo "ttsim tag          : ${ttsim_tag}"

pushd "${LLK_TESTS_DIR}" >/dev/null

source ./setup_external_testing_env.sh --reuse

case "${ARCHITECTURE}" in
    blackhole|bh)
        so_name="libttsim_bh.so"
        soc_src="../../soc_descriptors/blackhole_140_arch.yaml"
        ;;
    wormhole|wormhole_b0|wh)
        so_name="libttsim_wh.so"
        soc_src="../../soc_descriptors/wormhole_b0_80_arch.yaml"
        ;;
    *)
        echo "ERROR: unknown TTSIM_ARCHITECTURE: ${ARCHITECTURE}" >&2
        exit 1
        ;;
esac

api_url="https://api.github.com/repos/${ttsim_repo}/releases/tags/${ttsim_tag}"
release_json="$(curl -fsSL --retry 5 --retry-delay 2 "${api_url}")"
expected_digest="$(python3 -c '
import json, sys
for asset in json.load(sys.stdin).get("assets", []):
    if asset.get("name") == sys.argv[1]:
        print(asset.get("digest") or "")
        break
' "${so_name}" <<<"${release_json}")"
if [[ ! "${expected_digest}" =~ ^sha256:[0-9a-f]{64}$ ]]; then
    echo "ERROR: no valid SHA-256 digest for ${so_name} in ${api_url}" >&2
    exit 1
fi

# The simulator is small enough to download and verify on every run.
sim_dir="$(mktemp -d)"
trap 'rm -rf -- "${sim_dir}"' EXIT
so_path="${sim_dir}/${so_name}"
url="https://github.com/${ttsim_repo}/releases/download/${ttsim_tag}/${so_name}"
curl -fsSL --retry 5 --retry-delay 2 -o "${so_path}" "${url}"
printf '%s  %s\n' "${expected_digest#sha256:}" "${so_path}" | sha256sum --check

cp "${soc_src}" "${sim_dir}/soc_descriptor.yaml"
mkdir -p python_tests/ttsim_results

export TT_METAL_SIMULATOR="${so_path}"
export TT_METAL_SLOW_DISPATCH_MODE="${TT_METAL_SLOW_DISPATCH_MODE:-1}"
export DISABLE_SFPLOADMACRO="${DISABLE_SFPLOADMACRO:-1}"
export TT_METAL_DISABLE_SFPLOADMACRO="${TT_METAL_DISABLE_SFPLOADMACRO:-1}"

pytest_extra_args=()
if [[ -n "${PYTEST_K_EXPR}" ]]; then
    pytest_extra_args+=(-k "${PYTEST_K_EXPR}")
fi

(
    cd python_tests
    pytest -v \
        -p no:sugar \
        --run-simulator \
        --timeout="${TIMEOUT_SECONDS}" \
        --junit-xml="ttsim_results/${REPORT_NAME}.xml" \
        -o junit_logging=system-out \
        -o junit_log_passing_tests=False \
        -o log_cli=false \
        "${pytest_extra_args[@]}" \
        "${TEST_TARGET}"
)

popd >/dev/null
