## InputSystem
##
## Normalizes raw device input (touch / mouse / keyboard) into semantic
## EventBus events. Gameplay code never touches Godot Input directly —
## it subscribes to `Events.INPUT_TAP` etc. via the EventBus.
##
## This indirection is what lets future modifiers (e.g. "Reverse Controls")
## transform inputs without touching the PlayerController.
extends Node

const Events := preload("res://src/core/events.gd")


func _ready() -> void:
    Log.info("Input", "input system ready")


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("game_tap"):
        EventBus.emit(Events.INPUT_TAP, {
            "t_ms": Time.get_ticks_msec(),
            "device": _device_kind(event),
        })
        get_viewport().set_input_as_handled()


func _device_kind(event: InputEvent) -> String:
    if event is InputEventScreenTouch:
        return "touch"
    if event is InputEventMouseButton:
        return "mouse"
    if event is InputEventKey:
        return "key"
    return "unknown"
