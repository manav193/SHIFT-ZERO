## PlayerController
##
## Core movement system for SHIFT // ZERO.
##
## Contract (M1.1 scope):
##   - Vertical-only physics (X velocity forced to 0).
##   - A single INPUT_TAP flips gravity between floor (+Y) and ceiling (-Y).
##   - Gravity magnitude, terminal velocity and flip cooldown come from
##     GameplayConfig (data-driven, live-tunable via Remote Config).
##   - No horizontal auto-run yet — arrives in M1.2 with a scrolling world.
##
## Architecture:
##   - Never reads Godot Input directly; subscribes to EventBus INPUT_TAP.
##   - Refreshes tunables when Remote Config activates.
##   - Emits `gravity_flipped` for future subsystems (VFX, haptics, SFX)
##     without coupling this controller to them.
class_name PlayerController
extends CharacterBody2D

const Events := preload("res://src/core/events.gd")
const GameplayConfig := preload("res://src/gameplay/gameplay_config.gd")

## Emitted immediately after the gravity direction changes.
signal gravity_flipped(new_direction: int)

## +1 → gravity pulls DOWN (player falls toward floor).
## -1 → gravity pulls UP   (player rises toward ceiling).
var _gravity_dir: int = 1

## Timestamp (ms) of the last accepted flip — used to enforce cooldown.
var _last_flip_ms: int = -100000

# Cached tunables, refreshed on _ready and whenever Remote Config activates.
var _gravity_magnitude: float = 1600.0
var _terminal_velocity: float = 1800.0
var _flip_cooldown_ms: int = 80
var _run_speed: float = 420.0

## True while the run is active. Flipped to false when RUN_FINISHED fires,
## which freezes physics + input handling.
var _alive: bool = true


func _ready() -> void:
    _reload_tunables()
    add_to_group("player")
    EventBus.subscribe(Events.INPUT_TAP, _on_input_tap)
    EventBus.subscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    Logger.debug("Player", "ready. dir=%d g=%.1f v_term=%.1f cd=%dms run=%.1f" % [
        _gravity_dir, _gravity_magnitude, _terminal_velocity, _flip_cooldown_ms, _run_speed,
    ])


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.INPUT_TAP, _on_input_tap)
    EventBus.unsubscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    EventBus.unsubscribe(Events.RUN_FINISHED, _on_run_finished)


func _physics_process(delta: float) -> void:
    if not _alive:
        return
    velocity.y += float(_gravity_dir) * _gravity_magnitude * delta
    velocity.y = clampf(velocity.y, -_terminal_velocity, _terminal_velocity)
    velocity.x = _run_speed
    move_and_slide()


## Public API — allows tests + future modifiers to inspect / set direction.
func gravity_direction() -> int:
    return _gravity_dir


func set_gravity_direction(dir: int) -> void:
    var normalized := 1 if dir >= 0 else -1
    if normalized == _gravity_dir:
        return
    _gravity_dir = normalized
    # Reset vertical velocity on flip for a snappy, predictable feel.
    # A momentum-preserving variant can be introduced later via GameplayConfig.
    velocity.y = 0.0
    gravity_flipped.emit(_gravity_dir)
    Logger.trace("Player", "gravity flipped -> %d" % _gravity_dir)


func _on_input_tap(_payload: Dictionary) -> void:
    if not _alive:
        return
    var now := Time.get_ticks_msec()
    if now - _last_flip_ms < _flip_cooldown_ms:
        return
    _last_flip_ms = now
    set_gravity_direction(-_gravity_dir)


func _on_remote_config_activated(_payload: Dictionary) -> void:
    _reload_tunables()


func _on_run_finished(payload: Dictionary) -> void:
    if not _alive:
        return
    _alive = false
    velocity = Vector2.ZERO
    Logger.info("Player", "run ended: %s" % payload)


func _reload_tunables() -> void:
    _gravity_magnitude = GameplayConfig.get_float("gravity_magnitude")
    _terminal_velocity = GameplayConfig.get_float("terminal_velocity")
    _flip_cooldown_ms = GameplayConfig.get_int("tap_flip_cooldown_ms")
    _run_speed = GameplayConfig.get_float("player_base_speed")
