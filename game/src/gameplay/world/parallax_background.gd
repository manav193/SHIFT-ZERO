## ParallaxBackground
##
## Lightweight moving color bands for gameplay depth. No textures or heavy nodes.
extends Node2D

const Events := preload("res://src/core/events.gd")

@export var target: NodePath

var _target: Node2D
var _bands: Array[ColorRect] = []
var _detail_roots: Array[Node2D] = []
var _theme_id: String = "neon_city"
var _speeds := [0.06, 0.11, 0.18]


func _ready() -> void:
    var n := get_node_or_null(target)
    if n is Node2D:
        _target = n
    _make_band(Color(0.035, 0.05, 0.12, 1.0), 420.0, 0.0)
    _make_band(Color(0.055, 0.03, 0.12, 0.85), 360.0, 760.0)
    _make_band(Color(0.02, 0.11, 0.14, 0.65), 260.0, 1560.0)
    _rebuild_details(_theme_id)
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
    for i in _detail_roots.size():
        var root := _detail_roots[i]
        root.position.x = _target.position.x * (_speeds[min(i, _speeds.size() - 1)] + 0.03)
        root.position.y = sin(Time.get_ticks_msec() * 0.0007 + float(i)) * (6.0 + i * 4.0)


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
    var next_id := str(payload.get("id", _theme_id))
    var bands: Array = theme.get("bands", [])
    for i in _bands.size():
        if i >= bands.size():
            continue
        var color: Color = bands[i]
        if bool(payload.get("instant", false)):
            _bands[i].color = color
        else:
            create_tween().tween_property(_bands[i], "color", color, 0.65)
    if next_id != _theme_id:
        _theme_id = next_id
        _rebuild_details(_theme_id)


func _rebuild_details(theme_id: String) -> void:
    for root in _detail_roots:
        root.queue_free()
    _detail_roots.clear()
    match theme_id:
        "desert":
            _add_mountains(Color(0.55, 0.25, 0.08, 0.46), 0)
            _add_dunes(Color(0.95, 0.62, 0.2, 0.36), 1)
            _add_streaks(Color(1.0, 0.82, 0.36, 0.22), 2)
        "snow":
            _add_mountains(Color(0.7, 0.9, 1.0, 0.42), 0)
            _add_clouds(Color(0.86, 0.96, 1.0, 0.34), 1)
            _add_streaks(Color(1.0, 1.0, 1.0, 0.2), 2)
        "forest":
            _add_trees(Color(0.04, 0.18, 0.08, 0.58), 0)
            _add_trees(Color(0.12, 0.36, 0.14, 0.38), 1)
            _add_streaks(Color(0.34, 1.0, 0.48, 0.18), 2)
        "volcano":
            _add_mountains(Color(0.18, 0.035, 0.02, 0.62), 0)
            _add_lava(Color(1.0, 0.28, 0.02, 0.34), 1)
            _add_streaks(Color(1.0, 0.48, 0.08, 0.24), 2)
        "space":
            _add_stars(Color(0.75, 0.84, 1.0, 0.66), 0)
            _add_planets(Color(0.45, 0.3, 1.0, 0.34), 1)
            _add_streaks(Color(0.25, 0.8, 1.0, 0.2), 2)
        "cyber_grid":
            _add_grid(Color(0.0, 1.0, 0.86, 0.34), 0)
            _add_buildings(Color(0.0, 0.26, 0.32, 0.58), 1)
            _add_streaks(Color(1.0, 0.08, 0.9, 0.22), 2)
        "ancient_temple":
            _add_columns(Color(0.55, 0.46, 0.25, 0.48), 0)
            _add_mountains(Color(0.35, 0.28, 0.14, 0.32), 1)
            _add_streaks(Color(1.0, 0.78, 0.34, 0.2), 2)
        _:
            _add_buildings(Color(0.02, 0.14, 0.2, 0.58), 0)
            _add_buildings(Color(0.06, 0.03, 0.16, 0.42), 1)
            _add_streaks(Color(0.0, 0.941, 1.0, 0.22), 2)


func _root(layer: int) -> Node2D:
    var root := Node2D.new()
    root.z_index = -20 + layer
    add_child(root)
    _detail_roots.append(root)
    return root


func _add_buildings(color: Color, layer: int) -> void:
    var root := _root(layer)
    for i in 18:
        var rect := ColorRect.new()
        rect.color = color
        rect.position = Vector2(-2600.0 + i * 420.0, 470.0 + randf_range(40.0, 220.0) + layer * 130.0)
        rect.size = Vector2(randf_range(90.0, 190.0), randf_range(260.0, 720.0))
        rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        root.add_child(rect)
        if i % 2 == 0:
            var light := ColorRect.new()
            light.color = Color(0.0, 0.941, 1.0, 0.32)
            light.position = rect.position + Vector2(22.0, 36.0)
            light.size = Vector2(22.0, rect.size.y * 0.52)
            light.mouse_filter = Control.MOUSE_FILTER_IGNORE
            root.add_child(light)


func _add_mountains(color: Color, layer: int) -> void:
    var root := _root(layer)
    for i in 12:
        var x := -2800.0 + i * 650.0
        _poly(root, [Vector2(x, 1320), Vector2(x + 330, 520 + layer * 120), Vector2(x + 720, 1320)], color)


func _add_dunes(color: Color, layer: int) -> void:
    var root := _root(layer)
    for i in 14:
        var x := -2600.0 + i * 540.0
        _poly(root, [Vector2(x, 1460), Vector2(x + 270, 1220 + sin(float(i)) * 80.0), Vector2(x + 620, 1460)], color)


func _add_clouds(color: Color, layer: int) -> void:
    var root := _root(layer)
    for i in 16:
        var rect := ColorRect.new()
        rect.color = color
        rect.position = Vector2(-2600.0 + i * 520.0, 210.0 + randf_range(-60.0, 140.0))
        rect.size = Vector2(randf_range(160.0, 360.0), randf_range(34.0, 80.0))
        rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        root.add_child(rect)


func _add_trees(color: Color, layer: int) -> void:
    var root := _root(layer)
    for i in 30:
        var x := -2800.0 + i * 260.0
        _poly(root, [Vector2(x, 1360), Vector2(x + 60, 860 + randf_range(-90.0, 120.0)), Vector2(x + 128, 1360)], color)


func _add_lava(color: Color, layer: int) -> void:
    var root := _root(layer)
    for i in 18:
        var line := Line2D.new()
        line.points = PackedVector2Array([Vector2(-2600.0 + i * 420.0, 1420.0 + randf_range(-80.0, 80.0)), Vector2(-2440.0 + i * 420.0, 1438.0)])
        line.default_color = color
        line.width = randf_range(8.0, 22.0)
        root.add_child(line)


func _add_stars(color: Color, layer: int) -> void:
    var root := _root(layer)
    for i in 90:
        var rect := ColorRect.new()
        rect.color = color
        rect.position = Vector2(randf_range(-2800.0, 5200.0), randf_range(70.0, 930.0))
        rect.size = Vector2.ONE * randf_range(3.0, 9.0)
        rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        root.add_child(rect)


func _add_planets(color: Color, layer: int) -> void:
    var root := _root(layer)
    for i in 5:
        var p := Polygon2D.new()
        var pts: Array[Vector2] = []
        var radius := randf_range(48.0, 130.0)
        for j in 18:
            pts.append(Vector2(cos(float(j) / 18.0 * TAU), sin(float(j) / 18.0 * TAU)) * radius)
        p.polygon = PackedVector2Array(pts)
        p.color = color
        p.position = Vector2(-2100.0 + i * 1700.0, randf_range(140.0, 560.0))
        root.add_child(p)


func _add_grid(color: Color, layer: int) -> void:
    var root := _root(layer)
    for i in 20:
        var line := Line2D.new()
        line.points = PackedVector2Array([Vector2(-2800.0 + i * 420.0, 520.0), Vector2(-1800.0 + i * 420.0, 1540.0)])
        line.default_color = color
        line.width = 4.0
        root.add_child(line)


func _add_columns(color: Color, layer: int) -> void:
    var root := _root(layer)
    for i in 14:
        var rect := ColorRect.new()
        rect.color = color
        rect.position = Vector2(-2600.0 + i * 560.0, 680.0 + layer * 120.0)
        rect.size = Vector2(90.0, 760.0)
        rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        root.add_child(rect)


func _add_streaks(color: Color, layer: int) -> void:
    var root := _root(layer)
    for i in 20:
        var line := Line2D.new()
        var y := randf_range(280.0, 1160.0)
        var x := -2600.0 + i * 430.0
        line.points = PackedVector2Array([Vector2(x, y), Vector2(x + randf_range(90.0, 220.0), y + randf_range(-12.0, 12.0))])
        line.default_color = color
        line.width = randf_range(2.0, 6.0)
        root.add_child(line)


func _poly(root: Node, points: Array[Vector2], color: Color) -> Polygon2D:
    var p := Polygon2D.new()
    p.polygon = PackedVector2Array(points)
    p.color = color
    root.add_child(p)
    return p
