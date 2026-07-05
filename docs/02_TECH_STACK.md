# 02 — Technology Stack

## 1. Engine / Framework Selection

We evaluated four candidates against the SHIFT // ZERO requirements. Scoring is **1 (weak) → 5 (excellent)** with equal weight unless noted.

| Criterion (weight) | Unity 6 | **Godot 4.3+** | Flutter + Flame | Phaser 3 + Capacitor |
|---|:-:|:-:|:-:|:-:|
| 2D rendering quality & perf on Android (×2) | 4 | **5** | 3 | 3 |
| 60 FPS on 2019 mid-range Android (×2) | 4 | **5** | 3 | 3 |
| Base install size / APK footprint (×2) | 2 | **5** | 3 | 3 |
| Iteration speed (edit → play) | 3 | **5** | 4 | 4 |
| Editor / tooling maturity | **5** | 4 | 3 | 2 |
| Native Android AdMob + Play Billing plugins | **5** | 4 | 4 | 3 |
| Google Play Games Services v2 support | **5** | 4 | 3 | 2 |
| HTML5 / desktop-browser export | 3 | **5** | 3 | **5** |
| Foldable & responsive UI support | 4 | 4 | **5** | 4 |
| Long-term license cost / royalties | 2 | **5** | **5** | **5** |
| Talent pool / hiring | **5** | 3 | 4 | 4 |
| Ecosystem for premium 2D VFX (shaders, particles) | 4 | **5** | 3 | 3 |
| Physics for gravity-shift gameplay | 4 | **5** | 3 | 4 |
| Determinism controllability | 4 | **5** | 3 | 3 |
| Community + docs longevity | **5** | 4 | 4 | 4 |
| **Weighted total** | 58 | **69** | 51 | 54 |

### Why Godot 4 wins for this specific title

1. **2D-first architecture.** Godot's 2D renderer is not a 3D pipeline pretending to draw sprites — it's a purpose-built 2D engine. For a shader-heavy neon minimalist look at 60 FPS on mid Android, this is decisive.
2. **Tiny footprint.** Godot Android exports come in around 25–35 MB base. Unity's Mono/IL2CPP runtime + core modules typically add 40–60 MB before your game.
3. **MIT license, zero royalties, forever.** No revenue thresholds, no per-seat cost, no runtime fee drama. Critical for a commercial indie planning years of updates.
4. **Iteration speed.** GDScript hot-reload + instant scene reloads compress dev feedback loops massively vs. Unity's script recompile.
5. **HTML5 export is a first-class citizen.** Compressed builds are small, WebGL2 output is competitive. We can ship desktop-browser and itch.io mirrors with almost zero extra work.
6. **Signals + Nodes fit our event-driven architecture natively** — no need to bolt on a MessageBus package.
7. **Escape hatch: C#.** Godot 4 supports C# (.NET 8). For any hot path where GDScript is not enough (rare in 2D), we can drop into typed C# without leaving the engine.

### Where Unity would have won

- Corporate polish of AdMob / Play Billing / GPGS SDKs.
- Larger hiring pool.
- Battle-tested on hundreds of top-grossing mobile games.

We accept these trade-offs because (a) our monetization needs are covered by well-maintained Godot community plugins, and (b) our team-size fits Godot's iteration model better.

### Contingency

If, during **M0**, we discover a blocker in the Godot AdMob or GPGS plugin ecosystem, we will re-evaluate Unity 6 LTS. The architecture (see `03_ARCHITECTURE.md`) is designed engine-agnostically at the Services boundary so a swap is painful but not catastrophic.

## 2. Language(s)

- **GDScript 2.0** — primary. 90% of gameplay + UI code.
- **C# (.NET 8)** — optional, reserved for:
  - Deterministic fixed-point math (if physics determinism gets stricter).
  - Perf-critical simulation (procedural generation, collision broadphase if needed).
- **Rust** — *no*. Not worth the FFI complexity for a 2D indie game.

## 3. Full Stack

### 3.1 Client (game)

| Layer | Choice | Rationale |
|---|---|---|
| Engine | **Godot 4.3+ (LTS branch)** | See §1 |
| Language | GDScript + optional C# | See §2 |
| Physics | Godot 2D (Box2D-derived) | Fits gravity-flip requirement; deterministic per-seed |
| UI | Godot Control nodes + custom theme | Native, resolution-agnostic, no external UI kit |
| Animation | Godot AnimationPlayer + Tween | Ships in engine; sufficient for our style |
| Shaders | Godot Shader Language (GLSL-like) | For neon glow, chromatic aberration, distortion FX |
| Audio | Godot AudioStreamPlayer + buses | Positional + music/SFX buses + ducking |
| Localization | Godot CSV translation | Built-in; supports plural rules |

### 3.2 Services (mobile-side)

| Concern | Choice | Notes |
|---|---|---|
| Ads | **Google AdMob** via `poing-studios/godot-admob-plus` (v4.x) | Rewarded + interstitial + consent (UMP) |
| IAP | **Google Play Billing v6+** via `godotengine/godot-google-play-billing` | Remove-ads + cosmetics |
| Analytics | **Firebase Analytics** via community plugin | GDPR-aware event schema |
| Crash reporting | **Firebase Crashlytics** | Symbolicated stack traces |
| Remote Config | **Firebase Remote Config** | Difficulty tuning, ad caps, feature flags |
| Cloud Save (v1.1) | **Google Play Games Services v2** | Snapshots API |
| Push (post v1.0) | **Firebase Cloud Messaging** | Optional |

All of the above are **wrapped behind interfaces** in the Services layer (see `03_ARCHITECTURE.md §Services`). Gameplay code never touches an SDK directly.

### 3.3 Backend (optional, v1.1+)

Not required for v1.0 (offline-first). When leaderboards graduate beyond GPGS:

- **Cloudflare Workers + D1 (SQLite)** — score submission with HMAC-signed payloads; cheap, global, serverless.
- Alternative: **Supabase** (Postgres + Edge Functions).

### 3.4 Tooling & Ops

| Concern | Choice |
|---|---|
| Version control | Git (GitHub) |
| Branch model | Trunk-based with short-lived feature branches; `main` is always shippable |
| CI/CD | GitHub Actions — matrix builds (Android debug + release + HTML5) |
| Static analysis | `gdlint` (GDScript) + `dotnet format` (C#) + custom Godot import checks |
| Perf gate | Headless Godot run of a canned 60 s replay; fails PR if avg frame > 17 ms |
| Signing | Play App Signing (Google-managed) + upload key in GitHub Encrypted Secrets |
| Distribution (dev) | Firebase App Distribution or Google Play Internal Testing track |
| Distribution (prod) | Google Play Console — Internal → Closed → Open → Production |
| Bug tracking | GitHub Issues + a Projects board |
| Design assets | Figma (UI) + Aseprite (sprites, if pixel) or Illustrator (vector) |
| Audio | Reaper or Ableton; SFX via Soundly / freesound + custom sweetening |

### 3.5 Third-party libraries — allow-list policy

We keep dependencies minimal. Every dep must:
- Have activity in the last 12 months
- Have a permissive license (MIT / Apache 2 / BSD)
- Be pinned to an exact version in the project manifest
- Be justified in a `docs/decisions/ADR-xxx.md` (Architecture Decision Record)

## 4. Development Environment

- **OS:** Windows 11 or macOS 14+ or Ubuntu 22.04+
- **Editors:** Godot 4.3+ editor; VS Code with `godot-tools` extension for GDScript LSP.
- **Android SDK:** cmdline-tools + platform 34 + build-tools 34.0.0 + Java 17 JDK.
- **Emulator matrix:** Pixel 4a (mid), Pixel 7 (high), Samsung Fold 5 (foldable), 8″ tablet, Chromebook.
- **Physical device matrix (QA):** at least 1 device from each of Samsung, Xiaomi, Motorola, and one 2019 mid-range Snapdragon 6xx device.

## 5. Reasoning — why each choice, one line each

- **Godot 4** — best 2D perf + smallest footprint + zero royalty for a commercial 2D indie.
- **GDScript primary** — fastest iteration and lowest onboarding cost; adequate perf for 2D.
- **C# escape hatch** — insurance policy for hot paths without switching engines.
- **AdMob + Play Billing** — highest fill / revenue in India/LatAm/SEA where the game will land.
- **Firebase (Analytics/Crashlytics/Remote Config)** — free at our scale, mature Android SDKs, one console.
- **GPGS v2 in v1.1** — nice-to-have, defer to avoid slowing launch.
- **GitHub Actions** — free minutes cover us, integrates with the trunk-based workflow.
- **Cloudflare Workers backend later** — pay-as-you-go, no ops overhead, global edge.
