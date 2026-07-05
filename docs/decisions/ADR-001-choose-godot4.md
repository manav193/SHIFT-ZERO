# ADR-001 — Choose Godot 4 over Unity

**Status:** Accepted
**Date:** 2026-01
**Deciders:** Lead architect + product owner
**Related requirements:** All (foundational)

## Context

We are building a commercial-quality 2D indie mobile game with:
- 60 FPS on 2019 mid-range Android
- Lightweight download (target base AAB ≤ 40 MB)
- HTML5 export for desktop web
- Long-term update cadence (5+ years)
- Zero royalty / no revenue tiers
- Small team velocity

## Decision

We will use **Godot 4.3+ LTS** as the primary engine, with GDScript 2.0 as the primary language and C# (.NET 8) as an escape hatch for hot paths.

## Consequences

**Positive**
- Purpose-built 2D renderer → better perf per watt than Unity's general renderer.
- 25–35 MB base APK vs 50–80 MB for Unity.
- MIT license — no royalties, no per-seat, no runtime fee risk.
- HTML5 export is first-class → desktop web ships day one.
- Fast iteration (no compile step for GDScript).

**Negative**
- Smaller talent pool than Unity.
- AdMob / Play Billing / GPGS plugins are community-maintained rather than corporate-backed. Risk of bit-rot mitigated by version-pinning and a Unity contingency (see §Alternatives).
- Less battle-tested for top-grossing mobile studios.

**Neutral / follow-ups**
- All third-party plugins listed in `docs/legal/asset_attributions.md`.
- ADR-002 covers the language choice inside Godot.

## Alternatives considered

- **Unity 6 LTS** — larger footprint, licensing complexity, but strongest SDK ecosystem. Documented as fallback if a Godot plugin becomes unmaintainable.
- **Flutter + Flame** — great UI but Flame is under-tested for shader-heavy 2D action at 60 FPS on mid Android.
- **Phaser 3 + Capacitor** — web-first but weaker native Android performance and less mature commercial pipeline.

Full scoring table in `docs/02_TECH_STACK.md §1`.

## References

- `docs/02_TECH_STACK.md`
- `docs/00_EXECUTIVE_SUMMARY.md §Recommended Engine`
