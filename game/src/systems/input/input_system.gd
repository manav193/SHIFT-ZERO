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

const _TAP_DEBOUNCE_MS := 45

var _last_tap_ms: int = -100000


func _ready() -> void:
    print("Input", "input system ready")


func _input(event: InputEvent) -> void:
    if _is_direct_tap(event):
        _emit_tap(event)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("game_tap"):
        _emit_tap(event)


func _is_direct_tap(event: InputEvent) -> bool:
    if event is InputEventScreenTouch:
        return (event as InputEventScreenTouch).pressed and not (event as InputEventScreenTouch).canceled
    if event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton
        return mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
    return false


func _emit_tap(event: InputEvent) -> void:
    if _is_ui_blocked_tap(event):
        return
    var now := Time.get_ticks_msec()
    if now - _last_tap_ms < _TAP_DEBOUNCE_MS:
        return
    _last_tap_ms = now
    EventBus.emit(Events.INPUT_TAP, {
        "t_ms": now,
        "device": _device_kind(event),
    })
    get_viewport().set_input_as_handled()


func _is_ui_blocked_tap(event: InputEvent) -> bool:
    var pos: Variant = _event_position(event)
    if pos == null:
        return false
    var scene := get_tree().current_scene
    if scene == null:
        return false
    return _control_blocks_point(scene, pos)


func _event_position(event: InputEvent) -> Variant:
    if event is InputEventScreenTouch:
        return (event as InputEventScreenTouch).position
    if event is InputEventMouseButton:
        return (event as InputEventMouseButton).position
    return null


func _control_blocks_point(node: Node, point: Vector2) -> bool:
    if node is Control:
        var c := node as Control
        if not c.visible:
            return false
        if (c.name == "PauseModal" or c.name == "GameOverModal") and c.get_global_rect().has_point(point):
            return true
        if c is Button and c.get_global_rect().has_point(point):
            return true
    for child in node.get_children():
        if _control_blocks_point(child, point):
            return true
    return false


func _device_kind(event: InputEvent) -> String:
    if event is InputEventScreenTouch:
        return "touch"
    if event is InputEventMouseButton:
        return "mouse"
    if event is InputEventKey:
        return "key"
    return "unknown"
