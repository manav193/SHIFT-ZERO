#!/usr/bin/env bash
# Build the HTML5 (Web) release.
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
OUT_DIR="game/dist/web"
mkdir -p "$OUT_DIR"

"$GODOT_BIN" --headless --path game \
    --export-release "Web" "$OUT_DIR/index.html"

echo "Web: $OUT_DIR/index.html"
