# 06 — Technical Design Document (TDD) — Skeleton

> The TDD is the engineering counterpart to the GDD. Every section here is a promise that engineering will produce a precise technical spec before implementation of the corresponding feature begins.

---

## 1. Purpose & Audience
### 1.1 Purpose of this document
### 1.2 Audience (engineers, tech artists, QA)
### 1.3 Relationship to the GDD
### 1.4 Change control process

## 2. System Architecture Reference
### 2.1 Layer diagram (see `03_ARCHITECTURE.md`)
### 2.2 Runtime bootstrap sequence
### 2.3 Deployment topology (client-only for v1.0; +backend for v1.1)

## 3. Engine Configuration
### 3.1 Godot project settings that must be locked
- `physics_fps = 60` fixed
- `physics_jitter_fix = 0`
- `low_processor_usage_mode = true` when in menus
- `msaa_2d = disabled`, prefer FXAA where needed
- Renderer: **Compatibility** on Web/low-end Android, **Mobile** on mid+ Android
### 3.2 Project autoloads (order matters — see `04_FOLDER_STRUCTURE.md §3`)
### 3.3 Input map (single source of truth)
### 3.4 Layers & masks (physics + rendering)

## 4. Core Layer Spec
### 4.1 EventBus API (typed channels, payload shapes)
### 4.2 ServiceLocator API + lifetime rules
### 4.3 Result<T> conventions
### 4.4 RNG streams (world / spawn / cosmetic / vfx)
### 4.5 TimeSource semantics
### 4.6 Logger sinks & levels
### 4.7 Config loader (env + Remote Config merge)

## 5. Services Layer Spec (one subsection per service)
### 5.1 SaveService — see also `10_SAVE_SYSTEM.md`
### 5.2 SettingsService
### 5.3 AdsService — request/response contract, consent gating, frequency caps
### 5.4 BillingService — SKUs, purchase state machine, restore flow
### 5.5 AnalyticsService — event schema, consent, batching
### 5.6 RemoteConfigService — key schema, defaults, fetch strategy
### 5.7 CloudSaveService — snapshot format, conflict resolution
### 5.8 LocalizationService — plural rules, fallbacks
### 5.9 FeatureFlagService — override precedence (local → remote → build)

## 6. Systems Layer Spec
### 6.1 InputSystem — event normalization, gesture recognition, dead-zone rules
### 6.2 HapticsSystem — platform capability table
### 6.3 AudioBusManager — bus graph, ducking rules, mute-on-focus-loss
### 6.4 CameraDirector — screen-shake decay curves, zoom envelopes
### 6.5 AnimationController — palette blending, HUD micro-anim spec
### 6.6 PhysicsWrapper — gravity vector API, layer masks, contact callbacks

## 7. Gameplay Layer Spec
### 7.1 RunDirector — state machine for a single run
### 7.2 PlayerController — physics + input contract + edge cases (falling off screen)
### 7.3 ObstacleSpawner — pattern picker, fairness guards, pool size math
### 7.4 ModifierManager — scheduling algorithm, compatibility matrix enforcement
### 7.5 IModifier interface — enter/tick/exit contract, rollback guarantees
### 7.6 ScoreSystem — distance formula, combo multiplier rules, anti-cheat notes
### 7.7 DifficultyCurve — data schema, interpolation rules
### 7.8 DailyChallenge — seed derivation, submission format

## 8. Analytics Event Schema (initial cut)
| Event | When | Params |
|---|---|---|
| `app_start` | boot | build_ver, locale, device_bucket |
| `run_started` | tap-to-play resolved | seed, difficulty_id, modifiers_pool |
| `modifier_activated` | modifier enters | modifier_id, run_time |
| `player_died` | death | modifier_id_active, obstacle_id, run_time, score |
| `run_ended` | game over shown | score, best_score, duration_s, deaths_by_modifier |
| `ad_requested` / `ad_shown` / `ad_clicked` / `ad_reward_granted` | ads lifecycle | placement, format |
| `iap_impression` / `iap_purchase_start` / `iap_purchase_success` / `iap_purchase_error` | IAP funnel | sku, price_bucket, error_code |
| `cosmetic_equipped` | equip | cosmetic_id |
| `settings_changed` | any settings toggle | key, value |
| `daily_started` / `daily_completed` | daily challenge | date_utc, score |

Full schema (with param types + PII policy) lives in `docs/analytics/schema.md` (to be created during M4).

## 9. Networking Spec
### 9.1 v1.0 — no networking beyond ads/IAP/analytics/config
### 9.2 v1.1 — GPGS integration
### 9.3 v1.2 — optional custom leaderboard backend (Cloudflare Workers + D1) with HMAC-signed score payload

## 10. Persistence Spec
### 10.1 Save file format (see `10_SAVE_SYSTEM.md`)
### 10.2 Settings file format
### 10.3 Cache & telemetry queue formats
### 10.4 Migration policy

## 11. Rendering & VFX Spec
### 11.1 Sprite budget per scene (target ≤ 400 visible)
### 11.2 Draw-call budget (target ≤ 60 on mid-range)
### 11.3 Shader inventory (glow, chromatic aberration, distortion, palette-swap)
### 11.4 Particle system caps (max 800 live particles)
### 11.5 Post-processing: **disabled on low-end tier**; on mid+ enable bloom via low-cost blur pass

## 12. Audio Spec
### 12.1 Bus graph
### 12.2 SFX bank format + naming
### 12.3 Music streaming vs. loaded — streaming for tracks > 200 KB
### 12.4 Latency budget (input → SFX ≤ 40 ms)

## 13. Internationalization Spec
### 13.1 Translation table format (Godot CSV)
### 13.2 Font fallback chain per language
### 13.3 RTL handling policy (not v1.0)
### 13.4 Locale-driven number/date formatting

## 14. Performance Spec (see `09_PERFORMANCE_STRATEGY.md`)
### 14.1 Frame budgets per tier
### 14.2 Memory budgets per tier
### 14.3 Startup budget
### 14.4 Perf gate & CI thresholds

## 15. Security & Anti-cheat
### 15.1 IAP receipt validation flow
### 15.2 Leaderboard score signing (v1.2)
### 15.3 Local save tamper policy (best-effort obfuscation, never trust client)
### 15.4 Consent + privacy manifest

## 16. Build, Release & Distribution
### 16.1 Build variants: `dev`, `beta`, `release`
### 16.2 Signing keys management
### 16.3 Play Console tracks: internal → closed → open → production
### 16.4 Web deployment targets (own domain + itch.io mirror)
### 16.5 Rollback procedure

## 17. Observability & Ops
### 17.1 Dashboards (KPIs, crashes, ad revenue)
### 17.2 Alerts (crash spike, DAU cliff, ad-fill drop)
### 17.3 Runbook stubs (server outage, key rotation, plugin bit-rot)

## 18. Testing Strategy
### 18.1 Unit tests (GUT)
### 18.2 Integration tests (headless scenes)
### 18.3 Replay tests (deterministic input → expected score)
### 18.4 Perf regression tests (CI gate)
### 18.5 Device matrix QA plan
### 18.6 Playtest instrumentation

## 19. Risk Register
### 19.1 Technical risks + mitigations
### 19.2 Third-party SDK risks
### 19.3 Store policy risks

## 20. Appendices
### 20.1 Glossary of engineering terms
### 20.2 Reference links (Godot docs, plugin repos)
### 20.3 Open engineering questions
