# ADR-007 — Modifier registry pattern

**Status:** Accepted
**Date:** 2026-01
**Related requirements:** NFR-MAINT-03

## Context

We plan 15+ modifiers at v1.0 and expect the catalogue to grow through post-launch updates. If adding a modifier requires editing engine code, we bottleneck on engineers.

## Decision

Every modifier is:
1. A `.gd` file under `gameplay/modifiers/` implementing the `IModifier` interface.
2. A metadata `.tres` under `data/modifiers/`.
3. Registered by appending its `.tres` to `data/modifiers/registry.tres`.

`ModifierManager` reads the registry at boot; no code edits are needed to add a modifier.

## Consequences

**Positive**
- Designers can add + tune modifiers with minimal engineer time.
- Compatibility matrix lives in data.
- Feature-flag rollout per modifier is trivial.

**Negative**
- One indirection at boot to scan the registry.

## Alternatives considered

- **Hardcoded list in `ModifierManager`** — engineering bottleneck.
- **Auto-scan the folder** — implicit; harder to reason about ordering + compatibility rules.

## References

- `docs/03_ARCHITECTURE.md §10`
- `docs/04_FOLDER_STRUCTURE.md`
