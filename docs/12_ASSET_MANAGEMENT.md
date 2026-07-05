# 12 — Asset Management Strategy

Assets are 80% of a mobile game's download size, load time, and memory footprint. We treat them as a **first-class engineered pipeline**, not "just files".

## 1. Asset Categories

| Category | Format(s) | Import target |
|---|---|---|
| Character / obstacle sprites | PNG (source), Aseprite (source-of-truth) | ASTC 4×4 on Android, WebP on Web, packed atlases |
| UI (icons, buttons) | SVG (preferred), PNG | SVG rasterized at scene load; icons in a single UI atlas |
| Backgrounds / parallax | PNG or JPG | ETC2/ASTC on Android; JPG on Web where alpha not needed |
| Fonts | TTF / OTF, subsetted per locale | DynamicFont with per-script fallback family |
| Shaders | `.gdshader` | source-only |
| Music | OGG Vorbis (source) | streamed |
| SFX | OGG Vorbis, short (< 200 KB) | loaded to memory, pooled |
| Data | `.tres`, `.json`, `.csv` | text, versioned in Git |
| Video (cutscenes, if any) | WebM VP9 | streamed |

## 2. Source-of-truth Layout

Under `game/assets/raw/` we keep source files (`.aseprite`, `.psd`, `.wav`, `.reaper`) which are excluded from Godot import and from exports:

```
game/assets/raw/
├── aseprite/
├── figma/exports/
├── audio/wav/
└── reaper/
```

Baked, engine-ready files live under `game/assets/{sprites,audio,shaders,fonts}/`.

## 3. Atlasing Pipeline

- **Every non-trivial sprite lives inside an atlas** — no orphaned PNG loose in an export.
- Atlases are built by `game/tools/atlas_builder.gd` running headless as part of a pre-commit / CI step:
  - **UI atlas** — all icons, buttons, badges. Single texture.
  - **Character atlas** — the player + trails.
  - **Obstacle atlas per biome** — small enough to swap on biome transition.
- Naming: `atlas_ui.png` + `atlas_ui.tres` (Godot `AtlasTexture` list).
- Padding: 4 px around each sprite.
- Max atlas size: 2048×2048 (safe for T-Low GPUs).

## 4. Import Presets

Godot import presets are checked in (`.godot/imported/`) and controlled through per-folder `.import` files:

| Asset kind | Compression | Filter | Mipmaps |
|---|---|---|---|
| UI sprites | Lossless PNG | Off (pixel-perfect) | No |
| Character/obstacle sprites | Lossy (ASTC / WebP) | On (linear) | Yes |
| Backgrounds | Lossy | On | Yes |
| SFX | Uncompressed WAV *in editor*, OGG in export | — | — |
| Music | Streamed OGG | — | — |

CI check ensures no PR introduces an asset with a mismatched preset for its folder.

## 5. Resource Registry Pattern

Data-driven content (modifiers, cosmetics, biomes, obstacle patterns) is registered via a **registry `.tres`**, not by hardcoded paths:

```
data/modifiers/registry.tres  → [ res://data/modifiers/gravity_flip.tres, ... ]
data/cosmetics/registry.tres
data/biomes/registry.tres
data/obstacles/patterns_normal.tres
```

Registries are loaded once at boot, cached, and exposed via `ContentService.get_modifier(id)`. Adding content = adding a `.tres` + editing the registry.

## 6. Loading Strategy

### 6.1 Boot-time (blocking)

- UI atlas
- Default font family
- App configuration + registries (metadata only, not the referenced heavy assets)
- Palette resources
- Loading screen assets

### 6.2 Menu-idle (background, non-blocking)

- Character atlas
- First biome's obstacle atlas
- Music intro track
- Common SFX bank

### 6.3 Just-in-time (on demand)

- Additional biomes when they are near-selected
- Cosmetic previews when the cosmetics screen opens
- Ad SDK assets (handled by AdMob)

### 6.4 Never-load-again

- Once a biome is loaded during a session it stays cached until memory pressure requires eviction (LRU) or until app pause.

## 7. Play Asset Delivery (Android)

We ship a small base AAB (≤ 40 MB) and offload heavy content via **Play Asset Delivery**:

| Pack | Delivery mode | Contents |
|---|---|---|
| `install_time` | with base | code, core atlases, one biome, default cosmetics |
| `on_demand` | fetched when unlocked | additional biomes, premium cosmetic bundles |
| `fast_follow` | prefetched after install | extra languages, high-DPI variants |

Language-specific fonts and translations are DPI/lang-sliced via bundled AAB modules so users only download what they need.

## 8. Memory Management

- Textures unloaded on scene exit if not referenced elsewhere.
- `ResourceLoader.load_threaded_request(...)` for large assets to keep the main thread free.
- Peak texture memory sampled every 5 s in DEV; asserts against tier budget (see `09_PERFORMANCE_STRATEGY.md §3`).
- On low-memory OS callback: evict LRU biome atlases, drop optional cosmetic previews.

## 9. Naming Conventions

- Sprites: `<subject>_<state>_<direction>.png` — e.g. `player_idle.png`, `obstacle_spike_up.png`.
- UI icons: `ui_<function>.svg` — `ui_pause.svg`, `ui_ad_reward.svg`.
- Atlases: `atlas_<domain>.png` + matching `.tres`.
- SFX: `sfx_<domain>_<action>.ogg` — `sfx_player_flip.ogg`, `sfx_modifier_activate.ogg`.
- Music: `music_<biome>_<mood>.ogg` — `music_neon_calm.ogg`.
- Shaders: `<effect>.gdshader` — `neon_glow.gdshader`.
- Data resources: `<type>_<id>.tres` — `modifier_gravity_flip.tres`.

## 10. Localization Assets

- One `translations.csv` at `game/assets/i18n/translations.csv`.
- Columns: `key`, `en`, `es`, `pt-BR`, `fr`, `de`, `ru`, `ja`, `ko`, `zh-Hans`, `hi`.
- Font family per script defined in `data/config/font_families.tres`.
- Missing keys fall back to English + are logged to telemetry.

## 11. Versioning of Assets

- Assets follow the game's SemVer (see `13_VERSIONING_STRATEGY.md`).
- Renaming an asset requires updating all references atomically (grep + registry regeneration).
- Old assets are removed only after two versions of deprecation.

## 12. Legal & Attribution

- Every third-party asset (fonts, SFX libraries, textures) is logged in `docs/legal/asset_attributions.md` with license + source URL.
- No asset ships without a documented license.
- We never ship royalty-encumbered assets.

## 13. Tools

- **Aseprite** for sprite work (native slice export to Godot).
- **Figma** for UI (SVG export pipeline).
- **Reaper / Ableton** for audio.
- **TexturePacker** (optional) if we outgrow the built-in atlas builder.
- **ImageMagick** in CI for pre-flight size + dimension checks.
- Custom Godot editor plugin `tools/asset_lint.gd` — runs on save, flags oversized/misnamed assets.

## 14. Asset CI Checks

- Max sprite dimension ≤ 2048.
- Max PNG file size (before atlasing) ≤ 512 KB.
- All PNGs must have alpha appropriately used (no fully-opaque images with alpha channel that could be JPG).
- SFX ≤ 200 KB; music tracks ≤ 3.5 MB (streamed).
- Total baked asset size per platform, tracked and printed on every build.
