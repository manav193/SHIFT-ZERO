# ADR-008 — Analytics abstraction from day one

**Status:** Accepted
**Date:** 2026-01
**Related requirements:** User addition A1 (session 2)

## Context

Analytics providers change. Firebase pricing changes. Regulators push new consent rules. We do not want gameplay or UI code to know which provider is active.

## Decision

We will ship an `IAnalyticsService` interface from the very first commit. M0 provides a `ConsoleAnalyticsService` that writes structured JSON to the Logger, giving us real telemetry visibility immediately. The Firebase implementation lands in M4 without touching any call site. Event names are centralized in `core/events.gd::AnalyticsEvents`.

## Consequences

**Positive**
- Any provider (Firebase, GA4, Amplitude, Mixpanel) can be swapped in with a single-line change in `App`.
- Consent + user-property + event API is stable across providers.
- Tests use `MockAnalyticsService` — record and assert.

**Negative**
- Slight indirection at every `log_event` call site.

## Alternatives considered

- **Wire Firebase directly** — fastest to write, worst to swap. Rejected.
- **No analytics until M4** — loses M1/M2/M3 playtester telemetry.

## References

- `docs/15_M0_ADDENDA.md §A1`
- `game/src/services/analytics/`
