# PRD — SHIFT // ZERO

## Original Problem Statement

Build a mobile app: commercial-quality indie game "SHIFT // ZERO".
- Mobile-first (Android), fully responsive for phones/tablets/desktop browsers
- One-finger gameplay
- Premium quality UI/UX, 60 FPS target
- Offline gameplay
- Clean modular scalable architecture
- Publish to Google Play, continuously updated

Session 1 instruction: complete architecture & planning first (15 items), no gameplay code, wait for approval.
Session 2 approval with 5 additions (analytics abstraction, remote config abstraction, accessibility day-one, ghost runs v1.1 arch-ready, data-driven gameplay values). Then: "Approved — start M0".

## User Choices

- **Genre:** One-finger 2D gravity-shift action with rotating gameplay modifiers
- **Engine:** Godot 4.3+ LTS (recommended by main agent, user accepted)
- **Monetization:** Free with AdMob rewarded + optional Remove-Ads IAP + cosmetics. Never pay-to-win.
- **Online:** Offline-first, GPGS (cloud save, achievements, leaderboards) v1.1
- **Art style:** Neon / Cyberpunk Minimalist
- **Ghost Runs:** planned v1.1, architectural seams in place from M0
- **Accessibility:** day-one (colorblind palettes, adjustable VFX, haptic toggle, audio controls)
- **Data-driven gameplay:** everywhere possible

## Architecture Highlights (session 1 + session 2 additions)

- 5-layer strict architecture: Presentation → Gameplay → Systems → Services → Core
- EventBus + ServiceLocator with typed `Result<T>` at all service boundaries
- Deterministic seeded RNG with named streams (world / spawn / modifier / cosmetic / vfx)
- Save format: JSON + SHA-256 checksum + atomic double-buffered write + emergency slot + migrations
- Modifier registry pattern — new modifiers require no engine changes
- Layer-dependency enforced by CI script
- **Analytics abstraction (IAnalyticsService)** — live from M0 via ConsoleAnalyticsService, Firebase in M4
- **Remote Config abstraction (IRemoteConfigService)** — live from M0 via StaticRemoteConfigService, Firebase in M4
- **GameplayConfig** — three-layer lookup (Remote → build defaults → hardcoded fallback), all tunable values live in `.tres` / JSON
- **Accessibility** built into `ISettingsService` schema from day one (palette, VFX level, haptics, audio buses)
- **Ghost Runs seam** — `IInputRecorder` + `NoopInputRecorder` + ADR-012 draft ready for v1.1

## What's implemented — M0 Foundation

### Repo scaffold
- `/app/README.md`, `LICENSE`, `CHANGELOG.md`, `.editorconfig`, `.gitattributes`, `.gitignore`
- `.github/workflows/`: `ci.yml` (lint + layer_deps + unit tests + perf_smoke placeholder), `build-android.yml`, `build-web.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`, `ISSUE_TEMPLATE/{bug,feature}.md`

### Scripts (executable)
- `scripts/bootstrap.sh` — first-time contributor setup
- `scripts/check_layer_deps.py` — enforces layer dependency rules
- `scripts/check_forbidden.py` — blocks `print()`, `TODO(no-owner)`, absolute paths
- `scripts/run_tests.sh`, `scripts/build_android.sh`, `scripts/build_web.sh`

### Godot 4 project (`game/`)
- `project.godot` — 6 autoloads registered in correct boot order, 60 FPS physics, canvas-items stretch
- `icon.svg` — neon SHIFT // ZERO logo
- `.gdlintrc` — coding-standards config

### Core layer
- `logger.gd` — 5-level structured logger with ring buffer
- `config.gd` — build-time config + version reader
- `result.gd` — `Result<T>` with `Ok`/`Err` branches
- `rng.gd` — seeded RNG with 5 named streams
- `time_source.gd` — real / game / wall time domains
- `events.gd` — central channel + analytics event registry
- `event_bus.gd` — typed pub/sub
- `service_locator.gd` — interface → implementation resolver, sealable

### Services layer (interfaces + implementations)
- **Save:** `ISaveService` + `InMemorySaveService`
- **Settings:** `ISettingsService` (accessibility schema) + `InMemorySettingsService`
- **Ads:** `IAdsService` + `NullAdsService` + `MockAdsService`
- **Billing:** `IBillingService` + `MockBillingService`
- **Analytics:** `IAnalyticsService` + `ConsoleAnalyticsService` + `MockAnalyticsService`
- **Remote Config:** `IRemoteConfigService` + `StaticRemoteConfigService`
- **Localization:** `ILocalizationService` + `GodotLocalizationService`
- **Feature Flags:** `IFeatureFlagsService` + `DefaultFeatureFlagsService`

### Systems layer
- **Input:** `IInputRecorder` + `NoopInputRecorder` (Ghost Runs seam, v1.1-ready)

### Gameplay layer
- `GameplayConfig` — three-layer lookup wrapper for all tunable values

### App / Presentation
- `app.gd` — top-level bootstrap orchestrator
- `scene_router.gd` — scene stack
- `boot.tscn` + `boot.gd` — SHIFT // ZERO splash

### Data
- `game_config.json` — build-time gameplay defaults
- `game_version.json` — 0.1.0-m0+dev
- `feature_flags.json` — 5 flags including `ghost_runs_enabled=false`
- `remote_config_defaults.json` — full initial key list

### Tests (GUT)
- `test_result.gd` — 3 tests
- `test_event_bus.gd` — 4 tests
- `test_rng.gd` — 3 determinism tests
- `test_analytics_service.gd` — 3 contract tests
- `test_remote_config_service.gd` — 3 contract tests
- `test_settings_service.gd` — 3 accessibility-schema tests
- `test_gameplay_config.gd` — 3 three-layer-lookup tests

### Documentation (16 docs + 12 ADRs)
- Docs 00–15 covering executive summary → M0 addenda
- ADRs 001–012 covering all architectural decisions

## Deferred / Backlog

**P0 — M1 Core Loop Prototype (Weeks 2–3)**
- PlayerController + gravity flip
- ObstacleSpawner with pooling + 3 patterns
- ScoreSystem + minimal HUD
- 3 modifiers: Gravity Flip, Low Gravity, Time Slow
- Local save v1 (upgrade `InMemorySaveService` → `FileSystemSaveService`)

**P1 — M2 Vertical Slice (Weeks 4–6)**
- Neon art pass on Biome 1
- 8 modifiers total
- Adaptive audio + haptics implementation
- Full menu → game → game-over loop
- Settings screen wired to `SettingsService`
- Localization scaffolding

**P2 — M3 → M6** — content, monetization SDKs (AdMob, Play Billing, Firebase), polish, QA, soft-to-global launch. Details in `/app/docs/14_ROADMAP.md`.

**v1.1** — GPGS integration + Ghost Runs implementation (seams already in place).

## Next Action Items

1. User pulls repo, opens `game/project.godot` in Godot 4.3+, verifies boot screen renders and boot logs stream cleanly.
2. Verify CI passes on first push (lint + layer_deps + unit tests).
3. Approve M1 kickoff → main agent implements Core Loop Prototype.

## Notes for the record

- **No gameplay logic exists yet.** Per instructions, M0 delivered scaffolding + architecture only. The boot scene renders the splash; no PlayerController, no ObstacleSpawner, no ModifierManager code.
- **Godot is NOT installed in this preview environment.** All GDScript code is authored and lint-ready but was not executed here. To validate, open the project locally in Godot 4.3+ and press F5.
- **No mocked flows are misrepresented as real.** Ads (`NullAdsService`), Billing (`MockBillingService`), Analytics (`ConsoleAnalyticsService`), Remote Config (`StaticRemoteConfigService`) are explicitly the M0 development-tier implementations. Real Firebase / AdMob / Play Billing land in M4.
