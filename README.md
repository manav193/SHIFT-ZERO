# SHIFT // ZERO

> **Gravity is your only weapon.**

SHIFT // ZERO is a mobile-first Godot game foundation built around one-touch gravity shifting, rule-changing modifiers, and a high-contrast HUD language.

![SHIFT ZERO menu and HUD direction](https://raw.githubusercontent.com/manav193/MY-PORTFOLIO/main/frontend/images/sz_menu.png)

[View the product case study](https://my-portfolio-mu-jade-52.vercel.app/project-shift-zero.html)

## Core concept

Every run can be reshaped by modifiers such as gravity changes, low-gravity states, time effects, magnetic surfaces, portals, blackout conditions, or altered controls. The repository currently represents a documented and testable production foundation rather than a finished commercial release.

## Product direction

- Mobile-first one-touch interaction
- Gravity-shifting core mechanic
- Rule-changing gameplay modifiers
- High-contrast HUD designed for rapid readability
- Offline-first requirements
- Accessibility-oriented settings and input handling
- Ethical monetization goals documented before implementation

![SHIFT ZERO screen system](https://raw.githubusercontent.com/manav193/MY-PORTFOLIO/main/frontend/images/sz_screens.png)

## Engineering highlights

- Godot 4 and GDScript architecture
- Five dependency-checked layers
- Data-driven gameplay configuration
- Replaceable service interfaces
- Seeded randomness and input recording
- CI checks, linting, forbidden-pattern validation, and automated tests
- Architecture Decision Records and production roadmap

## Repository map

```text
.
├── docs/                 # Architecture, design, roadmap, and ADRs
├── game/                 # Godot project
│   ├── project.godot
│   ├── src/
│   ├── data/
│   └── tests/
├── scripts/              # CI-parity and validation scripts
├── .github/              # Workflows and templates
└── CHANGELOG.md
```

## Prerequisites

- Godot 4.3 or newer
- Python 3.11 or newer for validation scripts

## Run locally

```bash
git clone https://github.com/manav193/SHIFT-ZERO.git
cd SHIFT-ZERO
./scripts/bootstrap.sh
```

Then import `game/project.godot` into Godot and run the configured main scene.

## Validation

```bash
gdlint game/src game/tests
python3 scripts/check_layer_deps.py game/src
python3 scripts/check_forbidden.py
./scripts/run_tests.sh
```

## Architecture

```text
Presentation -> Gameplay -> Systems -> Services -> Core
```

- **Core:** configuration, events, results, timing, logging abstractions, and service location
- **Services:** external integrations behind interfaces
- **Systems:** input, audio, haptics, camera, physics, and related runtime systems
- **Gameplay:** player, modifiers, obstacles, scoring, and rule logic
- **Presentation:** scenes, HUD, UI kit, VFX, and menu flows

## Documentation

Start with [docs/README.md](docs/README.md) and the architecture documents under `docs/`.

## License

All rights reserved © 2026 SHIFT // ZERO. See [LICENSE](LICENSE).
