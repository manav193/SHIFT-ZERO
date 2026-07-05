# 03 — System Architecture

## 1. Guiding Principles

1. **Separation of Concerns.** Rendering, gameplay, services and platform code never blur.
2. **Talk in events, not references.** Systems communicate via a typed EventBus / Godot signals. No system holds a hard reference to another gameplay system.
3. **Data-oriented where it matters.** Modifier definitions, obstacle patterns, cosmetics, difficulty curves — all live in **Resources (`.tres`) or JSON**, never hardcoded. Designers tune without touching code.
4. **Composition over inheritance.** Behaviours are Nodes/Components attached to entities, not deep class hierarchies.
5. **Engine-agnostic seams at the Services boundary.** If we ever migrate engines, only Services + a thin scene-loader change.
6. **Deterministic simulation.** Given a seed and modifier schedule, a run is byte-identical replayable.
7. **Fail visibly in dev, gracefully in prod.** All service calls return a `Result` (ok / error), never throw across layer boundaries.

## 2. Layered Architecture

```
┌───────────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                                   │
│  Scenes (MainMenu, Game, GameOver, Cosmetics, Settings)               │
│  UI (HUD, Modals, Toasts), VFX orchestrator, SFX cues                 │
├───────────────────────────────────────────────────────────────────────┤
│  GAMEPLAY LAYER                                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ┌────────────────┐ │
│  │ Player      │  │ World /     │  │ Modifier    │ │ Obstacle       │ │
│  │ (gravity)   │  │ Camera      │  │ Manager     │ │ Spawner        │ │
│  └─────────────┘  └─────────────┘  └─────────────┘ └────────────────┘ │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ ┌────────────────┐ │
│  │ Score /     │  │ Difficulty  │  │ Modifiers/* │ │ Collectibles / │ │
│  │ Combo       │  │ Curve       │  │ (15+ impls) │ │ Pickups        │ │
│  └─────────────┘  └─────────────┘  └─────────────┘ └────────────────┘ │
├───────────────────────────────────────────────────────────────────────┤
│  SYSTEMS LAYER                                                        │
│  Input (tap/hold/gesture) │ Physics wrapper │ Audio bus manager       │
│  Animation controller     │ Camera director │ Haptics                 │
├───────────────────────────────────────────────────────────────────────┤
│  SERVICES LAYER (all behind interfaces — swappable)                   │
│  ISaveService │ ISettingsService │ IAdsService │ IBillingService      │
│  IAnalyticsService │ IRemoteConfigService │ ICloudSaveService         │
│  ILocalizationService │ IFeatureFlagService │ ILoggerService          │
├───────────────────────────────────────────────────────────────────────┤
│  CORE LAYER (pure, no engine coupling where possible)                 │
│  EventBus │ ServiceLocator │ Result<T> │ RNG (seeded) │ TimeSource    │
│  Config loader │ SchemaValidator │ Migrations │ Signals typedefs      │
└───────────────────────────────────────────────────────────────────────┘
```

### Dependency rule (strict)

**Higher layers may depend on lower layers only. Never the reverse.**
Presentation → Gameplay → Systems → Services → Core. Same layer talks via EventBus.

Enforced by:
- Static import checks (custom script in CI parses `preload/load` calls).
- Folder ownership: `services/` is not allowed to `preload` anything from `gameplay/`.

## 3. Runtime Bootstrap

```
App.launch()
  └─ Godot autoloads (order matters):
      1. Logger              (initialize first — everything else logs)
      2. Config              (load config.json, env)
      3. ServiceLocator      (registers all services as stubs)
      4. SaveService         (opens store, runs migrations)
      5. SettingsService     (reads persisted settings, applies to engine)
      6. LocalizationService (loads locale, sets translation)
      7. RemoteConfigService (fetch-and-activate, non-blocking after 1s timeout)
      8. AnalyticsService    (initialize with consent state)
      9. AdsService          (consent-gated init)
     10. BillingService      (query products in background)
     11. EventBus            (ready to broadcast)
  └─ SceneRouter.push("MainMenu")
```

**Rule:** boot must complete in < 800 ms. Anything slower than that must be deferred (lazy-init after MainMenu is interactive).

## 4. Runtime Data Flow — a single tap during gameplay

```
Touch event (OS)
  → InputSystem.on_touch()
     → normalizes to GameInput{type: TAP, t: 12.345, id: 0}
     → EventBus.emit("input/tap", GameInput)

Player listens:
  → PlayerController._on_input_tap()
     → flips gravity_direction
     → EventBus.emit("player/gravity_shifted", {new_dir, t})

ModifierManager may transform the event (e.g. "Reverse Controls" modifier):
  → intercepts "input/tap" before Player consumes it, swaps direction
  → re-emits "input/tap_effective"

VFX & Haptics react:
  → VFXOrchestrator plays flash + trail rebind
  → HapticsSystem fires light impulse
  → SFXCue plays "shift.wav"

Score/Combo listens to player events:
  → ScoreSystem increments combo, updates HUD via HUD binding
```

Each subsystem observes only the events it needs. Removing any subsystem does not break others.

## 5. Component Overview

### 5.1 Core

- **EventBus** — typed pub/sub. Channels are constants defined in `core/events.gd`. Payloads are typed dictionaries or `Resource` subclasses.
- **ServiceLocator** — resolves `IService` interfaces to concrete implementations. Two configs: `prod` and `dev` (with mock services).
- **RNG** — wraps `RandomNumberGenerator` with a seed and stream separation (world, cosmetics, spawns each get their own stream so cosmetic randomness never breaks determinism).
- **TimeSource** — `real_time`, `game_time`, `wall_time` abstractions. Modifiers like "Time Slow" scale `game_time` only.
- **Result** — `Ok(value)` / `Err(code, message)`. Used across service boundaries.
- **Logger** — levels (TRACE/DEBUG/INFO/WARN/ERROR), routes to console + file + Crashlytics.

### 5.2 Services (interfaces)

Every service has:
- an **interface** file (`i_xxx.gd`),
- a **prod** implementation (`xxx_service.gd`),
- a **mock** for tests (`mock_xxx_service.gd`),
- optionally a **null** implementation for platforms without the capability (e.g. Web has no AdMob).

| Interface | Prod impl (Android) | Prod impl (Web) | Mock (tests) |
|---|---|---|---|
| ISaveService | FileSystemSaveService | LocalStorageSaveService | InMemorySaveService |
| IAdsService | AdMobAdsService | NullAdsService | MockAdsService |
| IBillingService | PlayBillingService | NullBillingService | MockBillingService |
| IAnalyticsService | FirebaseAnalyticsService | ConsoleAnalyticsService | MockAnalyticsService |
| IRemoteConfigService | FirebaseRemoteConfigService | StaticRemoteConfigService | MockRemoteConfigService |
| ICloudSaveService | GpgsCloudSaveService | NullCloudSaveService | MockCloudSaveService |

The **ServiceLocator** picks the right stack per platform at boot.

### 5.3 Gameplay

- **PlayerController** — owns gravity direction & magnitude. Emits `player/*` events.
- **World** — parallax layers, biome swap, background palette animator.
- **ObstacleSpawner** — pulls from `DifficultyCurve` + `SpawnPatterns` resources.
- **ModifierManager** — schedules modifiers, applies + cleans up, tracks timers.
- **Modifiers/** — one `.gd` file per modifier, all implement `IModifier { on_enter, on_tick, on_exit, tags }`.
- **ScoreSystem** — distance-based + combo multiplier (combos build from close-call dodges).
- **DifficultyCurve** — resource that maps `time → { obstacle_density, speed, modifier_pool_weights }`.

### 5.4 Systems

- **InputSystem** — normalizes touch/mouse/keyboard into a single stream. Configurable dead-zones.
- **HapticsSystem** — abstracts Android Vibrator API + honours user setting.
- **AudioBusManager** — master/music/sfx/ui buses, ducking, mute-on-focus-loss.
- **CameraDirector** — screen-shake, zoom pulses, letterboxing during modifiers.
- **AnimationController** — palette shifts, character breathing, HUD micro-animations.

### 5.5 Presentation

- **SceneRouter** — a small stack of scenes with push/pop/replace. Transitions are declarative.
- **HUD** — root Control node; binds to EventBus and reflects game state.
- **UIKit** — reusable Control-based components (Button, Toggle, Slider, Toast) themed centrally.
- **VFXOrchestrator** — pool of particle emitters + shader trigger points, driven by events.

## 6. Data Flow Diagrams

### 6.1 Save flow

```
Gameplay ends
  → EventBus.emit("run/finished", RunSummary)
  → SaveService.mutate(state -> {
         state.total_runs += 1
         state.high_score = max(state.high_score, run.score)
         ...
     })
  → SaveService writes: staging file → checksum → atomic rename → primary
  → SaveService writes secondary backup slot every N mutations
  → CloudSaveService (if signed in) schedules debounced upload
```

### 6.2 Purchase flow

```
User taps "Remove Ads"
  → UI calls BillingService.purchase("remove_ads")
  → BillingService returns Result<PurchaseToken>
  → On Ok: BillingService.acknowledge(token)
  → EventBus.emit("entitlements/changed", { remove_ads: true })
  → AdsService listens → disables interstitials
  → SaveService persists entitlement snapshot (also refetched from Play on every launch)
```

### 6.3 Ad flow

```
Game Over screen
  → user taps "Watch to continue"
  → AdsService.showRewarded(placement="continue_run")
  → returns Result<RewardGranted>
  → On Ok: EventBus.emit("run/continue_granted")
  → Game resumes with brief invulnerability
```

## 7. Determinism Contract

For replay + tests + fair Daily Challenges:

- Every random draw happens through **RNG** with a named stream.
- `physics_step` is fixed at **1/60 s** (Godot's `physics_fps=60`, `physics_jitter_fix=0`).
- Modifier schedule for Daily Challenge is derived from `hash(date_utc + player_country_bucket_off)`.
- Player input is timestamped in `game_time` not `real_time`.
- Save format includes `engine_version + game_version + rng_seed` so replays remain valid.

## 8. Threading Model

- **Main thread**: gameplay + rendering + audio dispatch.
- **Worker thread** (Godot `WorkerThreadPool`): asset preloading, checksum, JSON parse, cloud sync.
- **No shared mutable state** across threads without a channel. Workers post results back to main via `call_deferred` or a job queue.

## 9. Error Handling Policy

- Services return `Result<T>` — callers must handle both branches. `unwrap()` is banned outside tests.
- Unrecoverable errors → route through `Logger.error(...)` → Crashlytics; UI shows a friendly toast; game state is snapshotted to `emergency_save.json`.
- Gameplay-level errors (impossible state) → `assert` in debug builds, safe fallback + telemetry in release.

## 10. Extensibility Hooks

The following are explicit **add-without-changing-code** extension points:

| Extension | How |
|---|---|
| Add a Modifier | Drop `xxx_modifier.gd` in `gameplay/modifiers/` and add its `.tres` to `data/modifiers/registry.tres`. Registry loads dynamically. |
| Add a Cosmetic | Add `.tres` to `data/cosmetics/`. Shop UI reads the folder. |
| Add a Biome | Add a `world_biome_xxx.tscn` + `.tres` metadata + register in `data/biomes/registry.tres`. |
| Add a Language | Add column to `translations.csv`. Godot auto-picks it up. |
| Add a Feature Flag | Add key + default to `data/config/feature_flags.json`. Overridden by Remote Config at runtime. |

## 11. Testing Architecture

- **Unit tests** with GUT (Godot Unit Test): pure logic in Core + Services + Modifiers.
- **Integration tests**: headless Godot runs a scripted scene, asserts on EventBus events.
- **Deterministic replay tests**: canned inputs + fixed seed → expected final score.
- **Perf tests** on CI: `run --headless --perf 60s` captures frame time histogram; PR fails if p95 > 17 ms.

## 12. Architecture Decision Records (ADRs)

All non-trivial architectural choices are captured as ADRs under `docs/decisions/ADR-NNN-slug.md`. Initial ADRs at kickoff:

- ADR-001: Choose Godot 4 over Unity
- ADR-002: GDScript primary, C# escape hatch
- ADR-003: EventBus as central pub/sub
- ADR-004: ServiceLocator with interfaces (not global singletons)
- ADR-005: Save format = JSON + checksum + atomic write + double slot
- ADR-006: Deterministic RNG with named streams
- ADR-007: Modifier registry pattern for extension
