## HapticsSystem
##
## Fires Android-style handheld vibration on key gameplay events.
## Silently no-ops on desktop / web (Godot's Input.vibrate_handheld handles it).
extends Node

const Events := preload("res://src/core/events.gd")

var _enabled: bool = true


func _ready() -> void:
    EventBus.subscribe(Events.PLAYER_GRAVITY_FLIPPED, _on_flip)
    EventBus.subscribe(Events.RUN_FINISHED, _on_death)
    Logger.info("Haptics", "haptics system ready")


func set_enabled(enabled: bool) -> void:
    _enabled = enabled


func _on_flip(_p: Dictionary) -> void:
    if not _enabled:
        return
    Input.vibrate_handheld(15)


func _on_death(_p: Dictionary) -> void:
    if not _enabled:
        return
    Input.vibrate_handheld(80)
