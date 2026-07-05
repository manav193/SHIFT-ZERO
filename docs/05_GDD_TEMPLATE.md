# 05 — Game Design Document (GDD) — Skeleton

> This is the **section structure only**, as requested.
> Each `TBD` will be filled during **M1 (Core Loop Prototype)** and iterated through vertical slice and content phases.
> Nothing here is gameplay yet — only the outline of *what the GDD will cover*.

---

## 1. Overview
### 1.1 Title, tagline, elevator pitch — `TBD`
### 1.2 Genre & sub-genre — `Skill-based arcade action, gravity-shift runner`
### 1.3 Target audience & personas — `TBD`
### 1.4 Platforms & controls summary — `Android + Web · one-finger tap/hold`
### 1.5 USP — What makes SHIFT // ZERO different — `TBD`
### 1.6 Reference games & inspirations — `TBD`
### 1.7 Success criteria (creative + commercial) — `TBD`

## 2. Story & World
### 2.1 Setting & lore (light, non-blocking) — `TBD`
### 2.2 Player fantasy — `TBD`
### 2.3 Tone & voice — `TBD`
### 2.4 Biomes overview — `TBD` (min. 3 at launch)

## 3. Core Gameplay Loop
### 3.1 One-sentence core loop — `TBD`
### 3.2 Minute-to-minute loop diagram — `TBD`
### 3.3 Session shape (targets: median 45 s, top 5% > 4 min) — `TBD`
### 3.4 Meta-loop (unlocks, daily, achievements) — `TBD`

## 4. Player Character
### 4.1 Character concept — `TBD`
### 4.2 Movement model (auto-run speed, gravity magnitude, terminal velocity) — `TBD`
### 4.3 Gravity control model (tap = flip, hold = ???) — `TBD`
### 4.4 Feel targets (input latency budget ≤ 32 ms, apex arc duration, etc.) — `TBD`
### 4.5 Death conditions & rules — `TBD`

## 5. Controls
### 5.1 Input scheme — `Single tap (flip) / tap-hold (contextual)`
### 5.2 Alternative inputs — `Keyboard: Space; Mouse: LMB; Gamepad: A`
### 5.3 Accessibility inputs — `TBD`

## 6. World & Obstacles
### 6.1 World camera model (side-scroll, vertical scroll, or hybrid) — `TBD`
### 6.2 Obstacle taxonomy — `Static · Moving · Reactive · Deadly-only · Modifier-scoped`
### 6.3 Spawn patterns & rhythm — `TBD`
### 6.4 Fairness rules (never spawn an unavoidable configuration) — `TBD`

## 7. Modifiers (the star of the show)
### 7.1 Definition — a modifier is a scoped rule change with a bounded duration
### 7.2 Modifier lifecycle — `enter → tick → exit` with clean rollback
### 7.3 Compatibility matrix — which modifiers can stack vs. never overlap
### 7.4 Modifier catalogue (v1.0 target: 15+)
Placeholder list — each gets its own subsection with rules, telemetry, art notes:
1. Gravity Flip
2. Low Gravity
3. Time Slow
4. Magnetic Walls
5. Portals
6. Blackout
7. Reverse Controls
8. Ghost Mode (phase through one obstacle type)
9. Speed Rush
10. Mirror World (flip X axis)
11. Rain (visibility + drift)
12. Neon Overdrive (visual + score multiplier)
13. Micro Gravity (tiny character)
14. Giant Mode (large hitbox, slower)
15. Quantum Split (two ghost trails, only one is real)
16. `TBD backlog…`

### 7.5 Modifier scheduling algorithm — `TBD`
### 7.6 Difficulty pacing per modifier — `TBD`
### 7.7 Telemetry per modifier (death rate, activation frequency, player satisfaction proxy) — `TBD`

## 8. Progression & Economy
### 8.1 XP / stars / currency model — `TBD` (soft-currency only, no hard currency)
### 8.2 Unlock cadence — target: something unlocks every 3–5 runs early on
### 8.3 Cosmetic catalogue — skins, trails, palettes, HUD themes
### 8.4 Daily Challenge design — `TBD`
### 8.5 Achievements list (v1.1 with GPGS) — `TBD`

## 9. UI / UX
### 9.1 Screen inventory & flowchart — `TBD` (see also `08_RESPONSIVE_STRATEGY.md`)
### 9.2 HUD spec — score, best, modifier icon + timer, combo, pause
### 9.3 Menu tone & motion language — `TBD`
### 9.4 First-time user experience (FTUE) — target: first tap → first flip in ≤ 6 s
### 9.5 Empty-states, error-states, offline-state — `TBD`

## 10. Art Direction
### 10.1 Style: **Neon / Cyberpunk Minimalist**
### 10.2 Palette system — one base neon set + colorblind-safe variants
### 10.3 Character silhouette rules — `TBD`
### 10.4 Obstacle silhouette rules (readability at 60 FPS in motion) — `TBD`
### 10.5 VFX language — flashes, glows, trails, chromatic aberration usage rules
### 10.6 Iconography set — `TBD`

## 11. Audio Direction
### 11.1 Music genre & structure — `TBD` (target: dark synthwave / minimal techno)
### 11.2 SFX inventory — `TBD`
### 11.3 Adaptive audio rules (music changes per modifier, ducks on impact) — `TBD`
### 11.4 Haptics language — `TBD`

## 12. Difficulty & Balancing
### 12.1 Difficulty curve targets (deaths per minute over first 20 runs) — `TBD`
### 12.2 Balancing methodology — telemetry-driven; adjust via Remote Config
### 12.3 Fairness invariants — `TBD`

## 13. Monetization Design (creative side; SDK details in TDD)
### 13.1 Ad placements & frequency caps — `TBD`
### 13.2 Rewarded ad hooks — continue run, unlock cosmetic preview, double coins
### 13.3 IAP catalogue — Remove Ads, cosmetic bundles, tip jar
### 13.4 Ethical guardrails — no timers, no lives, no exit-blocking ads, no pay-to-win

## 14. Retention & Live Ops
### 14.1 Push notification strategy (opt-in only) — `TBD`
### 14.2 Event/season structure (post v1.0) — `TBD`
### 14.3 Content update cadence — target every 4–6 weeks

## 15. Localization
### 15.1 Launch languages — EN, ES, PT-BR, FR, DE, RU, JA, KO, ZH-Hans, HI
### 15.2 Style rules per locale — `TBD`
### 15.3 Character-set / font fallback strategy — `TBD`

## 16. Accessibility
### 16.1 Colorblind modes — `TBD`
### 16.2 Reduce-motion mode spec — `TBD`
### 16.3 Haptic strength selector — `TBD`
### 16.4 Contrast + font-size options — `TBD`

## 17. Compliance & Ratings
### 17.1 Target rating — PEGI 3 / ESRB Everyone
### 17.2 Data privacy declarations — `TBD`
### 17.3 Ads content policy — family-safe categories only

## 18. Analytics & Metrics
### 18.1 Event schema — `TBD` (see TDD §8)
### 18.2 Funnels tracked — install → tutorial → run1 → run5 → D1 return
### 18.3 KPI dashboards — `TBD`

## 19. Post-Launch Roadmap (creative)
### 19.1 v1.1 content plan — `TBD`
### 19.2 v1.2 seasonal events — `TBD`
### 19.3 Long-tail features backlog — `TBD`

## 20. Appendices
### 20.1 Glossary
### 20.2 Version history of this GDD
### 20.3 Open questions log
