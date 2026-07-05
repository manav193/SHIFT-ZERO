# 01 — Requirements Analysis

## 1. Product Vision

A commercial-quality indie mobile game — **SHIFT // ZERO** — where a single tap flips gravity and the world periodically rewrites its own rules. The vision is a *"one more run"* skill game with the polish of a paid premium title but the accessibility of free-to-play.

## 2. Functional Requirements

### 2.1 Gameplay (defined at high level only — details go in the GDD)

- FR-GP-01: Single-tap input inverts gravity direction of the player character.
- FR-GP-02: Player auto-runs; the only player-controlled variable is gravity direction (and, in some modifiers, gravity magnitude via tap-hold).
- FR-GP-03: Obstacles spawn procedurally from a difficulty curve tied to run distance / time.
- FR-GP-04: **Modifiers** apply for a bounded window (e.g. 15–30 s) and change one or more rules of physics/rendering/input. At least 15 modifiers ship at v1.0.
- FR-GP-05: Death is instant on collision with hazards. Runs are short (target median 45 s, top 5% > 4 min).
- FR-GP-06: Deterministic runs — a given `(seed, modifier_schedule)` must be reproducible for testing and future replays/ghosts.

### 2.2 Meta / Progression

- FR-META-01: Persistent stats (high score, total distance, total runs, per-modifier records).
- FR-META-02: Unlockable cosmetics: skins (character), trails, background palettes. No stat impact.
- FR-META-03: Daily Challenge — fixed seed & modifier order for 24 h, global leaderboard.
- FR-META-04: Achievements (Google Play Games Services in v1.1).

### 2.3 UI / UX

- FR-UI-01: Main menu → Play, Cosmetics, Daily, Settings, About.
- FR-UI-02: In-run HUD: score, current modifier icon + timer, pause.
- FR-UI-03: Game Over screen: score, best, retry, home, watch-ad-to-continue (max 1 per run).
- FR-UI-04: Settings: audio (master/SFX/music), haptics, colorblind mode, reduce-motion, language, restore purchases.

### 2.4 Services

- FR-SVC-01: Local save (fully offline).
- FR-SVC-02: Google AdMob — rewarded video + optional interstitial (frequency-capped).
- FR-SVC-03: Google Play Billing — one-time IAP "Remove Ads" + consumable/durable cosmetic bundles.
- FR-SVC-04: Firebase Remote Config for tuning (difficulty curve, ad frequency caps, feature flags).
- FR-SVC-05: Firebase Analytics + Crashlytics for telemetry and crash reporting.
- FR-SVC-06: (v1.1) Google Play Games Services v2 — sign-in, cloud save, achievements, leaderboards.
- FR-SVC-07: Localization — 8+ languages at launch (EN, ES, PT-BR, FR, DE, RU, JA, KO, ZH-Hans, HI).

### 2.5 Platforms

- FR-PLT-01: Android 8.0 (API 26) minimum, target API = latest Google Play requirement.
- FR-PLT-02: Web build (HTML5) for desktop browsers + Chromebook + itch.io mirror.
- FR-PLT-03: Foldables (Fold/Flip) — no letterboxing in either posture.
- FR-PLT-04: Landscape + Portrait supported; primary is portrait for one-hand play.
- FR-PLT-05: iOS: **not** v1.0. Architecture must remain iOS-ready (no Android-only APIs bleeding into gameplay).

## 3. Non-Functional Requirements

### 3.1 Performance

- NFR-PERF-01: **60 FPS** sustained on Snapdragon 665 / Helio G80 class (2019 mid-range) with 3 GB RAM.
- NFR-PERF-02: Frame budget: **16.6 ms** total; gameplay logic ≤ 4 ms, physics ≤ 3 ms, render ≤ 6 ms, headroom ≥ 3.6 ms.
- NFR-PERF-03: Cold start ≤ 3 s to main menu on target device; warm start ≤ 1 s.
- NFR-PERF-04: Peak RAM ≤ 300 MB on target device.
- NFR-PERF-05: Battery: ≤ 8% drain per 30 min of gameplay on the target device.

### 3.2 Size

- NFR-SIZE-01: Base AAB ≤ 40 MB (uses Play Asset Delivery to slice DPI/lang packs).
- NFR-SIZE-02: HTML5 initial download ≤ 8 MB gzip; rest streamed.

### 3.3 Reliability

- NFR-REL-01: Crash-free sessions ≥ 99.5% at launch, target 99.8% by v1.2.
- NFR-REL-02: ANR rate ≤ 0.2%.
- NFR-REL-03: Save corruption rate = 0 (versioned + checksummed + atomic-write + backup slot).

### 3.4 Security & Privacy

- NFR-SEC-01: No PII stored locally beyond Google account ID hash (if signed in).
- NFR-SEC-02: GDPR + CCPA + COPPA compliant consent flow at first run (via UMP SDK for AdMob).
- NFR-SEC-03: IAP receipts validated (Play Billing library v6+); no client-side score submission trust — server-side signing for leaderboards in v1.1.

### 3.5 Accessibility

- NFR-A11Y-01: Colorblind palette variants (deuteranopia / protanopia / tritanopia).
- NFR-A11Y-02: Reduce-motion toggle disables camera shake, flashes, particles > threshold.
- NFR-A11Y-03: Haptic strength selector (off / light / strong).
- NFR-A11Y-04: All UI passes 4.5:1 contrast (WCAG AA) even in neon theme.
- NFR-A11Y-05: One-thumb reachable — no critical UI in top-right of large phones.

### 3.6 Maintainability

- NFR-MAINT-01: Static analysis clean (gdlint / dotnet-format) on CI.
- NFR-MAINT-02: Unit test coverage ≥ 60% on Services + Core layers.
- NFR-MAINT-03: All modifiers implement a single `IModifier` interface — adding a new modifier must not require touching engine code.
- NFR-MAINT-04: No file > 400 lines; no function > 50 lines (guideline, not law).

### 3.7 Observability

- NFR-OBS-01: Structured logging with levels; production strips DEBUG.
- NFR-OBS-02: Custom analytics events for every funnel step (see `TDD §8`).
- NFR-OBS-03: Perf overlay (FPS, ms, draw calls, RAM) toggleable via secret gesture in DEV builds.

## 4. Constraints

- **C-01:** Solo-to-small team scope. Feature list must respect this — no MMO features.
- **C-02:** No dependency that is unmaintained > 12 months.
- **C-03:** No native (JNI) code unless a Godot plugin is unavailable.
- **C-04:** All third-party SDKs must have documented uninstall paths (in case Play policy changes).
- **C-05:** Save format must be **forward-migratable**; never break a v1.0 user's save.

## 5. Assumptions

- Players have transient connectivity — game must work fully offline, sync opportunistically.
- Median device: 6.1″ phone, 1080×2400, 60 Hz. But 90/120 Hz displays exist and must be respected.
- Ad revenue > IAP revenue at launch; IAP grows with cosmetic depth.

## 6. Out of Scope for v1.0

- Multiplayer (real-time or async).
- User-generated content / level editor.
- iOS build.
- Console ports.
- NFTs / blockchain / crypto — permanently out of scope.

## 7. Key Performance Indicators (KPIs)

| KPI | Target |
|---|---|
| D1 retention | ≥ 35% |
| D7 retention | ≥ 12% |
| D30 retention | ≥ 4% |
| Median session length | ≥ 6 min |
| Sessions/day/DAU | ≥ 4 |
| Rewarded ad opt-in rate | ≥ 25% |
| Remove-ads conversion | 1.5–3% of D7 |
| Crash-free sessions | ≥ 99.5% |
| Store rating | ≥ 4.5 ★ within 90 days |

## 8. Risks & Mitigations (top 5)

| Risk | Impact | Mitigation |
|---|---|---|
| AdMob policy change kills fill rate | High | Mediation layer abstraction (`IAdsService`); can swap in AppLovin/ironSource without gameplay changes |
| Godot AdMob/GPGS plugin bit-rots | Medium | Pin plugin versions, fork-and-maintain in-house if needed; Unity contingency documented |
| 60 FPS fails on low-end Android | High | Perf gate on CI, dynamic quality scaler (particles/shadows), aggressive draw-call budget |
| Save corruption on OS crash | High | Atomic write + double-buffer + checksum + version tag; extensive fuzz tests |
| Modifier combinatorial explosion breaks fairness | Medium | Deterministic seed + compatibility matrix + telemetry on death-per-modifier |
