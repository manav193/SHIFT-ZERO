# 13 — Versioning Strategy

Long-term update-ability is only possible if versioning is a discipline, not an afterthought. This doc defines how we version code, saves, assets, config, and releases.

## 1. SemVer (game version)

We follow **Semantic Versioning 2.0**: `MAJOR.MINOR.PATCH[-preRelease][+build]`.

| Change | Bumps |
|---|---|
| Save-breaking change without a migration | **MAJOR** (never intentionally shipped; see §5) |
| New feature, new content, new modifier | **MINOR** |
| Bug fix, balance tweak, perf improvement | **PATCH** |
| Internal / dev / QA build | pre-release tag: `1.2.0-beta.3` |
| Same code, new build | build metadata: `+ci.842` |

`versionCode` (Android integer): monotonically increasing, computed as `MAJOR*10000 + MINOR*100 + PATCH`. Beta/RC/patch iterations increment by 1 within the same triple.

### Examples
- `1.0.0` — Global launch.
- `1.0.1` — Hotfix crash on Redmi 9.
- `1.1.0` — Adds GPGS integration + 3 new modifiers.
- `1.2.0-beta.1` — Beta of the seasonal event build.
- `2.0.0` — Major redesign / new game mode.

## 2. Where the version lives

Single source of truth: `game/data/config/game_version.tres`.
- `major`, `minor`, `patch`, `pre_release`, `build`
- Loaded at boot, exposed via `Config.version`.
- `versionCode` and `versionName` in the Android manifest are **generated** from this file by `scripts/build_android.sh`. Never hand-edited.
- HTML5 build embeds it in `index.html` and shows it in the Settings/About screen.

## 3. Save schema versioning (see also `10_SAVE_SYSTEM.md §7`)

- `save.json.schema_version` starts at **1** and bumps whenever any persisted field's shape changes.
- Save-schema version is **independent** of the game SemVer.
  - A patch release can bump save schema (e.g. fixing a stored typo).
  - Most minor releases do not bump save schema.
- **Migrations are mandatory** for every schema change. See `10_SAVE_SYSTEM.md §7`.
- Migration tests must exist from `1 → CURRENT` on every PR that bumps schema.

## 4. Asset & content versioning

- Content packs (biomes, cosmetic bundles) each declare a `content_version` in their `.tres`.
- When a piece of content is meaningfully changed, its version bumps.
- Old versions of a cosmetic are honoured — a player who owns "Neon Circuit v1" keeps it even if we ship "Neon Circuit v2".

## 5. Backward compatibility policy

- **A v1.0.0 user must be able to install any v1.x update and keep their data.** This is non-negotiable.
- No breaking change ships in a MINOR or PATCH release, ever.
- A MAJOR release (2.0.0) is allowed to change save schema in ways minor releases can't — but even then we ship migrations. We never wipe saves.
- Feature flags cover **behavioral** changes we may need to roll back.

## 6. Feature flags

- Managed by `FeatureFlagService`.
- Precedence: **local override (dev build only) → Firebase Remote Config → build-time default**.
- Naming: `flag_<domain>_<verb>` — e.g. `flag_modifier_portals_enabled`.
- Every flag has a **default = safe**. If Remote Config is unavailable, the game plays fine.
- Flags are documented in `docs/flags.md` with owner, purpose, default, rollout plan, and sunset date.
- Flags that outlive 2 minor versions must be removed or promoted to permanent config.

## 7. Release Tracks (Google Play Console)

| Track | Purpose | Audience |
|---|---|---|
| **Internal testing** | daily builds, no review | team (≤ 100 testers) |
| **Closed testing (Alpha)** | feature-complete builds | invited testers, opt-in list |
| **Closed testing (Beta)** | RC candidates | public opt-in with email list |
| **Open testing** | pre-launch soak | anyone via Play Store link |
| **Production** | 1% → 5% → 20% → 50% → 100% staged rollout | all users |

Every production release starts at **1%** for 24 h. We watch:
- crash-free session rate
- ANR rate
- D0 retention
- ad-fill rate

Any regression → pause rollout.

## 8. Web release

- Two channels: `web-canary` (nightly) and `web-stable` (matches Play production).
- Deployed via GitHub Actions to Cloudflare Pages / itch.io.
- Cache-busted with content hashes in filenames.
- Rollback = redeploy the previous artifact (kept for 90 days).

## 9. Hotfix Protocol

- Hotfix branches: `hotfix/1.0.x-<slug>` off the last production tag.
- Only critical fixes: crash, ANR, save-corruption, monetization outage, store-policy violation.
- Bumps PATCH.
- Same 1% staged rollout unless it's a fix *for* the current rollout.

## 10. Deprecation Policy

- Deprecating a field/API/asset: mark deprecated + emit a warning in DEV + log telemetry in RELEASE.
- Removal only permitted **two minor versions later**.
- E.g. deprecated in 1.3 → may be removed in 1.5.

## 11. Change Log

- `CHANGELOG.md` at repo root, following Keep-a-Changelog format.
- User-facing summary published to Play Console release notes + web site.
- Internal detailed release notes in `docs/releases/<version>.md`.

## 12. Version Display

- Settings → About shows: `1.2.3 (build 12345)`.
- DEV builds show version + git short SHA in the corner of every screen.
- Long-press on the version reveals: build channel, config source (remote vs default), feature flag summary, and a "copy diagnostic" button.

## 13. Governance

- Only two people are permitted to publish to production: a **Release Owner** and a **Backup Release Owner**.
- Every production release requires a completed checklist in `docs/releases/checklist.md`:
  - CI green (lint + tests + perf gate)
  - QA sign-off on device matrix
  - Release notes reviewed
  - Rollout percentage set
  - Rollback plan documented
  - Store listing screenshots up-to-date if UI changed
