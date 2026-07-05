# Changelog

All notable changes to SHIFT // ZERO will be documented in this file.
This project follows [Semantic Versioning](https://semver.org/) 2.0.0
and [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- **M0 Foundation** — repository scaffold, docs, CI, coding standards, layer-dependency guard.
- Godot 4 project bootstrap under `game/`.
- Autoloads: Logger, Config, ServiceLocator, EventBus, SceneRouter, App.
- Core layer: `Result<T>`, seeded `RNG` with named streams, `TimeSource`.
- Service interfaces + mock implementations: Save, Settings, Ads, Billing, Analytics, RemoteConfig, Localization, FeatureFlags.
- `IInputRecorder` no-op stub — ghost-runs architectural seam (implementation deferred to v1.1).
- `GameplayConfig` data-driven value wrapper with three-layer lookup (RemoteConfig → tres defaults → hardcoded fallback).
- Accessibility settings schema (color palette, visual effects level, haptics, audio buses).
- Full design + architecture documentation set under `docs/`.
- GitHub Actions: `ci.yml` (lint + tests + layer-deps + perf smoke).
