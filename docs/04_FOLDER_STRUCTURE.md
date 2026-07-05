# 04 — Folder Structure

## 1. Repository Root

```
shift-zero/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                # lint + unit tests on every PR
│   │   ├── build-android.yml     # AAB build + upload to Play Internal
│   │   ├── build-web.yml         # HTML5 build + deploy to itch.io
│   │   └── perf-gate.yml         # headless perf regression check
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE.md
│
├── docs/                          # (this folder) — architecture & design docs
│   ├── README.md
│   ├── 00_EXECUTIVE_SUMMARY.md
│   ├── 01_REQUIREMENTS_ANALYSIS.md
│   ├── 02_TECH_STACK.md
│   ├── 03_ARCHITECTURE.md
│   ├── 04_FOLDER_STRUCTURE.md
│   ├── 05_GDD_TEMPLATE.md
│   ├── 06_TDD_TEMPLATE.md
│   ├── 07_CODING_STANDARDS.md
│   ├── 08_RESPONSIVE_STRATEGY.md
│   ├── 09_PERFORMANCE_STRATEGY.md
│   ├── 10_SAVE_SYSTEM.md
│   ├── 11_STATE_MANAGEMENT.md
│   ├── 12_ASSET_MANAGEMENT.md
│   ├── 13_VERSIONING_STRATEGY.md
│   ├── 14_ROADMAP.md
│   ├── decisions/                # ADRs
│   │   ├── ADR-001-choose-godot4.md
│   │   ├── ADR-002-gdscript-primary.md
│   │   └── ...
│   └── art/                      # style guide, palette references, mockups
│
├── game/                          # Godot project root (project.godot lives here)
│   ├── project.godot
│   ├── icon.svg
│   ├── export_presets.cfg
│   ├── addons/                   # third-party Godot plugins (git-vendored, pinned)
│   │   ├── godot-admob-plus/
│   │   ├── godot-play-billing/
│   │   ├── godot-firebase/
│   │   └── gut/                  # test framework
│   │
│   ├── src/                      # ALL our code lives here
│   │   ├── core/                 # ↓ dependency-free (or engine-only) utilities
│   │   │   ├── event_bus.gd
│   │   │   ├── events.gd         # channel constants + payload typedefs
│   │   │   ├── service_locator.gd
│   │   │   ├── result.gd
│   │   │   ├── rng.gd
│   │   │   ├── time_source.gd
│   │   │   ├── logger.gd
│   │   │   ├── config.gd
│   │   │   ├── schema.gd
│   │   │   └── migrations.gd
│   │   │
│   │   ├── services/             # interfaces + implementations
│   │   │   ├── save/
│   │   │   │   ├── i_save_service.gd
│   │   │   │   ├── filesystem_save_service.gd
│   │   │   │   ├── localstorage_save_service.gd     # web
│   │   │   │   ├── in_memory_save_service.gd        # tests
│   │   │   │   └── save_schema.gd
│   │   │   ├── settings/
│   │   │   ├── ads/
│   │   │   │   ├── i_ads_service.gd
│   │   │   │   ├── admob_ads_service.gd
│   │   │   │   ├── null_ads_service.gd
│   │   │   │   └── mock_ads_service.gd
│   │   │   ├── billing/
│   │   │   ├── analytics/
│   │   │   ├── remote_config/
│   │   │   ├── cloud_save/
│   │   │   ├── localization/
│   │   │   ├── feature_flags/
│   │   │   └── logger/           # (thin wrapper on core Logger for prod sinks)
│   │   │
│   │   ├── systems/              # engine-adjacent runtime systems
│   │   │   ├── input/
│   │   │   ├── haptics/
│   │   │   ├── audio/
│   │   │   ├── camera_director/
│   │   │   ├── animation/
│   │   │   └── physics_wrapper/
│   │   │
│   │   ├── gameplay/
│   │   │   ├── player/
│   │   │   │   ├── player.tscn
│   │   │   │   ├── player_controller.gd
│   │   │   │   └── gravity_body.gd
│   │   │   ├── world/
│   │   │   │   ├── world.tscn
│   │   │   │   ├── parallax_layers.gd
│   │   │   │   ├── biome_switcher.gd
│   │   │   │   └── palette_animator.gd
│   │   │   ├── obstacles/
│   │   │   │   ├── obstacle_spawner.gd
│   │   │   │   ├── obstacle_pool.gd
│   │   │   │   └── patterns/     # data-driven pattern .tres files
│   │   │   ├── modifiers/
│   │   │   │   ├── i_modifier.gd
│   │   │   │   ├── modifier_manager.gd
│   │   │   │   ├── gravity_flip_modifier.gd
│   │   │   │   ├── low_gravity_modifier.gd
│   │   │   │   ├── time_slow_modifier.gd
│   │   │   │   ├── magnetic_walls_modifier.gd
│   │   │   │   ├── portals_modifier.gd
│   │   │   │   ├── blackout_modifier.gd
│   │   │   │   ├── reverse_controls_modifier.gd
│   │   │   │   └── ...           # 15+ at v1.0
│   │   │   ├── score/
│   │   │   ├── difficulty/
│   │   │   ├── daily_challenge/
│   │   │   └── run_director.gd   # top-level game-run orchestrator
│   │   │
│   │   ├── presentation/
│   │   │   ├── scenes/
│   │   │   │   ├── boot.tscn
│   │   │   │   ├── main_menu.tscn
│   │   │   │   ├── game.tscn
│   │   │   │   ├── game_over.tscn
│   │   │   │   ├── cosmetics.tscn
│   │   │   │   ├── settings.tscn
│   │   │   │   └── daily.tscn
│   │   │   ├── hud/
│   │   │   ├── modals/
│   │   │   ├── ui_kit/           # Button, Toggle, Slider, Toast, Modal shell
│   │   │   ├── vfx/
│   │   │   │   ├── shaders/
│   │   │   │   ├── particles/
│   │   │   │   └── vfx_orchestrator.gd
│   │   │   └── theme/
│   │   │       ├── theme.tres
│   │   │       ├── palette_neon_default.tres
│   │   │       ├── palette_deuteranopia.tres
│   │   │       └── typography.tres
│   │   │
│   │   └── app/                  # bootstrap + scene router + globals
│   │       ├── app.gd            # main autoload orchestrator
│   │       ├── scene_router.gd
│   │       └── autoloads.gd      # single source of truth for autoload registration
│   │
│   ├── data/                     # all designer-tunable content
│   │   ├── config/
│   │   │   ├── game_config.tres
│   │   │   ├── feature_flags.json
│   │   │   └── remote_config_defaults.json
│   │   ├── modifiers/
│   │   │   ├── registry.tres
│   │   │   └── *.tres            # one per modifier metadata
│   │   ├── obstacles/
│   │   ├── biomes/
│   │   ├── cosmetics/
│   │   │   ├── skins/
│   │   │   ├── trails/
│   │   │   └── palettes/
│   │   ├── difficulty/
│   │   │   ├── curve_normal.tres
│   │   │   ├── curve_daily.tres
│   │   │   └── curve_tutorial.tres
│   │   └── audio/
│   │       ├── sfx_bank.tres
│   │       └── music_playlist.tres
│   │
│   ├── assets/                   # raw + imported assets
│   │   ├── sprites/
│   │   │   ├── characters/
│   │   │   ├── obstacles/
│   │   │   ├── ui/
│   │   │   └── atlases/          # generated packs
│   │   ├── shaders/
│   │   ├── fonts/
│   │   ├── audio/
│   │   │   ├── music/
│   │   │   ├── sfx/
│   │   │   └── stingers/
│   │   ├── i18n/
│   │   │   └── translations.csv
│   │   └── raw/                  # source files, excluded from export
│   │       ├── figma_exports/
│   │       └── aseprite/
│   │
│   ├── tests/
│   │   ├── unit/
│   │   │   ├── core/
│   │   │   ├── services/
│   │   │   └── gameplay/
│   │   ├── integration/
│   │   ├── replay/               # deterministic replay fixtures
│   │   └── perf/
│   │
│   ├── platform/                 # per-platform manifests & configs
│   │   ├── android/
│   │   │   ├── AndroidManifest.xml
│   │   │   ├── build.gradle
│   │   │   ├── res/              # icons, splashes, adaptive icons
│   │   │   └── keystore.env.example
│   │   ├── web/
│   │   │   ├── index.html.template
│   │   │   └── pwa/manifest.webmanifest
│   │   └── ios/                  # placeholder for post-v1.0
│   │
│   └── tools/                    # dev-only editor scripts, generators, gizmos
│       ├── atlas_builder.gd
│       ├── modifier_scaffolder.gd
│       └── perf_overlay.gd
│
├── scripts/                      # repo-level shell / python scripts
│   ├── bootstrap.sh              # first-time contributor setup
│   ├── build_android.sh
│   ├── build_web.sh
│   ├── run_tests.sh
│   ├── gen_translations_stub.py
│   └── check_layer_deps.py       # enforces layer dependency rules
│
├── .editorconfig
├── .gitattributes
├── .gitignore
├── LICENSE                       # game code license (proprietary or chosen)
├── CHANGELOG.md                  # user-facing release notes
├── ARCHITECTURE.md -> docs/03_ARCHITECTURE.md
└── README.md                     # repo overview + quickstart
```

## 2. Conventions

- All folder names: `snake_case`.
- One scene (`.tscn`) per major node; its script (`.gd`) sits next to it with the same base name.
- `data/` is designer territory: never contains code, only `.tres`, `.json`, `.csv`, `.png` references.
- `assets/raw/` is excluded from Godot import (via `.gdignore`) and from Android/Web exports.
- `addons/` is git-vendored, pinned to exact tags. No live-fetch from network.

## 3. Autoloads (order = boot order)

Registered in `game/project.godot` and mirrored in `src/app/autoloads.gd` for documentation:

1. `Logger` — `src/core/logger.gd`
2. `Config` — `src/core/config.gd`
3. `ServiceLocator` — `src/core/service_locator.gd`
4. `EventBus` — `src/core/event_bus.gd`
5. `SceneRouter` — `src/app/scene_router.gd`
6. `App` — `src/app/app.gd` *(runs the boot sequence, then hands off)*

All other services are **not** autoloads — they are created and registered by `App` via `ServiceLocator`. This keeps the autoload list tiny and testable.

## 4. `.gitignore` (highlights)

```
# Godot
.godot/
.import/
export_presets.cfg    # keep template only — real one is generated locally
*.import

# Android
game/platform/android/keystore.env
game/platform/android/build/
*.aab
*.apk

# Web
game/platform/web/build/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/

# CI
coverage/
perf-reports/
```

## 5. Naming Baseline (see `07_CODING_STANDARDS.md` for full rules)

| Kind | Convention | Example |
|---|---|---|
| File / folder | `snake_case` | `modifier_manager.gd` |
| Class name | `PascalCase` | `class_name ModifierManager` |
| Function | `snake_case` | `apply_modifier()` |
| Signal | `snake_case`, past-tense | `modifier_activated` |
| Constant | `SCREAMING_SNAKE_CASE` | `MAX_MODIFIER_STACK` |
| Resource file | `snake_case.tres` | `gravity_flip_modifier.tres` |
| Scene file | `snake_case.tscn` | `main_menu.tscn` |
