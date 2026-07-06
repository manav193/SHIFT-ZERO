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
const SkinCatalog := preload("res://src/core/skin_catalog.gd")

@export var difficulty: NodePath

@onready var _model: SkinModel = $SkinModel
@onready var _trail: Line2D = $Trail

## +1 -> gravity pulls DOWN. -1 -> gravity pulls UP.
var _gravity_dir: int = 1
var _difficulty: Node
var _visual_tween: Tween
var _skin: Dictionary = SkinCatalog.by_id(SkinCatalog.CLASSIC)

## Timestamp (ms) of the last accepted flip -- used to enforce cooldown.
var _last_flip_ms: int = -100000

# Cached tunables, refreshed on _ready and whenever Remote Config activates.
var _gravity_magnitude: float = 1600.0
var _terminal_velocity: float = 1800.0
var _flip_cooldown_ms: int = 80
var _run_speed: float = 420.0

# Runtime modifier multipliers. 1.0 = no effect.
var _gravity_mult: float = 1.0
var _boss_gravity_mult: float = 1.0
var _boss_gravity_until_ms: int = 0
var _speed_mult: float = 1.0
var _shield_charges: int = 0
var _magnet_until_ms: int = 0
var _double_score_until_ms: int = 0
var _magnet_announced_expired: bool = true
var _double_score_announced_expired: bool = true

## True while the run is RUNNING. Toggled by RUN_STARTED and RUN_FINISHED.
var _active: bool = false

## Was the player on the floor/ceiling last frame? Used for landing detection.
var _was_on_surface: bool = false


func _ready() -> void:
    _reload_tunables()
    _resolve_difficulty()
    _load_skin()
    _apply_skin()
    add_to_group("player")
    EventBus.subscribe(Events.INPUT_TAP, _on_input_tap)
    EventBus.subscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    EventBus.subscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.subscribe(Events.MODIFIER_ACTIVATED, _on_modifier_activated)
    EventBus.subscribe(Events.MODIFIER_EXPIRED, _on_modifier_expired)
    EventBus.subscribe(Events.BOSS_GRAVITY_PULSE, _on_boss_gravity_pulse)
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
    EventBus.unsubscribe(Events.BOSS_GRAVITY_PULSE, _on_boss_gravity_pulse)


func _physics_process(delta: float) -> void:
    if not _active:
        return
    _update_powerup_expiry()
    _update_trail()
    _update_boss_gravity_expiry()
    velocity.y += float(_gravity_dir) * _gravity_magnitude * _gravity_mult * _boss_gravity_mult * delta
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
        "color": _skin.get("flash", Color(0.0, 0.941, 1.0, 1.0)),
        "t_ms": Time.get_ticks_msec(),
    })
    _play_flip_juice()
    print("Player", "gravity flipped -> %d" % _gravity_dir)


func speed_multiplier() -> float:
    return _speed_mult * _difficulty_speed_multiplier()


func gravity_multiplier() -> float:
    return _gravity_mult


func apply_powerup(id: String, duration_s: float) -> void:
    var now := Time.get_ticks_msec()
    match id:
        "shield":
            _shield_charges = max(_shield_charges, 1)
        "magnet":
            _magnet_until_ms = now + int(duration_s * 1000.0)
            _magnet_announced_expired = false
        "double_score":
            _double_score_until_ms = now + int(duration_s * 1000.0)
            _double_score_announced_expired = false
        _:
            push_warning("Player", "unknown powerup: %s" % id)
            return
    EventBus.emit(Events.POWERUP_ACTIVATED, {
        "id": id,
        "duration_s": duration_s,
        "position": position,
        "t_ms": now,
    })


func consume_shield() -> bool:
    if _shield_charges <= 0:
        return false
    _shield_charges -= 1
    EventBus.emit(Events.SHIELD_USED, {
        "position": position,
        "t_ms": Time.get_ticks_msec(),
    })
    return true


func magnet_active() -> bool:
    return Time.get_ticks_msec() < _magnet_until_ms


func double_score_active() -> bool:
    return Time.get_ticks_msec() < _double_score_until_ms


func _detect_landing() -> void:
    var on_surface: bool = is_on_floor() or is_on_ceiling()
    if on_surface and not _was_on_surface:
        EventBus.emit(Events.PLAYER_LANDED, {
            "position": position,
            "surface": "ceiling" if is_on_ceiling() else "floor",
            "color": _skin.get("land", Color(1.0, 0.169, 0.839, 1.0)),
            "t_ms": Time.get_ticks_msec(),
        })
        _play_land_juice()
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
    _boss_gravity_mult = 1.0
    _boss_gravity_until_ms = 0
    _speed_mult = 1.0
    _shield_charges = 0
    _magnet_until_ms = 0
    _double_score_until_ms = 0
    _magnet_announced_expired = true
    _double_score_announced_expired = true
    _trail.clear_points()
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


func _on_boss_gravity_pulse(payload: Dictionary) -> void:
    _boss_gravity_mult = clampf(float(payload.get("scale", 1.0)), 0.55, 1.4)
    _boss_gravity_until_ms = Time.get_ticks_msec() + int(float(payload.get("duration_s", 1.5)) * 1000.0)


func _update_boss_gravity_expiry() -> void:
    if _boss_gravity_until_ms > 0 and Time.get_ticks_msec() >= _boss_gravity_until_ms:
        _boss_gravity_until_ms = 0
        _boss_gravity_mult = 1.0


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


func _load_skin() -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var result: Result = save.load_state()
    if not result.ok:
        return
    var state: Dictionary = result.value
    var progression: Dictionary = state.get("progression", {})
    _skin = SkinCatalog.by_id(str(progression.get("equipped_skin", SkinCatalog.CLASSIC)))


func _apply_skin() -> void:
    _model.apply_skin(_skin)
    _trail.default_color = _model.trail_color()
    _trail.width = _model.trail_width()
    _trail.top_level = true


func _update_trail() -> void:
    var points := _model.trail_points(global_position)
    for p in points:
        _trail.add_point(p)
    while _trail.get_point_count() > 28:
        _trail.remove_point(0)


func _update_powerup_expiry() -> void:
    var now := Time.get_ticks_msec()
    if not _magnet_announced_expired and now >= _magnet_until_ms:
        _magnet_announced_expired = true
        EventBus.emit(Events.POWERUP_EXPIRED, {"id": "magnet", "t_ms": now})
    if not _double_score_announced_expired and now >= _double_score_until_ms:
        _double_score_announced_expired = true
        EventBus.emit(Events.POWERUP_EXPIRED, {"id": "double_score", "t_ms": now})


func _play_flip_juice() -> void:
    _reset_visual_tween()
    _model.play_flip_punch()


func _play_land_juice() -> void:
    _reset_visual_tween()
    _model.play_land_squash()


func _reset_visual_tween() -> void:
    if _visual_tween != null and _visual_tween.is_valid():
        _visual_tween.kill()
