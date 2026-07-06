## ParallaxBackground
##
## Lightweight moving color bands for gameplay depth. No textures or heavy nodes.
extends Node2D

const Events := preload("res://src/core/events.gd")

@export var target: NodePath

var _target: Node2D
var _bands: Array[ColorRect] = []
var _speeds := [0.06, 0.11, 0.18]


func _ready() -> void:
    var n := get_node_or_null(target)
    if n is Node2D:
        _target = n
    _make_band(Color(0.035, 0.05, 0.12, 1.0), 420.0, 0.0)
    _make_band(Color(0.055, 0.03, 0.12, 0.85), 360.0, 760.0)
    _make_band(Color(0.02, 0.11, 0.14, 0.65), 260.0, 1560.0)
    EventBus.subscribe(Events.WORLD_THEME_CHANGED, _on_world_theme_changed)


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.WORLD_THEME_CHANGED, _on_world_theme_changed)


func _process(delta: float) -> void:
    if _target == null:
        return
    for i in _bands.size():
        var band := _bands[i]
        band.position.x = _target.position.x * _speeds[i]
        band.position.y += sin(Time.get_ticks_msec() * 0.001 + float(i)) * delta * 8.0


func _make_band(color: Color, height: float, y: float) -> void:
    var rect := ColorRect.new()
    rect.color = color
    rect.position = Vector2(-3000.0, y)
    rect.size = Vector2(9000.0, height)
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(rect)
    _bands.append(rect)


func _on_world_theme_changed(payload: Dictionary) -> void:
    var theme: Dictionary = payload.get("theme", {})
    var bands: Array = theme.get("bands", [])
    for i in _bands.size():
        if i >= bands.size():
            continue
        var color: Color = bands[i]
        if bool(payload.get("instant", false)):
            _bands[i].color = color
        else:
            create_tween().tween_property(_bands[i], "color", color, 0.65)
