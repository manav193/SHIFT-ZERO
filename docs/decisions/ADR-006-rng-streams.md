# ADR-006 — Deterministic RNG with named streams

**Status:** Accepted
**Date:** 2026-01
**Related requirements:** FR-GP-06, Ghost Runs (v1.1)

## Context

We need:
- Reproducible Daily Challenges (same seed → same run).
- Ghost Runs replay (v1.1) — an input log against the same seed must produce identical world state.
- CI perf regression tests that don't flap on RNG drift.

Cosmetic randomness (particle jitter, background twinkle) must not affect gameplay outcomes.

## Decision

All randomness is drawn from `RNG.stream(name, seed)` where `name ∈ {world, spawn, modifier, cosmetic, vfx}`. Each stream is an independent `RandomNumberGenerator` seeded by `hash(name, seed)`. Streams are reset at the start of every run.

## Consequences

**Positive**
- Deterministic runs.
- Cosmetic changes never break gameplay determinism (or Ghost Run replays).
- Testability.

**Negative**
- Devs must remember to draw from the correct stream. Lint rule: any `randi/randf` in gameplay code is a violation.

## Alternatives considered

- **Single global RNG** — trivially breaks Ghost Runs whenever we add a cosmetic tweak.
- **Xorshift+ from scratch** — unnecessary; Godot's PRNG is stable across minor engine versions.

## References

- `docs/03_ARCHITECTURE.md §7`
- `game/src/core/rng.gd`
- `game/tests/unit/core/test_rng.gd`
