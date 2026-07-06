#!/usr/bin/env bash
# Build a debug APK.
# NOTE: Requires local Godot 4.3+ install and Android export template configured.
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
OUT_DIR="dist/android"
mkdir -p "game/$OUT_DIR"

"$GODOT_BIN" --headless --path game \
    --export-debug "Android" "$OUT_DIR/shiftzero-debug.apk"

echo "APK: $OUT_DIR/shiftzero-debug.apk"
