# 15 — M0 Addenda (User-approved additions)

Session-1 user approval came with five explicit additions. This document is authoritative — anything below overrides prior docs on conflict.

## A1. Analytics Abstraction — day one

Analytics is wired at boot behind `IAnalyticsService` from the very first commit. No gameplay or UI code ever imports Firebase (or any provider) directly.

### Contract

```gdscript
class_name IAnalyticsService

func init(consent: AnalyticsConsent) -> void
func set_user_property(key: String, value: Variant) -> void
func log_event(name: String, params: Dictionary = {}) -> void
func flush() -> void
func set_consent(consent: AnalyticsConsent) -> void
```

### Providers registered at boot (per platform)

| Platform | Prod | Dev | Test |
|---|---|---|---|
| Android | `FirebaseAnalyticsService` | `ConsoleAnalyticsService` | `MockAnalyticsService` |
| Web | `ConsoleAnalyticsService` (or GA4 via plugin later) | `ConsoleAnalyticsService` | `MockAnalyticsService` |
| Desktop | `ConsoleAnalyticsService` | `ConsoleAnalyticsService` | `MockAnalyticsService` |

Swapping providers = one line in `App._register_services()`. No gameplay change.

### Ships in M0
- Interface + `ConsoleAnalyticsService` (writes structured JSON lines to logs)
- `MockAnalyticsService` (records calls for tests)
- Event name registry (`core/events.gd::ANALYTICS_EVENTS`) — every gameplay event name lives here as a constant to prevent typos.

Firebase implementation lands in M4 without touching a single call site.

---

## A2. Remote Config Abstraction — day one

`IRemoteConfigService` is initialized during boot with **build-time defaults** loaded from `data/config/remote_config_defaults.json`. In M4 we swap in the Firebase implementation; nothing else changes.

### Contract

```gdscript
class_name IRemoteConfigService

func init() -> void
func fetch_and_activate(timeout_s: float = 1.0) -> Result   # Result<Bool activated>
func get_bool(key: String, default: bool = false) -> bool
func get_int(key: String, default: int = 0) -> int
func get_float(key: String, default: float = 0.0) -> float
func get_string(key: String, default: String = "") -> String
func get_json(key: String, default: Dictionary = {}) -> Dictionary
signal activated
```

### Gameplay values bind through it (see A5)

Gameplay reads values from `GameplayConfig.get(...)` which internally consults, in order:
1. Remote Config overrides (if activated)
2. `game_config.tres` build-time defaults
3. Hardcoded safe fallback

Anything tunable — obstacle density, gravity magnitude, modifier durations, spawn intervals, reward drop rates, ad frequency caps — lives in Remote Config keys with sane build-time defaults. **We must be able to rebalance without shipping a build.**

### Ships in M0
- Interface + `StaticRemoteConfigService` (reads defaults JSON, exposes get/set for tests)
- `MockRemoteConfigService` (in-memory, controllable in tests)
- `remote_config_defaults.json` with the full initial key list (populated as gameplay is added in M1+)

---

## A3. Accessibility — planned from day one

All four requested accessibility affordances have dedicated system + storage from M0 forward.

### M0 deliverables
- `SettingsService` schema includes:
  - `color_palette_id: String` — default, deuteranopia, protanopia, tritanopia, high-contrast
  - `visual_effects_level: int` — 0 (minimal / reduce-motion) → 3 (full)
  - `haptics_enabled: bool` and `haptics_strength: int` — 0..2
  - `audio_master: float`, `audio_music: float`, `audio_sfx: float`, `audio_ui: float`
- Palette resources scaffolded (empty for now, filled in M2 art pass): `data/palettes/*.tres`
- `AccessibilityBus` — an EventBus channel: settings changes broadcast so any subsystem (VFX, haptics, audio) reacts without polling.
- Contrast lint: any UI PR runs a WCAG-AA contrast check on the neon palette + colorblind variants.

### Non-negotiables
- Reduce-motion honored by camera-shake, screen flashes, particle spawn multiplier, background parallax.
- Haptics honor `haptics_enabled = false` at the system boundary — no gameplay code checks it.
- Every audio bus is user-adjustable. Ducking rules never override a muted bus.
- All UI elements meet WCAG-AA contrast at the default palette.

---

## A4. Ghost Runs — v1.1, arch-ready in M0

We will NOT implement Ghost Runs in v1.0. But every architectural seam it needs is in place from M0:

- **Determinism contract** (`03_ARCHITECTURE.md §7`) guarantees `(seed, modifier_schedule, input_log)` fully determines a run.
- **RNG streams** are named and independent — cosmetic randomness never affects gameplay RNG.
- **Input log capture** — `InputSystem` will expose a `record()` / `stop()` API in M0 (returning a `PackedByteArray` of timestamped inputs). Gameplay in v1.0 ignores this API; v1.1 will consume it.
- **Storage format** — `docs/decisions/ADR-012-ghost-run-format.md` (drafted in M0, implemented v1.1) specifies the compact binary format for input logs.
- **Playback subsystem** — v1.1 will add a `GhostPlayer` node that consumes the input log and drives a translucent copy of the player. No changes to `PlayerController` required.

### Ships in M0
- `IInputRecorder` interface + no-op default implementation.
- ADR-012 draft.
- Determinism unit test that would already catch a regression that breaks ghost playback.

---

## A5. Data-Driven Gameplay Values — everywhere possible

**Nothing gameplay-affecting is hardcoded.** All tunable values live in typed `Resource` `.tres` files under `data/`, and are optionally overridden by Remote Config at runtime.

### Concrete `.tres` schemas locked in M0

| Resource | Path | Purpose |
|---|---|---|
| `GameplayConfig` | `data/config/gameplay_config.tres` | player_base_speed, gravity_magnitude, terminal_velocity, tap_flip_cooldown_ms, invulnerability_after_continue_s |
| `DifficultyCurve` | `data/difficulty/curve_normal.tres` | keyframes: `[{t_s, obstacle_density, world_speed, modifier_pool_weights}]` |
| `ModifierDefinition` | `data/modifiers/<id>.tres` | id, display_name, duration_s, cooldown_s, tags, exclusive_group, weight, params |
| `ObstaclePattern` | `data/obstacles/patterns/<id>.tres` | shape data, spawn constraints, fairness flags |
| `CosmeticDefinition` | `data/cosmetics/<id>.tres` | id, slot, unlock_condition, tier, palette_ref, trail_ref |
| `RewardTable` | `data/rewards/table_default.tres` | drop_weights per rarity, seed_stream_id |
| `AdConfig` | `data/config/ad_config.tres` | interstitial_cooldown_s, rewarded_placements, frequency_cap |
| `SfxBank` | `data/audio/sfx_bank.tres` | id → resource map |

### Access pattern

```gdscript
# NEVER:
player.speed = 300.0                       # ❌ magic number

# ALWAYS:
player.speed = GameplayConfig.player_base_speed()   # ✅ resource-backed
```

Where `GameplayConfig` is a thin wrapper:

```
GameplayConfig.get(key)
   → RemoteConfig.override("gameplay." + key) if activated
   → gameplay_config.tres[key]
   → hardcoded safe fallback
```

### Ships in M0
- All resource **types** (classes) defined.
- Empty/example `.tres` files created (populated in M1+).
- `GameplayConfig` wrapper with the three-layer lookup implemented.
- `docs/data_schemas.md` (drafted in M0) documents every schema.

---

## M0 Exit-criteria addendum

The original M0 exit criteria in `14_ROADMAP.md` are amended with:

- ✅ `IAnalyticsService` + `ConsoleAnalyticsService` + `MockAnalyticsService` compile and pass round-trip tests.
- ✅ `IRemoteConfigService` + `StaticRemoteConfigService` + `MockRemoteConfigService` compile and pass tests. Boot fetch times out gracefully.
- ✅ Settings schema includes all A3 accessibility keys and persists them.
- ✅ `IInputRecorder` interface exists (no-op impl) and is documented.
- ✅ `GameplayConfig` resource types + wrapper exist. Fetching `player_base_speed` returns the resource default when Remote Config is inactive.
- ✅ ADRs 008–011 written; ADR-012 drafted.
