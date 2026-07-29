# SHIFT // ZERO

> **Gravity is your only weapon.**

SHIFT // ZERO is a mobile-first Godot game foundation built around one-touch gravity shifting, rule-changing modifiers, and a high-contrast HUD language.

[![CI](https://img.shields.io/badge/CI-automated-brightgreen)](.github/workflows/ci.yml)
[![Engine](https://img.shields.io/badge/Godot-4.3%2B-478cbf)](https://godotengine.org)

## Core concept

Every run can be reshaped by modifiers such as gravity changes, low-gravity states, time effects, magnetic surfaces, portals, blackout conditions, or altered controls. The project is structured as a reusable game foundation rather than a finished commercial release.

## Current focus

- Mobile-first one-touch interaction
- Godot 4 and GDScript architecture
- Data-driven gameplay configuration
- Layered services, systems, gameplay, and presentation code
- High-contrast HUD and premium UI direction
- CI checks, linting, dependency rules, and automated tests
- Offline-first design goals
- Accessibility-oriented settings and input handling

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
- Python 3.11 or newer for repository validation scripts

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

Use the current workflow files and scripts as the source of truth if commands evolve.

## Architecture

```text
Presentation -> Gameplay -> Systems -> Services -> Core
```

- **Core:** configuration, events, results, timing, logging abstractions, and service location
- **Services:** external integrations behind interfaces
- **Systems:** input, audio, haptics, camera, physics, and related runtime systems
- **Gameplay:** player, modifiers, obstacles, scoring, and rule logic
- **Presentation:** scenes, HUD, UI kit, VFX, and menu flows

Gameplay values are intended to remain data-driven rather than embedded as magic numbers.

## Documentation

Start with [docs/README.md](docs/README.md) and the architecture documents under `docs/`.

## Contributing

- Keep changes compatible with CI.
- Follow the coding standards in `docs/`.
- Document non-trivial architecture decisions with an ADR.
- Prefer focused branches and conventional commit messages.

## License

All rights reserved © 2026 SHIFT // ZERO. See [LICENSE](LICENSE).
