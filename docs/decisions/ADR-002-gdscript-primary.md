# ADR-002 — GDScript primary, C# escape hatch

**Status:** Accepted
**Date:** 2026-01

## Context

Godot 4 supports GDScript (native) and C# (via .NET 8). Both compile to bytecode; both are usable in production.

## Decision

We will use **GDScript 2.0 for ~90% of the codebase**, and reserve **C# for narrowly-scoped hot paths** — deterministic fixed-point math (if needed) and any collision/broadphase code that measurably benefits from static compilation.

## Consequences

**Positive**
- Fastest iteration (no compile step).
- Lowest onboarding cost for contributors.
- Adequate performance for a 2D game with our sprite/particle budgets.

**Negative**
- If we need C# in one module, we ship the .NET runtime → ~10 MB Android footprint hit. Acceptable but a factor.
- Two languages to maintain style guides for.

## Alternatives considered

- **All GDScript** — simplest, but no escape hatch if we hit a perf wall.
- **All C#** — statically compiled, but slower iteration and heavier runtime.

## References

- `docs/07_CODING_STANDARDS.md §2, §3`
