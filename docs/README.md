# SHIFT // ZERO — Design & Architecture Package

> Commercial indie 2D one-finger gravity-shift action game.
> Mobile-first (Android), fully responsive on tablets, foldables, Chromebooks and desktop web.

This directory contains the **complete pre-production package** for SHIFT // ZERO.
No gameplay code is written yet — this is the blueprint that gameplay will be built on.

## Document Index

| # | Document | Purpose |
|---|----------|---------|
| 00 | [Executive Summary](./00_EXECUTIVE_SUMMARY.md) | 1-page overview of the entire plan |
| 01 | [Requirements Analysis](./01_REQUIREMENTS_ANALYSIS.md) | Functional + non-functional requirements, constraints, KPIs |
| 02 | [Technology Stack](./02_TECH_STACK.md) | Engine comparison (Unity vs Godot 4 vs Flutter+Flame vs Phaser) + full stack recommendation |
| 03 | [System Architecture](./03_ARCHITECTURE.md) | Layered architecture, module boundaries, data flow diagrams |
| 04 | [Folder Structure](./04_FOLDER_STRUCTURE.md) | Production-ready project layout |
| 05 | [Game Design Document (GDD) — Skeleton](./05_GDD_TEMPLATE.md) | Section structure only, ready to be filled |
| 06 | [Technical Design Document (TDD) — Skeleton](./06_TDD_TEMPLATE.md) | Engineering counterpart to the GDD |
| 07 | [Coding Standards & Naming Conventions](./07_CODING_STANDARDS.md) | Enforceable rules for the codebase |
| 08 | [Responsive Design Strategy](./08_RESPONSIVE_STRATEGY.md) | Phone → tablet → foldable → desktop scaling |
| 09 | [Performance Optimization Strategy](./09_PERFORMANCE_STRATEGY.md) | 60 FPS budget, memory, GC, draw calls |
| 10 | [Save System Strategy](./10_SAVE_SYSTEM.md) | Local, migrate-safe, cloud-sync ready |
| 11 | [Game State Management](./11_STATE_MANAGEMENT.md) | Meta-state, run-state, session-state, FSM |
| 12 | [Asset Management](./12_ASSET_MANAGEMENT.md) | Import pipeline, atlases, loading, versioned bundles |
| 13 | [Versioning Strategy](./13_VERSIONING_STRATEGY.md) | SemVer, save migrations, live updates, Play Store tracks |
| 14 | [Development Roadmap](./14_ROADMAP.md) | M0 → M6 milestones with exit criteria |

## Approval Gate

Per your instructions, **no implementation work will begin** until this package is reviewed and approved.

When you're ready, reply with one of:
- ✅ **"Approved — start M0"** to begin engine bootstrap
- 🔁 **"Revise <doc # / section>"** to iterate on specific parts
- ❓ **"Explain <topic>"** for a deeper dive on any decision
