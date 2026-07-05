#!/usr/bin/env bash
# Build a debug AAB.
# NOTE: Requires local Godot 4.3+ install and Android export template configured.
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
OUT_DIR="game/dist/android"
mkdir -p "$OUT_DIR"

"$GODOT_BIN" --headless --path game \
    --export-debug "Android" "$OUT_DIR/shiftzero-debug.aab"

echo "AAB: $OUT_DIR/shiftzero-debug.aab"
