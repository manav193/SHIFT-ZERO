## CameraDirector
##
## Camera controller for gameplay scenes. Follows a Node2D target with
## per-axis locks and manual exponential smoothing. Implements a trauma-
## based screen shake (Squirrel Eiserloh's model) and a camera-impact
## boost on death.
##
## Layer: systems.
class_name CameraDirector
extends Camera2D

const Events := preload("res://src/core/events.gd")

@export var follow_target: NodePath
@export var follow_x: bool = true
@export var follow_y: bool = false

var _target: Node2D
var _base_position: Vector2 = Vector2.ZERO
var _shake_offset: Vector2 = Vector2.ZERO

var _smoothing_speed: float = 5.0
var _look_ahead_x: float = 200.0
var _base_look_ahead_x: float = 200.0
var _shake_decay: float = 1.4
var _shake_max_offset: float = 80.0
var _impact_trauma: float = 0.65
var _design_view_height: float = 2400.0

# Trauma is 0..1; visible shake = trauma^2 for a punchy feel.
var _trauma: float = 0.0
var _shake_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
    _reload_tunables()
    _shake_rng.randomize()
    EventBus.subscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.subscribe(Events.PLAYER_LANDED, _on_landed)
    EventBus.subscribe(Events.PLAYER_GRAVITY_FLIPPED, _on_flipped)
    EventBus.subscribe(Events.BOSS_WARNING, _on_boss_warning)
    EventBus.subscribe(Events.BOSS_DEFEATED, _on_boss_defeated)
    # We do smoothing ourselves so shake can offset the rendered position
    # without being smoothed away.
    position_smoothing_enabled = false
    _resolve_target()
    if _target != null:
        _base_position = _target.position
        position = _base_position
    print("Camera", "ready. smooth=%.2f look_ahead=%.1f decay=%.2f" % [
        _smoothing_speed, _look_ahead_x, _shake_decay,
    ])


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    EventBus.unsubscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.unsubscribe(Events.PLAYER_LANDED, _on_landed)
    EventBus.unsubscribe(Events.PLAYER_GRAVITY_FLIPPED, _on_flipped)
    EventBus.unsubscribe(Events.BOSS_WARNING, _on_boss_warning)
    EventBus.unsubscribe(Events.BOSS_DEFEATED, _on_boss_defeated)


func _process(delta: float) -> void:
    if _target == null:
        return
    var desired := _base_position
    if follow_x:
        desired.x = _target.position.x + _dynamic_look_ahead()
    if follow_y:
        desired.y = _target.position.y
    var t: float = 1.0 - exp(-_smoothing_speed * delta)
    _base_position = _base_position.lerp(desired, t)
    _update_shake(delta)
    _update_responsive_zoom()
    position = _base_position + _shake_offset


## Public API. `intensity` is a 0..1 additive trauma bump. Duration is
## implicit -- trauma decays over `_shake_decay` per second.
func shake(intensity: float, _duration_s: float = 0.0) -> void:
    _trauma = clampf(_trauma + intensity, 0.0, 1.0)


func _update_shake(delta: float) -> void:
    if _trauma <= 0.0:
        _shake_offset = Vector2.ZERO
        return
    var mag: float = _trauma * _trauma * _shake_max_offset
    _shake_offset = Vector2(
        _shake_rng.randf_range(-1.0, 1.0) * mag,
        _shake_rng.randf_range(-1.0, 1.0) * mag,
    )
    _trauma = maxf(0.0, _trauma - _shake_decay * delta)


func _on_flipped(_p: Dictionary) -> void:
    shake(0.22)


func _on_landed(_p: Dictionary) -> void:
    shake(0.08)


func _on_run_finished(_p: Dictionary) -> void:
    # Camera impact -- big trauma spike on death.
    shake(maxf(_impact_trauma, 0.9))


func _on_boss_warning(_p: Dictionary) -> void:
    shake(0.12)


func _on_boss_defeated(_p: Dictionary) -> void:
    shake(0.35)


func _resolve_target() -> void:
    if follow_target.is_empty():
        push_warning("Camera", "no follow_target assigned")
        return
    var n := get_node_or_null(follow_target)
    if n is Node2D:
        _target = n
    else:
        push_warning("Camera", "follow_target does not resolve to a Node2D")


func _reload_tunables() -> void:
    var rc: Object = ServiceLocator.get_service("IRemoteConfigService")
    if rc != null:
        _smoothing_speed = rc.get_float("gameplay.camera_smoothing_speed", 5.0)
        _look_ahead_x = rc.get_float("gameplay.camera_look_ahead_x", 200.0)
        _base_look_ahead_x = _look_ahead_x
        _shake_decay = rc.get_float("gameplay.camera_shake_decay_per_s", 1.4)
        _shake_max_offset = rc.get_float("gameplay.camera_shake_max_offset_px", 80.0)
        _impact_trauma = rc.get_float("gameplay.camera_impact_trauma", 0.65)
        _design_view_height = rc.get_float("gameplay.camera_design_view_height", 2400.0)


func _on_remote_config_activated(_payload: Dictionary) -> void:
    _reload_tunables()


func _update_responsive_zoom() -> void:
    var viewport_height := float(get_viewport_rect().size.y)
    if viewport_height <= 0.0:
        return
    var target_zoom := clampf(viewport_height / _design_view_height, 0.45, 1.0)
    zoom = Vector2(target_zoom, target_zoom)


func _dynamic_look_ahead() -> float:
    var speed := 0.0
    if _target is CharacterBody2D:
        speed = abs((_target as CharacterBody2D).velocity.x)
    var speed_bonus := clampf(speed * 0.28, 0.0, 220.0)
    _look_ahead_x = lerpf(_look_ahead_x, _base_look_ahead_x + speed_bonus, 0.08)
    return _look_ahead_x
