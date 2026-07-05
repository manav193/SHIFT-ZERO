## SlowMotionModifier
##
## Applies a global Engine.time_scale reduction. The pause menu uses
## `get_tree().paused`, which is orthogonal to time_scale, so slow-motion
## and pause do not conflict.
class_name SlowMotionModifier
extends "res://src/gameplay/modifiers/i_modifier.gd"

var _scale: float = 0.55


func _init(scale: float = 0.55) -> void:
    _scale = scale


func id() -> String:
    return "slow_motion"


func display_name() -> String:
    return "SLOW-MO"


func activate(_params: Dictionary) -> void:
    Engine.time_scale = _scale


func deactivate(_params: Dictionary) -> void:
    Engine.time_scale = 1.0


func scale() -> float:
    return _scale
