# SHIFT // ZERO

> **Gravity is your only weapon.**
> A commercial-quality indie mobile game — one-finger 2D gravity-shift action with rules that rewrite themselves mid-run.

[![CI](https://img.shields.io/badge/CI-passing-brightgreen)](.github/workflows/ci.yml) &nbsp;
[![Engine](https://img.shields.io/badge/Godot-4.3%2B-478cbf)](https://godotengine.org) &nbsp;
[![Stage](https://img.shields.io/badge/stage-M0%20Foundation-8a2be2)](docs/14_ROADMAP.md)

---

## What is it?

Every 20–40 seconds, a **Modifier** rewrites part of the rulebook — gravity flip, low-g, time slow, magnetic walls, portals, blackout, reverse controls — so every run feels fresh. Easy to learn, hard to master.

- Mobile-first (Android) · fully responsive on tablets, foldables, Chromebooks, desktop web
- 60 FPS target on 2019 mid-range Android
- Offline-first — plays 100% without a network
- Ethical monetization — rewarded ads + Remove-Ads IAP + cosmetics. **Never pay-to-win.**
- Accessibility built-in: colorblind palettes, reduce-motion, haptic toggle, adjustable audio

---

## Repository map

```
shift-zero/
├── docs/                     ← 16 architecture & design docs (start here)
│   ├── README.md               overview + index
│   ├── 00_EXECUTIVE_SUMMARY.md
│   ├── 01–14_*.md              full pre-production package
│   ├── 15_M0_ADDENDA.md        user-approved M0 additions
│   └── decisions/              12 ADRs
├── game/                     ← Godot 4 project
│   ├── project.godot
│   ├── src/                    all code (core → services → systems → gameplay → presentation → app)
│   ├── data/                   designer-tunable resources (config, feature flags, remote-config defaults)
│   └── tests/unit/             GUT test suite
├── scripts/                  ← CI-parity + build scripts
├── .github/                  ← workflows, PR / issue templates
└── CHANGELOG.md
```

---

## Quickstart

### Prerequisites
- **Godot 4.3+** (standard build) — https://godotengine.org/download
- **Python 3.11+** (for CI-parity checks)

### First-time setup

```bash
./scripts/bootstrap.sh
```

This installs `gdtoolkit` (linter) and prints the Godot editor next steps.

### Open the project

1. Launch Godot 4.3.
2. Import `game/project.godot`.
3. Press **F5** to run the boot scene.

You should see the SHIFT // ZERO splash with `ready · 0.1.0-m0+dev` and see boot logs from `Logger`, `ServiceLocator`, and the analytics/remote-config services in the console.

### Run tests + lint locally (matches CI)

```bash
gdlint game/src game/tests
python3 scripts/check_layer_deps.py game/src
python3 scripts/check_forbidden.py
./scripts/run_tests.sh
```

---

## Architecture in 30 seconds

Five strict layers, dependency-checked by CI:

```
Presentation → Gameplay → Systems → Services → Core
```

- **Core** — `EventBus`, `ServiceLocator`, `Logger`, `Config`, `Result`, seeded `RNG`, `TimeSource`
- **Services** — every external integration behind an interface (`IAnalyticsService`, `IRemoteConfigService`, `ISaveService`, `IAdsService`, `IBillingService`, `ILocalizationService`, `IFeatureFlagsService`, `IInputRecorder`)
- **Systems** — Input, Haptics, Audio, Camera Director, Physics wrapper
- **Gameplay** — Player, ObstacleSpawner, ModifierManager, ScoreSystem — *nothing implemented yet*
- **Presentation** — Scenes, HUD, UIKit, VFX

Gameplay values are **data-driven** — `GameplayConfig` reads from `data/config/game_config.json` and Remote Config, never from magic numbers.

Full details: `docs/03_ARCHITECTURE.md`.

---

## Development status

| Milestone | Status |
|---|---|
| **M0 — Foundation** | ✅ complete (this commit) |
| M1 — Core Loop Prototype | ⏳ next |
| M2 — Vertical Slice | ⏳ |
| M3 — Content & Meta | ⏳ |
| M4 — Monetization + Live Services | ⏳ |
| M5 — Polish, QA, Localization | ⏳ |
| M6 — Soft Launch → Global Launch | ⏳ |

Full roadmap: `docs/14_ROADMAP.md`.

---

## Contributing

- All PRs go through CI (lint + layer-deps + unit tests).
- Follow `docs/07_CODING_STANDARDS.md`.
- Non-trivial architectural changes require an ADR in `docs/decisions/`.
- Branch naming: `feat/*`, `fix/*`, `chore/*`, `hotfix/*`. Commits use Conventional Commits.

---

## License

All rights reserved © 2026 SHIFT // ZERO. See `LICENSE`.
