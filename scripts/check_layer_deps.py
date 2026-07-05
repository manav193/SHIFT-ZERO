#!/usr/bin/env python3
"""
Layer-dependency guard for SHIFT // ZERO.

Enforces the layered architecture defined in docs/03_ARCHITECTURE.md §2:

    presentation → gameplay → systems → services → core

A layer may only reference itself or layers strictly below it.

Usage:
    python scripts/check_layer_deps.py game/src
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

LAYERS = ["core", "services", "systems", "gameplay", "presentation", "app"]

# Allowed dependency graph.
# key = layer, value = set of layers that key may reference.
ALLOWED = {
    "core": {"core"},
    "services": {"core", "services"},
    "systems": {"core", "services", "systems"},
    "gameplay": {"core", "services", "systems", "gameplay"},
    "presentation": {"core", "services", "systems", "gameplay", "presentation"},
    # `app` is bootstrap glue — allowed to touch anything.
    "app": set(LAYERS),
}

# Matches preload("res://src/<layer>/...") and load("res://src/<layer>/...")
LOAD_RE = re.compile(r'(?:preload|load)\s*\(\s*"res://src/([a-z_]+)/')


def detect_layer(path: Path) -> str | None:
    parts = path.parts
    try:
        i = parts.index("src")
    except ValueError:
        return None
    if i + 1 >= len(parts):
        return None
    layer = parts[i + 1]
    return layer if layer in LAYERS else None


def check_file(path: Path) -> list[str]:
    layer = detect_layer(path)
    if layer is None:
        return []
    text = path.read_text(encoding="utf-8", errors="ignore")
    violations = []
    for m in LOAD_RE.finditer(text):
        target = m.group(1)
        if target not in LAYERS:
            continue
        if target not in ALLOWED[layer]:
            line_no = text.count("\n", 0, m.start()) + 1
            violations.append(
                f"{path}:{line_no}: layer '{layer}' cannot depend on '{target}' "
                f"(loaded: res://src/{target}/...)"
            )
    return violations


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "game/src")
    if not root.exists():
        print(f"[layer-deps] path not found: {root}", file=sys.stderr)
        return 0  # non-blocking during initial scaffold

    violations: list[str] = []
    for gd in root.rglob("*.gd"):
        violations.extend(check_file(gd))

    if violations:
        print("Layer dependency violations found:", file=sys.stderr)
        for v in violations:
            print("  " + v, file=sys.stderr)
        return 1

    print("[layer-deps] OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
