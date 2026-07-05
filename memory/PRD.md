# PRD — SHIFT // ZERO

## Original Problem Statement

Build a mobile app: commercial-quality indie game "SHIFT // ZERO".
- Mobile-first (Android), fully responsive for phones/tablets/desktop browsers
- One-finger gameplay
- Premium quality UI/UX, 60 FPS target
- Offline gameplay
- Clean modular scalable architecture
- Publish to Google Play, continuously updated

Instruction: Do NOT generate gameplay yet. Complete architecture & planning tasks first (15 items). Wait for approval before implementation.

## User Choices (session 1)

- **Genre:** One-finger 2D gravity-shift action with rotating gameplay modifiers (Gravity Flip, Low-G, Time Slow, Magnetic Walls, Portals, Blackout, Reverse Controls, etc.)
- **Engine choice:** Main agent to compare Unity / Godot 4 / Flutter+Flame / Phaser and recommend
- **Monetization:** Free with AdMob rewarded + optional Remove-Ads IAP + cosmetics. Never pay-to-win.
- **Online:** Offline-first, Google Play Games (cloud save, achievements, leaderboards) as future add-on
- **Art style:** Neon / Cyberpunk Minimalist
- **Also required:** Foldable + Chromebook + desktop-web responsive, lightweight download, long-term maintainable architecture, commercial indie polish (not prototype)

## Core Requirements (static)

- 60 FPS on 2019 mid-range Android (Snapdragon 6xx, 3 GB RAM)
- Cold start ≤ 3 s, warm start ≤ 1 s
- Offline-first save, corruption-safe, migrate-safe
- One-thumb reachable UI
- Colorblind + reduce-motion accessibility
- 8+ launch languages
- No dark monetization patterns
- Ethical rewarded ads + optional IAP (Remove Ads + cosmetics)

## Recommended Stack (documented in /app/docs/02_TECH_STACK.md)

- **Engine:** Godot 4.3+ LTS (GDScript primary, C# escape hatch)
- **Ads:** Google AdMob via community plugin (+ UMP consent)
- **IAP:** Google Play Billing v6+
- **Backend services:** Firebase (Analytics, Crashlytics, Remote Config)
- **Cloud save (v1.1):** Google Play Games Services v2
- **CI/CD:** GitHub Actions (matrix: Android debug/release + HTML5)
- **Backend (v1.2+):** Cloudflare Workers + D1 for signed leaderboard submissions

## Architecture Highlights

- 5-layer strict architecture: Presentation → Gameplay → Systems → Services → Core
- EventBus + ServiceLocator with typed `Result<T>` at all service boundaries
- Deterministic seeded RNG with named streams for replayable runs + Daily Challenge
- Save format: JSON + SHA-256 checksum + atomic double-buffered write + emergency slot + migrations
- Modifier registry pattern — adding a new modifier requires no engine code changes
- Layer-dependency enforced by CI script
- Perf gate on CI — PR fails if p95 frame > 17 ms

## Deliverables — Session 1 (Planning Phase)

Created full pre-production package under `/app/docs/`:

| # | File | Status |
|---|---|---|
| 00 | Executive Summary | ✅ done |
| 01 | Requirements Analysis (FR + NFR + KPIs + Risks) | ✅ done |
| 02 | Tech Stack (Unity vs Godot vs Flutter+Flame vs Phaser comparison + recommendation) | ✅ done |
| 03 | System Architecture (layers, data flow, bootstrap, determinism, threading) | ✅ done |
| 04 | Folder Structure (production-ready layout) | ✅ done |
| 05 | GDD Skeleton (20 sections) | ✅ done |
| 06 | TDD Skeleton (20 sections) | ✅ done |
| 07 | Coding Standards & Naming Conventions (enforceable rules) | ✅ done |
| 08 | Responsive Design Strategy (phones, tablets, foldables, desktop, ultra-wide) | ✅ done |
| 09 | Performance Optimization Strategy (device tiers, frame/memory budgets, CI gate) | ✅ done |
| 10 | Save System Strategy (atomic writes, migrations, cloud sync, recovery) | ✅ done |
| 11 | Game State Management Strategy (scopes, FSMs, EventBus discipline) | ✅ done |
| 12 | Asset Management Strategy (atlasing, PAD, loading, versioning) | ✅ done |
| 13 | Versioning Strategy (SemVer, save schema, feature flags, release tracks) | ✅ done |
| 14 | Development Roadmap (M0 → M6, ~18 weeks to global launch) | ✅ done |

## Approval Gate

Per user instruction, **no gameplay code has been written** and **no engine bootstrap has been performed**.
Awaiting explicit approval to begin **M0 — Foundation**.

## Backlog (post-approval)

**P0 — M0 Foundation (Week 1)**
- Bootstrap Godot 4 project at `/app/game/`
- Set up folder structure per `04_FOLDER_STRUCTURE.md`
- Autoloads: Logger, Config, ServiceLocator, EventBus, SceneRouter, App
- Core: Result<T>, seeded RNG, TimeSource, EventBus
- Mock implementations for all services (SaveService, AdsService, BillingService, etc.)
- CI: GitHub Actions with lint + unit tests + Android debug build
- Layer-dependency enforcement script
- README + quickstart

**P1 — M1 Core Loop Prototype (Weeks 2–3)**
- PlayerController + gravity flip
- ObstacleSpawner + 3 patterns
- ScoreSystem + minimal HUD
- 3 modifiers: Gravity Flip, Low Gravity, Time Slow
- Local save v1

**P2 — M2 Vertical Slice (Weeks 4–6)**
- Neon art pass on Biome 1
- 8 modifiers
- Adaptive audio + haptics
- Full menu → game → game over loop
- Settings + localization scaffolding

Further milestones in `/app/docs/14_ROADMAP.md`.

## Next Action Items

1. User reviews `/app/docs/` package.
2. User replies with approval or revision requests.
3. On approval, main agent begins M0 (Foundation).
