# ADR-010 — Accessibility planned from day one

**Status:** Accepted
**Date:** 2026-01
**Related requirements:** NFR-A11Y-01..05, User addition A3 (session 2)

## Context

Accessibility retrofitted late is accessibility done badly. Neon aesthetics are especially unfriendly to colorblind players unless we plan colorblind palettes early. Reduce-motion, haptics toggles, and adjustable audio are non-negotiable for a modern mobile game.

## Decision

From M0 the settings schema includes:
- `color_palette_id` — default_neon | deuteranopia | protanopia | tritanopia | high_contrast
- `visual_effects_level` — 0 (reduce-motion) .. 3 (full)
- `haptics_enabled`, `haptics_strength`
- Four audio buses: master / music / sfx / ui

A dedicated `AccessibilityBus` channel set (`A11Y_*` in `events.gd`) lets subsystems react without polling. Palette resources are scaffolded now, filled in M2 art pass. Contrast lint runs on every UI PR to enforce WCAG-AA.

## Consequences

**Positive**
- We ship accessible on day one, not as a patch.
- Every subsystem reacts to a11y changes via events → no branching in gameplay.

**Negative**
- Art must produce 4+ palette variants (built into the M2 plan).
- Slight complexity in the settings API.

## Alternatives considered

- **Accessibility in a post-launch update** — leaves an early cohort excluded; hurts reviews and reputation.

## References

- `docs/15_M0_ADDENDA.md §A3`
- `docs/01_REQUIREMENTS_ANALYSIS.md §3.5`
- `docs/05_GDD_TEMPLATE.md §16`
