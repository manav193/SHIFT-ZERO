# 00 — Executive Summary

## Project

**SHIFT // ZERO** — a premium one-finger 2D action game where the player controls gravity (not the character). Every 20–40 seconds, a *Modifier* rewrites part of the rulebook (gravity flip, low-g, time slow, magnetic walls, portals, blackout, reverse controls, etc.), so every run feels fresh. Easy to learn, hard to master.

## Positioning

- **Category:** Skill-based arcade action, session length 30 s – 3 min.
- **Audience:** Global casual + midcore mobile players (13–35), fans of Super Hexagon, Geometry Dash, VVVVVV, Alto's Odyssey.
- **Business model:** Free-to-play, ethical monetization — rewarded ads + one-time *Remove Ads* IAP + cosmetic skins/trails. **Never pay-to-win.**
- **Store target:** Google Play (primary), Web (itch.io + own site), Google Play Games on PC via ChromeOS/Android emulation. iOS deferred to post-1.2.

## Recommended Engine

**Godot 4.x (GDScript + optional C# for hot paths).**
Reasoning summary (full comparison in `02_TECH_STACK.md`):

| Criterion | Winner | Why |
|---|---|---|
| 2D performance & renderer | **Godot 4** | Dedicated 2D pipeline, low overhead, 60 FPS on mid Android easily |
| Lightweight download | **Godot 4** | Android APK/AAB ~25–35 MB base; Unity is 50–80 MB |
| Licensing / long-term cost | **Godot 4** | MIT, zero royalties, no per-seat fees, no revenue tiers |
| Iteration speed | **Godot 4** | Instant editor reloads, no compile wait for GDScript |
| Ecosystem (ads, IAP, GPGS) | Unity (but Godot is sufficient) | Godot has maintained community plugins for AdMob + Google Play Games Services v2 |
| Web export (desktop browsers) | **Godot 4** | HTML5 export is first-class; Unity WebGL is heavier and worse on mobile web |
| Talent pool | Unity | Larger, but Godot is growing fast and GDScript is trivial to learn |

**Decision:** Godot 4 gives us the best balance of *commercial polish + tiny footprint + zero royalty + fast iteration* for a 2D indie title. Unity remains the fallback if a critical platform plugin becomes blocking.

## Architecture at a Glance

Layered, event-driven, data-oriented where it matters:

```
┌──────────────────────────────────────────────────────────────┐
│  Presentation Layer  (Scenes, UI, HUD, Menus, VFX, SFX)      │
├──────────────────────────────────────────────────────────────┤
│  Gameplay Layer      (Player, World, Modifiers, Obstacles)   │
├──────────────────────────────────────────────────────────────┤
│  Systems Layer       (Input, Physics wrapper, Audio, Anim)   │
├──────────────────────────────────────────────────────────────┤
│  Services Layer      (Save, Settings, Analytics, Ads, IAP,   │
│                       GPGS, Localization, Feature Flags)     │
├──────────────────────────────────────────────────────────────┤
│  Core Layer          (EventBus, ServiceLocator, Logger, RNG, │
│                       Time, Config, Result<T>, Signals)      │
└──────────────────────────────────────────────────────────────┘
```

Everything above the Core layer talks through **signals/events** and a **ServiceLocator**, never direct references. This is what makes the game maintainable across years of updates.

## Non-negotiables

1. **60 FPS on a 2019 mid-range Android** (Snapdragon 6-series, 3 GB RAM) — enforced by CI perf gate.
2. **Cold start to playable in ≤ 3 s** on the target device.
3. **Offline-first** — game must be fully playable without network, ever.
4. **One-finger, one-thumb** playable — no reliance on two-hand input.
5. **Save data is sacred** — migrations tested, corruption-safe, cloud-mergeable.
6. **No dark patterns.** No forced ads on failure, no timers on progression, no loot boxes.

## High-Level Roadmap

| Milestone | Duration | Goal |
|---|---|---|
| **M0 — Foundation** | 1 week | Engine bootstrap, folder structure, CI, coding standards enforced |
| **M1 — Core Loop Prototype** | 2 weeks | Gravity shift + 3 modifiers + procedural obstacle spawner, internal only |
| **M2 — Vertical Slice** | 3 weeks | Full art pass on 1 biome, 8 modifiers, polished HUD, sound |
| **M3 — Content & Meta** | 3 weeks | 3 biomes, 15+ modifiers, cosmetics, daily challenge, save system v1 |
| **M4 — Monetization + Live Services** | 2 weeks | AdMob, IAP, analytics, remote config, GPGS optional layer |
| **M5 — Polish, QA, Localization** | 3 weeks | 8+ languages, accessibility, device matrix QA, perf/mem passes |
| **M6 — Soft Launch → Global Launch** | 4 weeks | Closed → open testing on Play Console, telemetry-driven tuning, global GA |

Total to global launch: **~18 weeks** with a solo–small team cadence.

## Approval

Awaiting your ✅ before I begin M0.
