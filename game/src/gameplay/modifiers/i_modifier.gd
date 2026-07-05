## IModifier
##
## Contract for a runtime gameplay modifier. A modifier is a short-lived
## effect that changes some aspect of gameplay (gravity, time-scale, speed,
## visuals, ...). ModifierManager owns activation, expiry and scheduling.
##
## Modifiers must be idempotent and side-effect-free on failure. Their
## `activate()` / `deactivate()` hooks receive the same params dictionary
## used in the EventBus payload.
##
## Layer: gameplay.
class_name IModifier
extends RefCounted


func id() -> String:
    return "unknown"


## Human-readable display name for HUD badges.
func display_name() -> String:
    return "MOD"


## Duration in seconds; may be overridden by params.
func default_duration_s() -> float:
    return 6.0


## Called by ModifierManager when the modifier begins.
## The manager also emits Events.MODIFIER_ACTIVATED on the EventBus so
## subsystems (Player, VFX, HUD) can react without direct coupling.
func activate(_params: Dictionary) -> void:
    pass


## Called by ModifierManager when the modifier expires or is cancelled.
func deactivate(_params: Dictionary) -> void:
    pass
