#!/usr/bin/env bash

set -euo pipefail

TT_METAL_DIR="${1:-tt-metal}"
LLK_TESTS_DIR="${TT_METAL_DIR}/tt_metal/tt-llk/tests"

if [[ ! -d "${LLK_TESTS_DIR}" ]]; then
    echo "ERROR: LLK tests directory not found: ${LLK_TESTS_DIR}" >&2
    exit 1
fi

ARCHITECTURE="${TTSIM_ARCHITECTURE:-blackhole}"
WORKERS="${TTSIM_WORKERS:-0}"
TIMEOUT_SECONDS="${TTSIM_TIMEOUT_SECONDS:-300}"
TEST_TARGET="${TTSIM_TEST_TARGET:-auto}"
export TTSIM_CACHE_DIR="${TTSIM_CACHE_DIR:-${PWD}/ttsim-cache}"

echo "tt-metal directory : ${TT_METAL_DIR}"
echo "LLK tests directory: ${LLK_TESTS_DIR}"
echo "ttsim architecture : ${ARCHITECTURE}"
echo "test target        : ${TEST_TARGET}"
echo "timeout seconds    : ${TIMEOUT_SECONDS}"
echo "workers            : ${WORKERS}"

pushd "${LLK_TESTS_DIR}" >/dev/null

source ./setup_external_testing_env.sh --reuse

if [[ "${TEST_TARGET}" == "auto" ]]; then
    collect_log="$(mktemp)"
    (
        cd python_tests
        pytest --collect-only -q test_eltwise_unary_datacopy.py
    ) >"${collect_log}"
    TEST_TARGET="$(
        grep -F 'test_eltwise_unary_datacopy.py::test_unary_datacopy[' "${collect_log}" \
            | grep -F 'formats::Float16_b->Float16_b' \
            | grep -F 'dest_acc::No' \
            | grep -F 'num_faces::4' \
            | grep -F 'tilize::No' \
            | grep -F 'input_dimensions::[64, 64]' \
            | head -n1
    )"
    if [[ -z "${TEST_TARGET}" ]]; then
        echo "ERROR: failed to auto-select the Float16_b no-tilize datacopy smoke target" >&2
        sed -n '1,80p' "${collect_log}" >&2
        rm -f "${collect_log}"
        exit 1
    fi
    rm -f "${collect_log}"
    echo "auto-selected test target: ${TEST_TARGET}"
fi

./run_ttsim_regression.sh \
    --architecture "${ARCHITECTURE}" \
    --workers "${WORKERS}" \
    --timeout "${TIMEOUT_SECONDS}" \
    "${TEST_TARGET}"

popd >/dev/null
