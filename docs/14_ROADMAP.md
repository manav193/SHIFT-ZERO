# 14 — Development Roadmap

Duration estimates assume a small team (1–2 devs, 1 artist part-time, 1 audio designer part-time). Solo would roughly 1.6× these.

Every milestone has **exit criteria** — nothing rolls forward on vibes.

---

## M0 — Foundation (Week 1)

**Goal:** Everything below "gameplay" is real. Repo is production-shaped.

### Scope
- Godot 4 project bootstrapped under `game/`.
- Folder structure per `04_FOLDER_STRUCTURE.md`.
- Autoloads: `Logger`, `Config`, `ServiceLocator`, `EventBus`, `SceneRouter`, `App`.
- `Result<T>`, seeded `RNG`, `TimeSource`.
- Interfaces + **mock** implementations for every service (`ISaveService`, `ISettingsService`, `IAdsService`, `IBillingService`, `IAnalyticsService`, `IRemoteConfigService`, `ILocalizationService`, `IFeatureFlagService`).
- Coding standards enforced: `gdlint`, layer-dependency checker, editorconfig.
- GitHub Actions: `ci.yml` (lint + unit tests) + basic Android debug build.
- README + `docs/` in repo.
- A "Hello, SHIFT // ZERO" scene renders correctly on Android + Web + Desktop.

### Exit criteria
- ✅ Clone → follow README → run on Android + Web + Desktop in < 20 minutes.
- ✅ CI green on `main`.
- ✅ Layer-dependency script fails a deliberately-invalid PR (test the guardrails).
- ✅ Startup < 3 s on T-Low device (measured).

---

## M1 — Core Loop Prototype (Weeks 2–3)

**Goal:** The core fantasy is proven — gravity flipping *feels good*.

### Scope
- `PlayerController` with auto-run + gravity flip on tap.
- Fixed-timestep physics @ 60 Hz.
- `ObstacleSpawner` with 3 basic obstacle patterns and pooling.
- `ScoreSystem` (distance-based) + minimal HUD (score + best).
- `RunDirector` FSM.
- 3 modifiers implemented: **Gravity Flip** (baseline), **Low Gravity**, **Time Slow**.
- `ModifierManager` with schedule + compatibility matrix scaffold.
- Local save (JSON + checksum) storing high score.
- One-finger UX correct on portrait phone; keyboard `Space` on desktop.
- Perf overlay in DEV builds.

### Exit criteria
- ✅ Median internal playtester run ≥ 30 s within 5 attempts.
- ✅ Team-internal NPS on "feel" ≥ 8/10.
- ✅ 60 FPS stable on T-Low reference device across a 5 min soak.
- ✅ Save survives 1 000 forced kills (fuzz).

---

## M2 — Vertical Slice (Weeks 4–6)

**Goal:** One biome, art-complete, feels like a shipping game.

### Scope
- Neon minimalist art pass on Biome 1 (backgrounds, character, one obstacle set, HUD, palette).
- 8 modifiers total (add: Magnetic Walls, Portals, Blackout, Reverse Controls, Mirror World).
- Adaptive audio (music intro/loop, ducking, SFX for tap/flip/impact/modifier events).
- Haptics on flip, impact, modifier enter/exit.
- Main Menu → Game → Game Over loop, polished.
- Settings screen (audio, haptics, reduce-motion, language toggle, colorblind mode).
- Localization scaffolding — EN + one other language proven end-to-end.
- Boot sequence < 3 s cold on T-Low.

### Exit criteria
- ✅ 30 external playtesters — median 6 min session, D0 retention proxy ≥ 60%.
- ✅ No P0/P1 bugs.
- ✅ Perf gate green on T-Low across the vertical slice replay.
- ✅ Store listing draft created (icon, feature graphic, 5 screenshots, description v1).

---

## M3 — Content & Meta (Weeks 7–9)

**Goal:** From vertical slice to a game with depth.

### Scope
- **3 biomes** total, each with distinct palette + obstacle set + music.
- **15+ modifiers** total.
- Cosmetics system: 6 skins, 6 trails, 4 palettes at launch. Unlock schedule tuned.
- Daily Challenge implemented (deterministic seed + shareable code).
- Save system v1 finalized (backup slot + emergency save + migrations).
- Settings expanded (all languages toggleable, restore purchases stub, credits).
- Analytics scaffolding (via mock in DEV, plumbed for prod integration in M4).

### Exit criteria
- ✅ 3 biomes ship-quality (art director sign-off).
- ✅ Content registries drive UI — no hardcoded lists left.
- ✅ Save migration test: v0 → v1 upgrade path proven.
- ✅ 50 external playtesters — median D1 (proxy) ≥ 30%.

---

## M4 — Monetization + Live Services (Weeks 10–11)

**Goal:** Revenue and observability wired end-to-end.

### Scope
- **AdMob** integrated behind `IAdsService`: rewarded ("continue run", "unlock cosmetic preview"), one interstitial with frequency cap.
- **UMP** consent flow (GDPR/CCPA/COPPA).
- **Play Billing** integrated: "Remove Ads" IAP + one cosmetic bundle.
- **Firebase Analytics** + **Crashlytics** wired; event schema (see TDD §8) firing.
- **Firebase Remote Config** wired for difficulty tuning + ad frequency cap + feature flags.
- Restore purchases flow tested.
- Ad and IAP funnels visible in dashboards.

### Exit criteria
- ✅ End-to-end purchase on Play sandbox → entitlement reflected on relaunch → cross-device via cloud save (post-M5).
- ✅ Rewarded ad opt-in ≥ 25% in internal tests.
- ✅ Ad + IAP telemetry validated in Firebase console.
- ✅ No monetization dark pattern anywhere (self-audit checklist signed).

---

## M5 — Polish, QA, Localization (Weeks 12–14)

**Goal:** Store-review-quality, on real devices.

### Scope
- **8+ languages** finalized (EN, ES, PT-BR, FR, DE, RU, JA, KO, ZH-Hans, HI target).
- Accessibility final pass: colorblind palettes, reduce-motion, haptic strength, contrast checked WCAG AA.
- Device matrix QA — at least 12 real devices covering all buckets (see `08_RESPONSIVE_STRATEGY.md §12`).
- Battery / thermal soak: 30 min gameplay ≤ 8% drain on target.
- Memory + FPS regression fixed until perf gate green in all scenarios.
- Play Console listing complete (icon, graphics, screenshots per language, privacy policy).

### Exit criteria
- ✅ Crash-free sessions ≥ 99.5% on closed testing over 7 days.
- ✅ Store review pre-check (Play Console warnings) — zero blockers.
- ✅ Localization QA sign-off from at least 3 native speakers.
- ✅ All P0/P1 bugs resolved; P2 known-issues logged.

---

## M6 — Soft Launch → Global Launch (Weeks 15–18)

**Goal:** Launch and learn.

### Scope
- **Closed testing** (Alpha) → invite-only, 100 testers, 1 week.
- **Open testing** (Beta) → public link in 2 launch markets (e.g. Philippines, Brazil), 1 week.
- Telemetry-driven tuning of difficulty curve + ad frequency via Remote Config.
- **Global launch** on Google Play, staged rollout: 1% → 5% → 20% → 50% → 100% over 7 days.
- **Web launch** (mirror on itch.io + own site) same-day as global Play.
- Community day-0 assets: trailer, GIFs, press kit, social posts.

### Exit criteria
- ✅ D1 retention ≥ 35% in soft launch markets.
- ✅ Crash-free sessions ≥ 99.5%.
- ✅ Ad revenue + IAP conversion tracked; unit economics dashboard live.
- ✅ Store rating ≥ 4.5 ★ within first 500 reviews.
- ✅ Rollback plan tested (fire drill during Beta).

---

## Post-Launch (v1.1 and beyond, ongoing)

Rough plan; refined per user feedback.

| Version | Theme | Highlights |
|---|---|---|
| **v1.1** | GPGS layer + first content drop | Cloud save, achievements, leaderboards; +5 modifiers; +2 biomes |
| **v1.2** | Seasonal events | 4-week limited-time events; custom leaderboard backend |
| **v1.3** | Accessibility & polish | Additional colorblind sets; UI redesign passes; extra languages |
| **v1.4** | Cosmetics expansion | New skins, trails, HUD themes; season pass (ethical, ad-only unlock path) |
| **v2.0** | New game mode | Endless "Zen" mode without death; possibly co-op ghost mode |

---

## Cross-cutting: Definition of Done (per feature)

Every feature, regardless of milestone, is "done" when:

1. Passes CI (lint + unit + integration).
2. Passes perf gate on T-Low profile.
3. Has telemetry events for its key user actions.
4. Has feature-flag coverage where behavioral rollback is plausible.
5. Documented in the appropriate section of the TDD or design docs.
6. Peer-reviewed and merged via squash.
7. Verified once on a real Android device.
