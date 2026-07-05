## SpeedBurstModifier
##
## Multiplies player horizontal run speed. Player consumes the payload and
## applies `params.speed_scale` to its speed multiplier.
class_name SpeedBurstModifier
extends "res://src/gameplay/modifiers/i_modifier.gd"

var _scale: float = 1.55


func _init(scale: float = 1.55) -> void:
    _scale = scale


func id() -> String:
    return "speed_burst"


func display_name() -> String:
    return "BURST"


func activate(_params: Dictionary) -> void:
    pass


func deactivate(_params: Dictionary) -> void:
    pass


func scale() -> float:
    return _scale
