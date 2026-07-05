# ADR-012 — Ghost Run input-log format (DRAFT)

**Status:** Draft — implementation deferred to v1.1
**Date:** 2026-01
**Related requirements:** User addition A4 (session 2)

## Context

Ghost Runs let a player replay a friend's Daily Challenge run as a translucent ghost. They rely on deterministic simulation (ADR-006) and a compact log of the friend's inputs + timing.

## Decision (draft)

The input log is a compact binary format captured by `IInputRecorder`:

```
Header (16 bytes):
  magic          : 4 bytes  = "SZG1"
  version        : uint16
  run_seed       : uint64
  input_count    : uint32   (little-endian throughout)

Body (10 bytes × input_count):
  t_ms           : uint32   (milliseconds since run start, game_time)
  event_kind     : uint8    (0=TAP, 1=HOLD_BEGIN, 2=HOLD_END)
  x_norm         : int16    (Q1.14 fixed-point in [-1, 1])
  y_norm         : int16    (Q1.14 fixed-point in [-1, 1])
  reserved       : uint8

Trailer (32 bytes):
  sha256 of Header + Body
```

Typical median run (45 s, ~30 taps) → ~350 bytes → base64-encoded shareable code.

## Consequences

**Positive**
- Tiny logs — easy to share via Play Games or a share URL.
- SHA-256 trailer prevents tampering for leaderboards.
- Determinism contract (ADR-006) guarantees identical playback.

**Negative**
- Any future engine physics change requires a new format version and a compatibility flag.

## Alternatives considered

- **Full state snapshots per frame** — huge, wasteful.
- **JSON** — 3–5× larger, no meaningful upside.

## Follow-ups

- Implementation ticket queued for v1.1.
- Recording API stub (`IInputRecorder` + `NoopInputRecorder`) is present in M0.

## References

- `docs/15_M0_ADDENDA.md §A4`
- `game/src/systems/input/i_input_recorder.gd`
