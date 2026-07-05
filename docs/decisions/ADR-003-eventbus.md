# ADR-003 — EventBus as central pub/sub

**Status:** Accepted
**Date:** 2026-01

## Context

Cross-system communication in a game with many independent subsystems (Player, ModifierManager, Score, VFX, Audio, HUD, Analytics, Save) becomes an N² mess of direct references without discipline.

## Decision

We will use a single **autoloaded EventBus** with typed string channels (constants in `core/events.gd`). Subscribers register via `subscribe(channel, callable)`; publishers use `emit(channel, payload)`. Cross-layer communication goes through the bus. Intra-scene signals remain native Godot signals for locality.

## Consequences

**Positive**
- Loose coupling — removing/adding a subsystem never breaks others.
- Easy to test (mock/observe channels).
- Cross-layer dependency rule enforceable (no `preload` needed).

**Negative**
- String-based channels require a discipline of centralizing names (mitigated by `events.gd` constants and lint rule).
- Slight overhead vs direct calls (negligible at our event rate).

## Alternatives considered

- **Direct signals + service references** — tighter, but brittle at scale.
- **Reactive framework (RxGD / GodotFlux)** — too heavy for our needs.

## References

- `docs/03_ARCHITECTURE.md §5.1`
- `game/src/core/event_bus.gd`
- `game/src/core/events.gd`
