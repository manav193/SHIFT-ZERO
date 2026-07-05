# ADR-004 — ServiceLocator with interfaces (not global singletons)

**Status:** Accepted
**Date:** 2026-01

## Context

We have many external-integration services (Save, Ads, Billing, Analytics, Remote Config, Cloud Save, Localization, Feature Flags). Each has a prod, dev, mock implementation. Gameplay code must not depend on which one is active.

## Decision

We will use a **ServiceLocator** autoload that resolves an interface name (e.g. `"IAnalyticsService"`) to a concrete instance selected at boot by `App._register_services()`. The locator is sealed after boot to prevent runtime tampering.

## Consequences

**Positive**
- Swapping providers = 1 line change in App.
- Testing: register mocks in the test setup.
- Per-platform selection (`NullAdsService` on Web, real one on Android).

**Negative**
- Some indirection cost (one dictionary lookup per resolution).
- Interface files are boilerplate — mitigated by keeping them thin.

## Alternatives considered

- **Direct autoloads per service** — hard to swap for tests, hard to make platform-conditional.
- **Dependency injection container** — overkill for our scale.

## References

- `docs/03_ARCHITECTURE.md §5.2`
- `game/src/core/service_locator.gd`
- `game/src/app/app.gd`
