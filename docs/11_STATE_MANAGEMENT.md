# 11 — Game State Management Strategy

State in a game is more than "which screen am I on". It spans four scopes:

| Scope | Lives for | Examples |
|---|---|---|
| **Meta-state** | Forever (persisted) | high score, unlocks, entitlements, settings |
| **Session-state** | App lifetime | current locale resolved, remote config snapshot, ad SDK loaded flag |
| **Screen-state** | While a scene is loaded | which menu tab is selected, scroll position |
| **Run-state** | Duration of one gameplay run | current score, active modifiers, obstacle pool, player velocity |

Each scope has a different owner, different rules, and different lifetime.

## 1. Ownership

| Scope | Owner |
|---|---|
| Meta-state | `SaveService` (single source of truth) |
| Session-state | `App` (top-level autoload) |
| Screen-state | The scene root (`Control` or `Node`) that owns the screen |
| Run-state | `RunDirector` (top-level orchestrator of a single run) |

## 2. State Machines — where and why

We use **explicit finite state machines** at two levels:

### 2.1 App-level FSM (in `App`)

```
BOOTING → MENU → LOADING_RUN → IN_RUN → PAUSED
                                 ↓
                              GAME_OVER → MENU
                              ↳ (or) CONTINUING (post-rewarded-ad) → IN_RUN
```

Transitions are authoritative; the `SceneRouter` follows them, not the other way around.

### 2.2 Run-level FSM (in `RunDirector`)

```
INIT → COUNTDOWN → PLAYING ↔ MODIFIER_TRANSITION
                     ↓
                   DYING → DEAD → SUMMARIZED
```

Modifier transitions are a sub-state so we can freeze relevant systems (haptic burst, VFX cue) atomically.

### 2.3 Modifier FSM (per modifier instance)

```
QUEUED → ENTERING → ACTIVE → EXITING → ENDED
```

`ModifierManager` guarantees `ENTERING → ACTIVE → EXITING → ENDED` runs to completion even if the run ends early, so cleanup (unregistering listeners, restoring gravity vector, reverting shaders) always happens.

## 3. Communication Between States

- **EventBus** is the primary vehicle. Any state change publishes an event (`run/started`, `run/modifier_activated`, `entitlements/changed`).
- **No polling.** UI never asks "is the game paused?"; it subscribes to `game/pause_state_changed`.
- **No cross-scope references.** Run-state must never read directly from Meta-state; if it needs `high_score`, it asks via a small read-only API on `SaveService`.

## 4. Immutability Discipline

Meta-state is treated as **immutable snapshots**:

- Reads return a **copy** (or a read-only wrapper).
- Writes go through `SaveService.mutate(state -> new_state)`.
- No system holds a long-lived reference to a mutable meta-state object.

This eliminates a whole class of bugs (partial writes, mid-frame changes, listeners seeing torn state).

## 5. Persistence Triggers

| Trigger | What is persisted |
|---|---|
| `run/finished` | high score, run count, per-modifier stats, daily entry |
| `cosmetic/equipped` | equipped_cosmetics slot |
| `settings/changed` | settings.json |
| `entitlements/changed` | entitlements block + immediate refetch from Play |
| App pause / close | emergency flush of all dirty state |

Persistence is **debounced** where safe (settings changes coalesced within 500 ms) and **synchronous** where required (run finished, entitlement change).

## 6. Handling Interruptions

Mobile is hostile: calls, notifications, low battery, task switch, incoming ads.

- On `NOTIFICATION_APPLICATION_PAUSED` mid-run:
  - Freeze the run FSM (transition to `PAUSED`).
  - Emit `game/paused` so audio ducks, music stops.
  - Do **not** persist run-state — a paused run resumes in memory. If the OS kills us, the run is lost by design (this keeps saves small and integrity high).
- On resume:
  - Refresh Remote Config (async).
  - Re-query IAP entitlements (background).
  - Show a friendly resume overlay ("tap to continue").

## 7. Ad + IAP Integration with State

Rewarded ad "continue run" flow (see `03_ARCHITECTURE.md §6.3`) is a state transition, not a side-effect:

```
IN_RUN → GAME_OVER          (player dies)
GAME_OVER → CONTINUING       (user taps "watch to continue")
CONTINUING → IN_RUN          (on ad_reward_granted event)
CONTINUING → GAME_OVER       (on ad_error or ad_dismissed_no_reward)
```

Only one continue is allowed per run — tracked on `RunState.continues_used`.

## 8. Determinism Contract with State

- `RunDirector.init(seed, modifier_schedule)` fully determines a run.
- Any state that must be replayable is derived from the seed + input log, not sampled from real-time.
- Cosmetics affect *appearance only*, never `RunState`.

## 9. Debug Utilities

- **Time-travel state inspector** (DEV only): a dev-only overlay lists current values of App-FSM, Run-FSM, active modifiers, and last 20 EventBus messages.
- **Force transition** commands via a hidden menu.
- **State snapshot dump** — writes the current run-state to a JSON file for bug reports.

## 10. Anti-Patterns (banned)

- ❌ Global mutable variables representing game state outside the four defined scopes.
- ❌ Reaching into `Node.get_tree().current_scene` to change screens (only `SceneRouter` may).
- ❌ Storing gameplay pointers in Meta-state.
- ❌ Reading from `SaveService` inside `_process`.

## 11. State Test Plan

- Every FSM has a **transition matrix** unit test — every legal transition covered, every illegal one asserted to be rejected.
- Long-run soak test: 10 000 simulated runs → assert no state drift, no leaks, no orphan modifiers.
- Backgrounding fuzz test: pause/resume during every state → assert consistent recovery.
