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
TTSIM_CACHE_DIR="${TTSIM_CACHE_DIR:-${PWD}/ttsim-cache}"
export TTSIM_CACHE_DIR="$(realpath -m "${TTSIM_CACHE_DIR}")"

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

pushd "${LLK_TESTS_DIR}" >/dev/null

source ./setup_external_testing_env.sh --reuse

case "${ARCHITECTURE}" in
    blackhole|bh)
        ARCHITECTURE="blackhole"
        so_name="libttsim_bh.so"
        soc_src="../../soc_descriptors/blackhole_140_arch.yaml"
        hash_var="ttsim_bh_so_hash"
        ;;
    wormhole|wormhole_b0|wh)
        ARCHITECTURE="wormhole"
        so_name="libttsim_wh.so"
        soc_src="../../soc_descriptors/wormhole_b0_80_arch.yaml"
        hash_var="ttsim_wh_so_hash"
        ;;
    *)
        echo "ERROR: unknown TTSIM_ARCHITECTURE: ${ARCHITECTURE}" >&2
        exit 1
        ;;
esac

source ./ttsim-version

cache_dir="${TTSIM_CACHE_DIR}/${ttsim_version}/${ARCHITECTURE}"
so_path="${cache_dir}/${so_name}"
soc_path="${cache_dir}/soc_descriptor.yaml"
url="${ttsim_repo}/releases/download/${ttsim_tag}/${so_name}"
expected_hash="${!hash_var}"

mkdir -p "${cache_dir}" python_tests/ttsim_results

need_download=1
if [[ -f "${so_path}" ]]; then
    got="$("${ttsim_hashtype}sum" "${so_path}" | awk '{print $1}')"
    if [[ "${got}" == "${expected_hash}" ]]; then
        need_download=0
    else
        echo "Cached ${so_name} ${ttsim_hashtype} mismatch; re-downloading" >&2
    fi
fi

if [[ "${need_download}" -eq 1 ]]; then
    tmp="${so_path}.tmp.$$"
    curl -fSL --retry 5 --retry-delay 2 -o "${tmp}" "${url}"
    got="$("${ttsim_hashtype}sum" "${tmp}" | awk '{print $1}')"
    if [[ "${got}" != "${expected_hash}" ]]; then
        rm -f "${tmp}"
        echo "ERROR: ${ttsim_hashtype} mismatch for ${so_name} (got=${got} expected=${expected_hash})" >&2
        exit 1
    fi
    mv "${tmp}" "${so_path}"
fi

cp -f "${soc_src}" "${soc_path}"

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
