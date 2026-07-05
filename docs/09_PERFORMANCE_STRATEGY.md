# 09 — Performance Optimization Strategy

The 60 FPS target is a **hard requirement**, not aspirational. This doc defines budgets, tooling, and enforcement.

## 1. Device Tiers

We define three tiers and target them explicitly.

| Tier | Reference device | GPU class | Rendering quality |
|---|---|---|---|
| **T-Low** | Snapdragon 665 / Helio G80, 3 GB RAM (2019 mid) | Adreno 610 / Mali-G52 | Compatibility renderer; particles halved; shaders in low-end mode; no bloom |
| **T-Mid** | Snapdragon 7-series, 6 GB RAM (2021+) | Adreno 6xx | Mobile renderer; standard particles; bloom on |
| **T-High** | Snapdragon 8 / A16-class, 8+ GB RAM | Adreno 7xx+ | Mobile renderer; full VFX; 120 Hz where display supports |

Tier detection at boot: heuristic on `device_model`, `renderer_info`, `total_memory`. Confirmed by a 3 s micro-benchmark on first launch. Users can override in Settings.

## 2. Frame Budget (16.6 ms @ 60 FPS)

| Slice | Budget (ms) | Notes |
|---|---:|---|
| Gameplay logic (`_process`) | 4.0 | modifiers + spawner + score |
| Physics (`_physics_process`) | 3.0 | 60 Hz fixed; broadphase must stay flat with obstacle pool |
| Rendering (draw calls, culling, VFX) | 6.0 | |
| Audio dispatch | 0.5 | |
| Input + haptics | 0.3 | |
| Headroom | 2.8 | *never* pushed to zero — heat/throttling reserve |

For 120 Hz devices (T-High), budgets are halved on the gameplay/physics/render slices; audio+input stays unchanged.

## 3. Memory Budget

| Tier | Peak RAM | Peak textures |
|---|---:|---:|
| T-Low | 250 MB | 60 MB |
| T-Mid | 400 MB | 100 MB |
| T-High | 600 MB | 160 MB |

Enforcement:
- Global asset budget tracked at build time (see `12_ASSET_MANAGEMENT.md`).
- Runtime memory sampler asserts against the tier budget every 5 s in DEV builds; logs a warning in RELEASE.

## 4. Startup Budget

| Phase | Budget |
|---|---:|
| Native process → Godot main | 500 ms |
| Autoload boot (Logger → Config → EventBus) | 200 ms |
| First frame of Main Menu drawn | +500 ms |
| Interactive (input accepted) | 3.0 s cold, 1.0 s warm |

Any lazy work is deferred **after** the Main Menu is interactive:
- AdMob init
- Remote Config fetch (with 1 s timeout, then non-blocking)
- Cloud save probe

## 5. CPU Optimization Techniques

- **Object pooling** for anything that spawns/despawns often: obstacles, VFX, sound emitters, floating text.
- **No allocations in hot paths.** Reuse `Vector2` buffers, prefer `PackedFloat32Array` for bulk math.
- **Avoid `get_node()` per frame.** Cache references in `_ready`.
- **Signal wisely.** Cross-system chatter goes through EventBus (batched at frame boundary); intra-node chatter stays on Godot signals.
- **Batch physics queries** through the PhysicsWrapper — combine raycasts.
- **Deterministic order** — spawner, then modifier tick, then player, then camera. No re-entrancy.

## 6. GPU / Rendering Optimization

- Draw-call target: **≤ 60** typical, hard cap 90.
- Single texture atlas per biome + one UI atlas. Never sample from raw sprites.
- All UI in one `CanvasLayer`, one common `Theme` → engine batches efficiently.
- Particles use `GPUParticles2D` with pre-computed lifetime curves; live particle cap **800**.
- **Shader complexity budget:**
  - fragment shader ≤ 60 GPU cycles equivalent (measured via Godot's frame profiler)
  - no texture-fetches inside loops
  - `low_end_disable` variant for T-Low
- Bloom is a **cheap two-pass blur**, not a full HDR bloom. Disabled on T-Low.

## 7. Asset Optimization

- Textures: **ASTC 4×4** on Android; WebP fallback on Web.
- Audio: SFX as OGG Vorbis (short, ≤ 100 KB); music streamed OGG.
- Sprite atlases packed with 4-pixel padding to avoid mipmap bleed.
- No sprite > 2048×2048.
- Fonts subsetted per script (Latin, Cyrillic, CJK, Devanagari) — no monolithic 20 MB font.

## 8. Dynamic Quality Scaler

Runtime component that watches frame time and can:

1. Reduce particle multiplier (1.0 → 0.5 → 0.25)
2. Disable bloom
3. Drop background parallax from 4 layers → 2
4. Reduce trail length
5. Lower render resolution scale (100% → 85%)

Trigger: rolling 60-frame p95 > 18.5 ms → step down one level. Recovery after 10 s of clean frames.

User-facing: a **Quality** setting has Auto / Low / Med / High.

## 9. Benchmarking & CI

- **Perf gate on CI** — a headless Godot run replays a canned 60 s scenario on Linux CI runners. Fails PR if:
  - Mean frame > 12 ms
  - p95 frame > 17 ms
  - Memory delta > 20 MB across the run (leak detector)
- **On-device manual benchmark** — a hidden dev-only screen runs 5 min of scripted gameplay and produces a report (fps histogram, memory, draw calls) exported to JSON.

## 10. Profiling Tools

- Godot built-in Frame Profiler (per-node time, memory).
- Godot Debug Menu (in-game overlay, gated behind a dev gesture).
- Android Studio Profiler for CPU / GPU / battery deep dives.
- Chrome DevTools Performance panel for web builds.
- Systrace / Perfetto for ANR investigation.

## 11. Battery & Thermal

- Reduce `Engine.max_fps` to 30 in menus if `low_processor_usage_mode` is off but menu is idle for > 10 s.
- Respect the OS thermal state — on Android 12+, `getPowerService()` API surfaces thermal warnings; we drop to T-Low quality when in `MODERATE` or higher.
- No sustained > 90% CPU. Rest between waves.
- Audio streaming avoids waking the disk more than once per 2 s.

## 12. Web-Specific

- WebGL2 compatibility profile.
- Assets served with `Content-Encoding: gzip` (or brotli).
- Godot HTML5 template stripped of unused modules.
- Set `requestAnimationFrame` throttled to match tab visibility (Godot handles by default).

## 13. Anti-Patterns (banned)

- ❌ Instantiating a new `Node` every frame.
- ❌ `find_node()` recursive lookups at runtime.
- ❌ `PackedScene.instantiate()` in a tight loop without pooling.
- ❌ Full-screen post-process on T-Low.
- ❌ Loading textures synchronously mid-run.
- ❌ String concatenation in `_process` (allocates).

## 14. Performance Definition of Done

A feature is "perf-done" when:
1. It passes local perf smoke test.
2. It passes the CI perf gate.
3. It has been sampled on the T-Low reference device for 3 minutes without drops or memory growth.
4. It has an entry in the analytics events schema so we can see it in the wild.
