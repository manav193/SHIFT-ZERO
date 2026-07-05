# ADR-009 — Remote Config abstraction from day one

**Status:** Accepted
**Date:** 2026-01
**Related requirements:** User addition A2 (session 2), NFR-MAINT-*

## Context

We need to rebalance gameplay values (obstacle density, gravity, modifier weights, ad frequency) without shipping a build. Play Console review can take days; a bad-balance patch cannot wait.

## Decision

`IRemoteConfigService` is initialized during boot with build-time defaults from `data/config/remote_config_defaults.json`. `GameplayConfig` reads all tunable values through a three-layer lookup:

1. Remote Config override (if activated)
2. `game_config.json` build-time default
3. Hardcoded safe fallback

Firebase Remote Config implementation lands in M4. Everything up to then uses `StaticRemoteConfigService`.

## Consequences

**Positive**
- Live re-balancing without app updates from v1.0.
- Every hardcoded value is a code smell — enforced by CI over time.
- Provider-neutral (can swap to GrowthBook, LaunchDarkly, custom).

**Negative**
- One more system to keep in sync.
- Defaults live in two places (JSON + hardcoded). Both are minimal and diff'd.

## Alternatives considered

- **Ship values only in code** — fatal for balance patches.
- **Custom backend from day one** — expensive, unnecessary v1.0.

## References

- `docs/15_M0_ADDENDA.md §A2`, `§A5`
- `game/src/services/remote_config/`
- `game/src/gameplay/gameplay_config.gd`
