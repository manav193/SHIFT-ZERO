#!/usr/bin/env bash
# Run all unit tests headlessly via GUT.
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"

"$GODOT_BIN" --headless --path game \
    -s addons/gut/gut_cmdln.gd \
    -gdir=res://tests/unit -gexit
