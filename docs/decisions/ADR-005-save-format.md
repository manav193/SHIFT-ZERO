# ADR-005 — Save format: JSON + checksum + atomic double-buffered write

**Status:** Accepted
**Date:** 2026-01
**Related requirements:** NFR-REL-03, FR-META-01/02

## Context

A single lost high-score costs us a review. Mobile OSes kill the process at any moment. We need saves that survive crashes, kills, and OS-level anomalies.

## Decision

Save format:

```json
{ "checksum": "<sha256 of payload>", "payload": <state> }
```

Write protocol: serialize → checksum → write staging → atomic rename → primary. Every N writes we copy primary → backup. On uncaught error we write an emergency slot.

Read protocol: primary → verify → migrate. Fallback: backup → emergency. Fully fresh init only as last resort (telemetered).

## Consequences

**Positive**
- Zero data loss under normal OS behavior.
- Corruption self-healing via backup slot.
- Migration chain covers every schema change.

**Negative**
- Slightly more disk IO per save (three files potentially touched).
- Migration discipline is required forever.

## Alternatives considered

- **Binary format (msgpack)** — smaller but harder to diff, harder to debug. Overkill for < 50 KB saves.
- **SQLite** — heavy for our scale.
- **No checksum** — cheap but leaves silent corruption undetectable.

## References

- `docs/10_SAVE_SYSTEM.md`
