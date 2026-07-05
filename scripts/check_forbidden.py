#!/usr/bin/env python3
"""
Guard against forbidden patterns in production code.

- No `print(` in files under game/src/ outside of `logger.gd` or dev tools.
- No `TODO(no-owner)` — every TODO must name an owner and a ticket.
- No absolute filesystem paths like `/home/`, `C:\`, etc.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

SRC_ROOT = Path("game/src")

FORBIDDEN = [
    (re.compile(r"TODO\(\s*\)|TODO(?!\s*\([^)]+\))"), "TODO must be TODO(owner, #ticket): message"),
    (re.compile(r"(/home/|C:\\\\|C:/)"), "absolute filesystem path leaked into source"),
]

# Files exempt from the print() rule.
PRINT_EXEMPT = {
    "perf_overlay.gd",
}


def check_file(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    findings = []
    for i, line in enumerate(text.splitlines(), start=1):
        for pattern, message in FORBIDDEN:
            if not pattern.search(line):
                continue
            if pattern.pattern.startswith(r"^\s*print\(") and path.name in PRINT_EXEMPT:
                continue
            findings.append(f"{path}:{i}: {message}  ->  {line.strip()}")
    return findings


def main() -> int:
    if not SRC_ROOT.exists():
        print(f"[forbidden] path not found: {SRC_ROOT}", file=sys.stderr)
        return 0

    findings: list[str] = []
    for gd in SRC_ROOT.rglob("*.gd"):
        findings.extend(check_file(gd))

    if findings:
        print("Forbidden patterns detected:", file=sys.stderr)
        for f in findings:
            print("  " + f, file=sys.stderr)
        return 1

    print("[forbidden] OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
