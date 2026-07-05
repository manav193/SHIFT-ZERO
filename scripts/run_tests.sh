#!/usr/bin/env bash
# Run all unit tests headlessly via GUT.
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
GUT_VERSION="${GUT_VERSION:-9.7.0}"
GUT_URL="https://github.com/bitwes/Gut/archive/refs/tags/v${GUT_VERSION}.zip"
GUT_DIR="game/addons/gut"

ensure_gut() {
    if [[ -f "${GUT_DIR}/gut_cmdln.gd" ]]; then
        return
    fi

    if ! command -v curl >/dev/null 2>&1; then
        echo "curl is required to install GUT ${GUT_VERSION}" >&2
        exit 1
    fi
    if ! command -v unzip >/dev/null 2>&1; then
        echo "unzip is required to install GUT ${GUT_VERSION}" >&2
        exit 1
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' EXIT

    echo "[gut] installing GUT ${GUT_VERSION}"
    curl -fsSL "${GUT_URL}" -o "${tmp_dir}/gut.zip"
    unzip -q "${tmp_dir}/gut.zip" -d "${tmp_dir}"
    mkdir -p "game/addons"
    cp -R "${tmp_dir}/Gut-${GUT_VERSION}/addons/gut" "${GUT_DIR}"
}

ensure_gut

"$GODOT_BIN" --headless --path game \
    -s addons/gut/gut_cmdln.gd \
    -gdir=res://tests/unit -ginclude_subdirs -gexit
