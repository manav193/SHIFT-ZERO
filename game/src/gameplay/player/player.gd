## PlayerController
##
## Core movement system for SHIFT // ZERO.
##
## Contract:
##   - X velocity forced to run speed * difficulty * modifier multipliers.
##   - INPUT_TAP flips gravity between floor (+Y) and ceiling (-Y).
##   - Gravity magnitude, terminal velocity and flip cooldown come from
##     GameplayConfig (data-driven, live-tunable via Remote Config).
##   - Modifiers alter `_gravity_mult` and `_speed_mult` at runtime.
##   - Emits PLAYER_GRAVITY_FLIPPED and PLAYER_LANDED on the EventBus so
##     VFX / SFX / haptics stay decoupled.
##
## Layer: gameplay.
class_name PlayerController
extends CharacterBody2D

const Events := preload("res://src/core/events.gd")
const GameplayConfig := preload("res://src/gameplay/gameplay_config.gd")

@export var difficulty: NodePath

## +1 -> gravity pulls DOWN. -1 -> gravity pulls UP.
var _gravity_dir: int = 1
var _difficulty: Node

## Timestamp (ms) of the last accepted flip -- used to enforce cooldown.
var _last_flip_ms: int = -100000

# Cached tunables, refreshed on _ready and whenever Remote Config activates.
var _gravity_magnitude: float = 1600.0
var _terminal_velocity: float = 1800.0
var _flip_cooldown_ms: int = 80
var _run_speed: float = 420.0

# Runtime modifier multipliers. 1.0 = no effect.
var _gravity_mult: float = 1.0
var _speed_mult: float = 1.0

## True while the run is RUNNING. Toggled by RUN_STARTED and RUN_FINISHED.
var _active: bool = false

## Was the player on the floor/ceiling last frame? Used for landing detection.
var _was_on_surface: bool = false


func _ready() -> void:
    _reload_tunables()
    _resolve_difficulty()
    add_to_group("player")
    EventBus.subscribe(Events.INPUT_TAP, _on_input_tap)
    EventBus.subscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    EventBus.subscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.subscribe(Events.MODIFIER_ACTIVATED, _on_modifier_activated)
    EventBus.subscribe(Events.MODIFIER_EXPIRED, _on_modifier_expired)
    print("Player", "ready. dir=%d g=%.1f v_term=%.1f cd=%dms run=%.1f" % [
        _gravity_dir, _gravity_magnitude, _terminal_velocity, _flip_cooldown_ms, _run_speed,
    ])


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.INPUT_TAP, _on_input_tap)
    EventBus.unsubscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    EventBus.unsubscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.unsubscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.unsubscribe(Events.MODIFIER_ACTIVATED, _on_modifier_activated)
    EventBus.unsubscribe(Events.MODIFIER_EXPIRED, _on_modifier_expired)


func _physics_process(delta: float) -> void:
    if not _active:
        return
    velocity.y += float(_gravity_dir) * _gravity_magnitude * _gravity_mult * delta
    velocity.y = clampf(velocity.y, -_terminal_velocity, _terminal_velocity)
    velocity.x = _run_speed * speed_multiplier()
    move_and_slide()
    _detect_landing()


## Public API -- allows tests + modifiers to inspect / set direction.
func gravity_direction() -> int:
    return _gravity_dir


func set_gravity_direction(dir: int) -> void:
    var normalized := 1 if dir >= 0 else -1
    if normalized == _gravity_dir:
        return
    _gravity_dir = normalized
    # Reset vertical velocity on flip for a snappy, predictable feel.
    velocity.y = 0.0
    EventBus.emit(Events.PLAYER_GRAVITY_FLIPPED, {
        "dir": _gravity_dir,
        "position": position,
        "t_ms": Time.get_ticks_msec(),
    })
    print("Player", "gravity flipped -> %d" % _gravity_dir)


func speed_multiplier() -> float:
    return _speed_mult * _difficulty_speed_multiplier()


func gravity_multiplier() -> float:
    return _gravity_mult


func _detect_landing() -> void:
    var on_surface: bool = is_on_floor() or is_on_ceiling()
    if on_surface and not _was_on_surface:
        EventBus.emit(Events.PLAYER_LANDED, {
            "position": position,
            "surface": "ceiling" if is_on_ceiling() else "floor",
            "t_ms": Time.get_ticks_msec(),
        })
    _was_on_surface = on_surface


func _on_input_tap(_payload: Dictionary) -> void:
    if not _active:
        return
    var now := Time.get_ticks_msec()
    if now - _last_flip_ms < _flip_cooldown_ms:
        return
    _last_flip_ms = now
    set_gravity_direction(-_gravity_dir)


func _on_remote_config_activated(_payload: Dictionary) -> void:
    _reload_tunables()


func _on_run_started(_payload: Dictionary) -> void:
    _active = true
    _gravity_mult = 1.0
    _speed_mult = 1.0
    print("Player", "activated")


func _on_run_finished(payload: Dictionary) -> void:
    if not _active:
        return
    _active = false
    velocity = Vector2.ZERO
    print("Player", "run ended: %s" % payload)


func _on_modifier_activated(payload: Dictionary) -> void:
    var id: String = str(payload.get("id", ""))
    var params: Dictionary = payload.get("params", {})
    match id:
        "low_gravity":
            _gravity_mult = float(params.get("gravity_scale", 0.5))
        "speed_burst":
            _speed_mult = float(params.get("speed_scale", 1.5))


func _on_modifier_expired(payload: Dictionary) -> void:
    var id: String = str(payload.get("id", ""))
    match id:
        "low_gravity":
            _gravity_mult = 1.0
        "speed_burst":
            _speed_mult = 1.0


func _reload_tunables() -> void:
    _gravity_magnitude = GameplayConfig.get_float("gravity_magnitude")
    _terminal_velocity = GameplayConfig.get_float("terminal_velocity")
    _flip_cooldown_ms = GameplayConfig.get_int("tap_flip_cooldown_ms")
    _run_speed = GameplayConfig.get_float("player_base_speed")


func _resolve_difficulty() -> void:
    if difficulty.is_empty():
        return
    var n := get_node_or_null(difficulty)
    if n != null:
        _difficulty = n


func _difficulty_speed_multiplier() -> float:
    if _difficulty == null or not _difficulty.has_method("speed_multiplier"):
        return 1.0
    return float(_difficulty.speed_multiplier())
