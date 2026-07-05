# 10 — Save System Strategy

Save data is sacred. A single lost high-score costs us a review, a review costs us installs. This system is designed to **never** corrupt or lose the player's data.

## 1. What we save

Two logical stores, persisted separately:

### 1.1 `save.json` — the game save (progress + entitlements)
- `schema_version` (int, monotonically increasing)
- `player_id` (locally generated UUID; migrated to GPGS ID if signed in later)
- `stats`:
  - `high_score`, `total_runs`, `total_distance`, `total_time_s`
  - `deaths_by_modifier: {modifier_id: count}`
  - `best_score_by_modifier`, `longest_streak`
- `progression`:
  - `unlocked_cosmetics: [id]`
  - `equipped_cosmetics: {slot: id}`
  - `daily_history: [{date_utc, score}]`
  - `achievements_unlocked: [id]`
- `entitlements`:
  - `remove_ads: bool`
  - `owned_bundles: [id]`
- `consent`:
  - `analytics: bool`, `personalized_ads: bool`, `crashlytics: bool`
- `flags`:
  - `has_seen_tutorial`, `has_rated`, `has_seen_privacy_v2` …
- `metadata`:
  - `created_at`, `updated_at`, `client_version`, `engine_version`, `platform`

### 1.2 `settings.json` — user preferences (audio, haptics, language)
Kept separate because it should survive save-corruption of the game save.

## 2. Where we save

| Platform | Location |
|---|---|
| Android | `user://` (Godot) → resolves to `/data/data/<pkg>/files/` (private, backed up by Android auto-backup opt-in) |
| Web | `localStorage` (via Godot HTML5 wrapper) with size guard |
| Desktop (browser) | `localStorage` |
| iOS (future) | `user://` → app sandbox |

Cloud (v1.1): **Google Play Games Services Snapshots** for `save.json` only. `settings.json` is device-local.

## 3. File Layout on Disk

```
user://
├── save.json                # primary
├── save.backup.json         # last-known-good backup
├── save.staging.json        # scratch file used during atomic writes
├── save.emergency.json      # snapshot written on crash guard
├── settings.json
├── telemetry_queue.json     # offline analytics events waiting to upload
└── logs/
    ├── current.log
    └── previous.log
```

## 4. Write Protocol — atomic + double-buffered

Every mutation goes through `SaveService.mutate(mutator: Callable) -> Result`:

```
1. Load current in-memory state (already validated).
2. Apply mutator (pure function -> new state).
3. Serialize new state to JSON.
4. Compute SHA-256 checksum, embed into an envelope:
     { "checksum": "...", "payload": <state_json> }
5. Write envelope to save.staging.json  (fsync).
6. Rename save.staging.json  ->  save.primary.tmp  (atomic on POSIX/Android).
7. Rename save.primary.tmp   ->  save.json         (atomic).
8. Every N successful writes (default 5), copy save.json -> save.backup.json.
9. Emit  "save/persisted"  on EventBus.
```

If any step fails: we log, revert in-memory to the previous validated state, and surface a `Result.err`.

## 5. Read Protocol

```
1. Read save.json.
2. Parse JSON, verify checksum.
3. If OK: run migrations if schema_version < CURRENT.
4. If corrupt or missing: read save.backup.json, verify.
5. If backup corrupt: read save.emergency.json.
6. If all three fail: initialize a fresh save with all defaults, tag telemetry event "save/recovered_fresh".
```

Every recovery path is telemetered so we can catch a regression fast.

## 6. Emergency Save

- On `NOTIFICATION_WM_CLOSE_REQUEST` (Android/desktop close) and `NOTIFICATION_APPLICATION_PAUSED` (Android background): synchronously flush.
- On uncaught error / crash guard: dump current state to `save.emergency.json` before propagating.

## 7. Migrations

- Every `schema_version` change ships with a `MigrationN_to_N+1` function in `core/migrations.gd`.
- Migrations run in a strict chain. A v1.0 user going to v1.5 runs 1→2→3→4→5.
- **Never delete a field** without a migration; deprecate first, then remove in a version whose min-supported-from is above the deprecation window.
- Every migration is unit-tested with fixtures in `tests/unit/save/fixtures/`.
- If a migration fails: the save is **preserved untouched**, backup is used, and the user is asked (soft prompt) to send a diagnostic report.

## 8. Cloud Sync (v1.1, GPGS Snapshots)

- Sync unit: entire `save.json`.
- Conflict resolution: `deterministic merge`:
  - `high_score`, `total_*`, `best_score_by_modifier` → **max**
  - `unlocked_cosmetics`, `achievements_unlocked` → **union**
  - `equipped_cosmetics` → **most recent by `updated_at`**
  - `entitlements` → **union of `true`** (once unlocked, always unlocked)
  - `daily_history` → **union**, dedupe by `date_utc`
- Debounced upload: 5 s after last mutation, or on app pause.
- Download at boot (if signed in) → merge → notify user only if a meaningful change occurred.

## 9. Anti-Tamper (light)

Since v1.0 is offline and no leaderboards are server-authoritative, we only:
- Obfuscate the JSON with a light xor-key (deterrent against curious users).
- Keep the checksum inside the envelope.
- Server-side leaderboards (v1.2) will require **HMAC-signed score submissions** derived from a per-install key + run seed + replay hash. Client-only trust is never granted.

## 10. Backups & Restore

- Android **Auto Backup** is enabled for `user://` via `allowBackup=true` in the manifest — the OS handles backup to the user's Google Drive.
- `Settings → Data → Restore backup` exposes a manual "load from backup slot" for support cases.

## 11. Save Size Envelope

- Target: ≤ **50 KB** per save.json.
- Hard cap: 250 KB. Beyond this we compress the payload (gzip) inside the envelope.
- `daily_history` capped to last 90 entries; older entries are aggregated into monthly totals.

## 12. Testing Strategy

- Round-trip tests: write → read → equality.
- Corruption tests: fuzz random bytes into `save.json`; assert recovery succeeds and player is not punished.
- Migration chain tests: apply every possible from-version to CURRENT.
- Concurrent-writer tests: two mutate calls in the same frame → serialized correctly, no lost updates.
- Cloud conflict tests: matrix of local × remote states → assert deterministic merged result.

## 13. Public API (sketch, will formalize in TDD §5.1)

```gdscript
class_name ISaveService

func load() -> Result             # returns Result<SaveState>
func save(state: SaveState) -> Result
func mutate(mutator: Callable) -> Result
func reset_all(confirm_token: String) -> Result   # destructive, needs a token
func export_to_string() -> String     # for support debugging
func import_from_string(data: String) -> Result   # gated in dev
```

Public via `ServiceLocator.get(ISaveService)`; never accessed directly by gameplay.
