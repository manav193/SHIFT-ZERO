## CameraDirector
##
## Camera controller for gameplay scenes. Follows a Node2D target with
## per-axis locks and manual exponential smoothing. Exposes a screen-shake
## seam (`shake()`) reserved for a future milestone — no-op in M1.2.
##
## Layer: systems. Reads tunables via ServiceLocator -> IRemoteConfigService
## so it does NOT depend on the gameplay layer (would violate layer-deps).
class_name CameraDirector
extends Camera2D

const Events := preload("res://src/core/events.gd")

@export var follow_target: NodePath
@export var follow_x: bool = true
@export var follow_y: bool = false

var _target: Node2D
var _base_position: Vector2 = Vector2.ZERO
# Reserved for future screen-shake system. Composed into `position` every
# frame; while zero it has no visible effect but keeps the API stable.
var _shake_offset: Vector2 = Vector2.ZERO

var _smoothing_speed: float = 5.0
var _look_ahead_x: float = 200.0


func _ready() -> void:
    _reload_tunables()
    EventBus.subscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    # We do smoothing ourselves so shake can offset the rendered position
    # without being smoothed away.
    position_smoothing_enabled = false
    _resolve_target()
    if _target != null:
        _base_position = _target.position
        position = _base_position
    Logger.debug("Camera", "ready. smooth=%.2f look_ahead=%.1f" % [_smoothing_speed, _look_ahead_x])


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)


func _process(delta: float) -> void:
    if _target == null:
        return
    var desired := _base_position
    if follow_x:
        desired.x = _target.position.x + _look_ahead_x
    if follow_y:
        desired.y = _target.position.y
    var t: float = 1.0 - exp(-_smoothing_speed * delta)
    _base_position = _base_position.lerp(desired, t)
    position = _base_position + _shake_offset


## Reserved API — no-op until screen-shake ships (deferred per M1.2 scope).
## Callers may invoke this today; the effect will appear once implemented
## without any change to call sites.
func shake(intensity: float, duration_s: float) -> void:
    Logger.trace("Camera", "shake requested intensity=%.2f dur=%.2fs (no-op)" % [intensity, duration_s])


func _resolve_target() -> void:
    if follow_target.is_empty():
        Logger.warn("Camera", "no follow_target assigned")
        return
    var n := get_node_or_null(follow_target)
    if n is Node2D:
        _target = n
    else:
        Logger.warn("Camera", "follow_target does not resolve to a Node2D")


func _reload_tunables() -> void:
    var rc: Object = ServiceLocator.get_service("IRemoteConfigService")
    if rc == null:
        return
    _smoothing_speed = rc.get_float("gameplay.camera_smoothing_speed", 5.0)
    _look_ahead_x = rc.get_float("gameplay.camera_look_ahead_x", 200.0)


func _on_remote_config_activated(_payload: Dictionary) -> void:
    _reload_tunables()
