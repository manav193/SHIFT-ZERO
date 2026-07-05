# ADR-011 — Data-driven gameplay values

**Status:** Accepted
**Date:** 2026-01
**Related requirements:** User addition A5 (session 2), NFR-MAINT-*

## Context

Hardcoded magic numbers (speed, gravity, modifier durations, reward drops) cause three problems:
1. Designers can't tune without pinging engineers.
2. Balancing patches require full app updates.
3. Testing edge cases requires re-compilation.

## Decision

**Nothing gameplay-affecting is a magic number.** All tunables live in typed `.tres` Resources under `data/`, accessed through `GameplayConfig.get_*(...)`. The wrapper enforces the three-layer lookup (Remote Config → build defaults → hardcoded fallback). Custom `Resource` subclasses define the schemas.

Concrete `.tres` schemas locked in M0:
- `GameplayConfig`, `DifficultyCurve`, `ModifierDefinition`, `ObstaclePattern`, `CosmeticDefinition`, `RewardTable`, `AdConfig`, `SfxBank`.

## Consequences

**Positive**
- Live tuning via Remote Config from v1.0.
- Designers own the numbers, not engineers.
- Playtest telemetry can propose rebalances that ship without a build.

**Negative**
- One more indirection layer per read (negligible perf cost).
- Discipline required — the codebase must reject PRs that introduce magic numbers.

## Alternatives considered

- **Hardcoded constants** — fast to write, painful to maintain.
- **Godot's `ProjectSettings`** — flat namespace, not typed, not designer-friendly.

## References

- `docs/15_M0_ADDENDA.md §A5`
- `game/src/gameplay/gameplay_config.gd`
