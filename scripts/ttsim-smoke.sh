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
PYTEST_FILTER="${TTSIM_PYTEST_FILTER:-Float16_b and not tilize}"
export TTSIM_CACHE_DIR="${TTSIM_CACHE_DIR:-${PWD}/ttsim-cache}"

echo "tt-metal directory : ${TT_METAL_DIR}"
echo "LLK tests directory: ${LLK_TESTS_DIR}"
echo "ttsim architecture : ${ARCHITECTURE}"
echo "pytest filter      : ${PYTEST_FILTER}"
echo "timeout seconds    : ${TIMEOUT_SECONDS}"
echo "workers            : ${WORKERS}"

pushd "${LLK_TESTS_DIR}" >/dev/null

source ./setup_external_testing_env.sh --reuse

./run_ttsim_regression.sh \
    --architecture "${ARCHITECTURE}" \
    --workers "${WORKERS}" \
    --timeout "${TIMEOUT_SECONDS}" \
    test_eltwise_unary_datacopy.py \
    -- -k "${PYTEST_FILTER}"

popd >/dev/null
