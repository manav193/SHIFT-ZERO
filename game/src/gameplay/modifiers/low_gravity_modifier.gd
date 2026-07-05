## LowGravityModifier
##
## Halves gravity for the duration. Player consumes the MODIFIER_ACTIVATED
## payload and applies `params.gravity_scale` to its gravity multiplier.
class_name LowGravityModifier
extends "res://src/gameplay/modifiers/i_modifier.gd"

var _scale: float = 0.5


func _init(scale: float = 0.5) -> void:
    _scale = scale


func id() -> String:
    return "low_gravity"


func display_name() -> String:
    return "LOW G"


func activate(_params: Dictionary) -> void:
    pass


func deactivate(_params: Dictionary) -> void:
    pass


func scale() -> float:
    return _scale
