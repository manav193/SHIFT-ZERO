#!/usr/bin/env bash
# First-time contributor setup for SHIFT // ZERO.
set -euo pipefail

echo "== SHIFT // ZERO :: bootstrap =="

# 1. Python tooling for CI parity locally
if command -v python3 >/dev/null 2>&1; then
    python3 -m pip install --user --upgrade "gdtoolkit==4.*"
else
    echo "!! python3 not found. Install Python 3.11+ then re-run."
    exit 1
fi

# 2. Godot editor reminder
cat <<'EOF'

Next steps:
  1. Install Godot 4.3+ (Standard build): https://godotengine.org/download
  2. Open the project by pointing Godot at:  game/project.godot
  3. Let Godot import assets (first run only, ~30 seconds).
  4. Press F5 to run the boot scene.

For CI parity locally, run:
  gdlint game/src
  python3 scripts/check_layer_deps.py game/src
  python3 scripts/check_forbidden.py

EOF
