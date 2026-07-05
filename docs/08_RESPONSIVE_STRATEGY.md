# 08 — Responsive Design Strategy

Goal: SHIFT // ZERO must feel **native** on every screen it lands on — from a 5.5″ budget phone in portrait to a 27″ desktop monitor and every foldable/tablet in between — without duplicating the UI.

## 1. Target Device Buckets

| Bucket | Examples | Aspect | Base UI reference |
|---|---|---|---|
| **P-Small** | 5.5″ HD phone (720×1600) | 9:20 portrait | 720 dp × 1600 dp |
| **P-Std** | 6.1″ FHD phone (1080×2400) | 9:20 portrait | 1080 dp × 2400 dp (design baseline) |
| **P-Tall** | 6.7″ FHD+ (1080×2640) | 9:22 portrait | scale |
| **Foldable-Inner** | Fold5 unfolded (1812×2176) | ~5:6 | tablet-class layout |
| **Foldable-Outer** | Fold5 cover (904×2316) | very tall | portrait phone layout |
| **Flip-Inner** | Flip5 (1080×2640) | phone-class | portrait phone layout |
| **Tablet** | 10.1″ (1600×2560) | 5:8 or 4:5 | tablet layout |
| **Chromebook / Desktop** | 1920×1080+, landscape | 16:9 → 21:9 | desktop layout |
| **Ultra-wide** | 3440×1440 | 21:9 | desktop layout with letterboxing on gameplay only |

## 2. Design Baseline & Units

- **Design baseline:** 1080×2400 dp, portrait.
- **Unit:** `dp` (density-independent). All layout uses Godot's `content_scale_mode = "canvas_items"` + `content_scale_aspect = "expand"`.
- **Safe area:** we honour `DisplayServer.get_display_safe_area()` on Android for notches, cutouts, and edge-to-edge gestures. All critical UI stays inside a **48 dp** inset from screen edges.
- **Thumb reach zone:** for portrait phones, primary interactive buttons live in the **bottom 40%** of the screen (right thumb + left thumb friendly). Nothing critical in the top 15%.

## 3. Layout Modes

Three layout modes; the UI Kit picks one per breakpoint.

### 3.1 `phone_portrait` (P-Small, P-Std, P-Tall, Foldable-Outer, Flip-Inner)

- HUD score anchored top-center; modifier icon top-left; pause top-right.
- Menus: full-screen, stacked list.
- Cosmetics: single-column grid with horizontal snap.

### 3.2 `tablet` (Foldable-Inner, Tablet)

- HUD stretches with **wider gutters** — never re-anchor gameplay elements to keep muscle-memory consistent with phone.
- Menus: two-column layouts (nav on left, content on right).
- Cosmetics: 3–4 column grid.

### 3.3 `desktop` (Chromebook, Desktop browsers, ultra-wide)

- Gameplay canvas is **letterboxed to the target aspect** (default 9:16 vertical or 16:9 horizontal — decided in GDD §6.1). The letterbox is filled with neon ambient art, not black bars.
- Menus: three-column layouts allowed. Larger padding.
- Full keyboard/mouse/gamepad support. Cursor hides during gameplay.

## 4. Breakpoints

Chosen at logical widths (dp):

| Breakpoint | Range (min dp) | Layout mode |
|---|---|---|
| xs | 0 | phone_portrait |
| md | 720 | tablet |
| lg | 1200 | desktop |
| xl | 1800 | desktop (wider gutters) |

Breakpoint is chosen at boot and on every OS window / configuration change (foldable posture change is a config change → we re-layout).

## 5. Godot Configuration

```
[display]
window/size/viewport_width = 1080
window/size/viewport_height = 2400
window/stretch/mode = "canvas_items"
window/stretch/aspect = "expand"
window/handheld/orientation = "sensor"   # allow rotation; runtime chooses
window/subwindows/embed_subwindows = true
```

- Cameras use **`Camera2D` with `anchor_mode = fixed_top_left`** in gameplay + a **screen-space UI CanvasLayer** on top.
- HUD `Control` nodes use anchor presets, never absolute positions.

## 6. Orientation Rules

- Default: **Portrait**. Best fit for one-thumb play on phones.
- Optional Landscape: toggle in Settings. On tablets and desktops, landscape is the default.
- On foldables: unfolding into tablet-class posture triggers automatic switch to tablet layout mode; folding back returns to phone_portrait.

## 7. Input Adaptation

| Device | Primary input | Secondary |
|---|---|---|
| Phone / Tablet | Touch (tap, hold) | — |
| Foldable | Touch | Stylus is treated as touch |
| Chromebook | Touch, mouse, keyboard | Gamepad |
| Desktop | Mouse (LMB), keyboard (Space) | Gamepad |

- **Input mappings are unified through `InputSystem`** — gameplay only sees `TAP`, `HOLD`, `RELEASE` events, never raw device events.
- Keyboard mapping: `Space` = tap, `Esc` = pause, `M` = mute.
- Gamepad mapping: `A` = tap, `Start` = pause.

## 8. Fonts

- One display font (branding/menus) + one legible sans (HUD/body).
- All fonts declare fallback for CJK + Cyrillic + Devanagari; we don't ship a single font for all — we ship a font family per script chosen by locale.
- Minimum readable body size: **14 sp** on phones, **16 sp** on tablets, **14 sp equivalent** on desktop (bumped visually since the viewport is larger).

## 9. Assets & DPI

- Sprites shipped at **@2x** of the design baseline.
- Vector assets (menus, icons) are SVG imported to Godot as SVG → rasterized at scene load per DPI. This keeps them razor-sharp on tablets and desktop.
- Backgrounds authored **wider than needed** so tablets/desktops never see edges.

## 10. Foldable Handling

- Listen to `NOTIFICATION_APPLICATION_RESUMED` and `DisplayServer.screen_get_size()` deltas → re-run layout selection.
- On posture change during a run: gameplay is auto-paused with a friendly toast ("posture changed — resuming safely…") to prevent unfair deaths.

## 11. Web Build Specifics

- Canvas resizes to fit container; parent HTML page provides letterboxing background using CSS `background: radial-gradient(...)` matching the in-game palette.
- Prevent right-click context menu on the canvas.
- Provide a **"Add to Home Screen"** PWA manifest for Android Chrome users who prefer the web build.
- Handle browser resize/rotate via `window.onresize` → Godot `_notification(NOTIFICATION_WM_SIZE_CHANGED)`.

## 12. Testing Matrix

Every UI PR must pass a screenshot diff test on the following viewports (headless Godot):

- 720×1600 (P-Small)
- 1080×2400 (P-Std, baseline)
- 1080×2640 (P-Tall)
- 1600×2560 (Tablet portrait)
- 2560×1600 (Tablet landscape)
- 1920×1080 (Desktop 16:9)
- 3440×1440 (Ultra-wide)
- Fold5 unfolded: 1812×2176
- Fold5 cover: 904×2316

Screenshots are diffed against golden references with a 1% tolerance.
