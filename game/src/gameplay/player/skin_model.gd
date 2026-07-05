## SkinModel
##
## Procedural character renderer used by gameplay and the shop preview.
class_name SkinModel
extends Node2D

const SkinCatalog := preload("res://src/core/skin_catalog.gd")

var _skin: Dictionary = SkinCatalog.by_id(SkinCatalog.CLASSIC)
var _body: Node2D
var _phase: float = 0.0
var _idle: String = "run"


func _ready() -> void:
    if _body == null:
        apply_skin(_skin)


func _process(delta: float) -> void:
    _phase += delta
    if _body == null:
        return
    match _idle:
        "run":
            _body.position.y = sin(_phase * 9.0) * 3.0
            _body.rotation = sin(_phase * 9.0) * 0.08
        "tilt":
            _body.rotation = sin(_phase * 3.5) * 0.18
        "servo":
            _body.position.y = round(sin(_phase * 5.0) * 2.0)
        "stealth":
            _body.scale = Vector2.ONE * (0.94 + sin(_phase * 4.0) * 0.03)
        "bob", "hover", "float":
            _body.position.y = sin(_phase * 2.6) * 7.0
        "thrust":
            _body.position.y = sin(_phase * 7.0) * 2.0
            _body.rotation = sin(_phase * 5.0) * 0.07
        "crawl":
            _body.rotation = sin(_phase * 8.0) * 0.06
        "shimmer":
            _body.scale = Vector2(1.0 + sin(_phase * 5.0) * 0.04, 1.0 - sin(_phase * 5.0) * 0.03)
        "wing":
            _body.position.y = sin(_phase * 4.8) * 4.0
        "pulse":
            _body.scale = Vector2.ONE * (1.0 + sin(_phase * 4.0) * 0.06)


func apply_skin(skin: Dictionary) -> void:
    _skin = skin
    _idle = str(skin.get("idle", "run"))
    _phase = 0.0
    _clear()
    _body = Node2D.new()
    add_child(_body)
    var shape := str(skin.get("shape", "runner"))
    match shape:
        "cube":
            _build_cube()
        "robot":
            _build_robot()
        "ninja":
            _build_ninja()
        "alien":
            _build_alien()
        "ufo":
            _build_ufo()
        "rocket":
            _build_rocket()
        "spider":
            _build_spider()
        "crystal":
            _build_crystal()
        "ghost":
            _build_ghost()
        "dragon":
            _build_dragon()
        "core":
            _build_core()
        _:
            _build_runner()


func play_flip_punch() -> void:
    scale = Vector2(1.24, 0.78)
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", Vector2.ONE, 0.18)
    tween.parallel().tween_property(self, "modulate", _skin.get("flash", Color.WHITE), 0.08)
    tween.tween_property(self, "modulate", Color.WHITE, 0.12)


func play_land_squash() -> void:
    scale = Vector2(1.18, 0.76)
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_ELASTIC)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", Vector2.ONE, 0.22)


func trail_points(global_pos: Vector2) -> PackedVector2Array:
    var style := str(_skin.get("trail_style", "dash"))
    match style:
        "flame":
            return PackedVector2Array([global_pos + Vector2(-44, 0), global_pos + Vector2(-88, -14), global_pos + Vector2(-126, 8)])
        "beam":
            return PackedVector2Array([global_pos + Vector2(-30, -18), global_pos + Vector2(-132, -18), global_pos + Vector2(-132, 18), global_pos + Vector2(-30, 18)])
        "web":
            return PackedVector2Array([global_pos, global_pos + Vector2(-46, -22), global_pos + Vector2(-94, 0), global_pos + Vector2(-46, 22)])
        "slash":
            return PackedVector2Array([global_pos + Vector2(-18, -28), global_pos + Vector2(-96, 26)])
        "bubbles", "mist":
            return PackedVector2Array([global_pos + Vector2(-20, 0), global_pos + Vector2(-54, -10), global_pos + Vector2(-86, 8), global_pos + Vector2(-118, -6)])
        "circuit":
            return PackedVector2Array([global_pos, global_pos + Vector2(-34, 0), global_pos + Vector2(-34, -18), global_pos + Vector2(-86, -18), global_pos + Vector2(-86, 10), global_pos + Vector2(-126, 10)])
        _:
            return PackedVector2Array([global_pos + Vector2(-18, 0), global_pos + Vector2(-72, 0), global_pos + Vector2(-122, 0)])


func trail_width() -> float:
    return float(_skin.get("trail_width", 12.0))


func trail_color() -> Color:
    return _skin.get("trail", Color(0.0, 0.941, 1.0, 0.65))


func _clear() -> void:
    for child in get_children():
        child.queue_free()


func _build_runner() -> void:
    _poly([Vector2(-22, -28), Vector2(20, -24), Vector2(30, 12), Vector2(0, 34), Vector2(-32, 14)], _c("player"))
    _poly([Vector2(18, -14), Vector2(48, -4), Vector2(20, 8)], _c("accent"))
    _line([Vector2(-8, 26), Vector2(-28, 52)], _c("accent"), 7.0)
    _line([Vector2(12, 24), Vector2(38, 48)], _c("accent"), 7.0)


func _build_cube() -> void:
    _poly([Vector2(-34, -34), Vector2(34, -34), Vector2(34, 34), Vector2(-34, 34)], _c("player"))
    _line([Vector2(-34, -16), Vector2(34, -16)], _c("accent"), 5.0)
    _line([Vector2(-12, 34), Vector2(-12, -34)], _c("accent"), 5.0)


func _build_robot() -> void:
    _poly([Vector2(-26, -30), Vector2(26, -30), Vector2(30, 24), Vector2(-30, 24)], _c("player"))
    _poly([Vector2(-18, -52), Vector2(18, -52), Vector2(22, -30), Vector2(-22, -30)], _c("player"))
    _poly([Vector2(-14, -44), Vector2(-4, -44), Vector2(-4, -34), Vector2(-14, -34)], _c("accent"))
    _poly([Vector2(4, -44), Vector2(14, -44), Vector2(14, -34), Vector2(4, -34)], _c("accent"))
    _line([Vector2(-34, -4), Vector2(-52, 18)], _c("accent"), 7.0)
    _line([Vector2(34, -4), Vector2(52, 18)], _c("accent"), 7.0)


func _build_ninja() -> void:
    _poly([Vector2(0, -44), Vector2(38, -8), Vector2(12, 36), Vector2(-36, 22), Vector2(-28, -22)], _c("player"))
    _poly([Vector2(-8, -18), Vector2(32, -10), Vector2(20, 4), Vector2(-10, 2)], _c("accent"))
    _line([Vector2(-32, 18), Vector2(42, -40)], _c("accent"), 5.0)


func _build_alien() -> void:
    _poly([Vector2(0, -48), Vector2(36, -18), Vector2(26, 30), Vector2(0, 48), Vector2(-26, 30), Vector2(-36, -18)], _c("player"))
    _poly([Vector2(-18, -16), Vector2(-2, -10), Vector2(-12, 2)], _c("accent"))
    _poly([Vector2(18, -16), Vector2(2, -10), Vector2(12, 2)], _c("accent"))
    _line([Vector2(-18, -42), Vector2(-38, -62)], _c("accent"), 4.0)
    _line([Vector2(18, -42), Vector2(38, -62)], _c("accent"), 4.0)


func _build_ufo() -> void:
    _poly([Vector2(-54, 0), Vector2(-26, -20), Vector2(26, -20), Vector2(54, 0), Vector2(24, 18), Vector2(-24, 18)], _c("player"))
    _poly([Vector2(-22, -20), Vector2(0, -42), Vector2(22, -20)], _c("accent"))
    _line([Vector2(-36, 18), Vector2(-18, 34), Vector2(18, 34), Vector2(36, 18)], _c("accent"), 5.0)


func _build_rocket() -> void:
    _poly([Vector2(0, -58), Vector2(26, -18), Vector2(20, 34), Vector2(0, 52), Vector2(-20, 34), Vector2(-26, -18)], _c("player"))
    _poly([Vector2(-26, 10), Vector2(-52, 36), Vector2(-18, 30)], _c("accent"))
    _poly([Vector2(26, 10), Vector2(52, 36), Vector2(18, 30)], _c("accent"))
    _poly([Vector2(-12, -28), Vector2(12, -28), Vector2(12, -4), Vector2(-12, -4)], Color(0.35, 0.85, 1.0, 1.0))


func _build_spider() -> void:
    _poly([Vector2(0, -34), Vector2(34, -12), Vector2(28, 26), Vector2(0, 42), Vector2(-28, 26), Vector2(-34, -12)], _c("player"))
    for y in [-20.0, -4.0, 12.0, 26.0]:
        _line([Vector2(-24, y), Vector2(-58, y - 16.0)], _c("accent"), 4.0)
        _line([Vector2(24, y), Vector2(58, y - 16.0)], _c("accent"), 4.0)


func _build_crystal() -> void:
    _poly([Vector2(0, -58), Vector2(34, -18), Vector2(22, 42), Vector2(0, 58), Vector2(-22, 42), Vector2(-34, -18)], _c("player"))
    _line([Vector2(0, -58), Vector2(0, 58)], _c("accent"), 4.0)
    _line([Vector2(-34, -18), Vector2(22, 42)], _c("accent"), 3.0)
    _line([Vector2(34, -18), Vector2(-22, 42)], _c("accent"), 3.0)


func _build_ghost() -> void:
    _poly([Vector2(0, -50), Vector2(34, -28), Vector2(36, 20), Vector2(22, 42), Vector2(8, 28), Vector2(-6, 44), Vector2(-22, 28), Vector2(-36, 42), Vector2(-34, -28)], _c("player"))
    _poly([Vector2(-16, -20), Vector2(-4, -20), Vector2(-4, -8), Vector2(-16, -8)], _c("accent"))
    _poly([Vector2(6, -20), Vector2(18, -20), Vector2(18, -8), Vector2(6, -8)], _c("accent"))


func _build_dragon() -> void:
    _poly([Vector2(-30, -20), Vector2(8, -40), Vector2(38, -18), Vector2(22, 34), Vector2(-18, 38), Vector2(-42, 10)], _c("player"))
    _poly([Vector2(-8, -34), Vector2(-34, -66), Vector2(18, -42)], _c("accent"))
    _poly([Vector2(22, -14), Vector2(56, -28), Vector2(34, 4)], _c("accent"))
    _line([Vector2(-32, 20), Vector2(-60, 38), Vector2(-36, 46)], _c("accent"), 5.0)


func _build_core() -> void:
    _poly([Vector2(0, -46), Vector2(38, 0), Vector2(0, 46), Vector2(-38, 0)], _c("player"))
    _poly([Vector2(0, -24), Vector2(20, 0), Vector2(0, 24), Vector2(-20, 0)], _c("accent"))
    _line([Vector2(-58, 0), Vector2(-38, 0), Vector2(-22, -22)], _c("accent"), 4.0)
    _line([Vector2(58, 0), Vector2(38, 0), Vector2(22, 22)], _c("accent"), 4.0)
    _line([Vector2(0, -58), Vector2(0, -46)], _c("accent"), 4.0)


func _poly(points: Array[Vector2], color: Color) -> Polygon2D:
    var p := Polygon2D.new()
    p.polygon = PackedVector2Array(points)
    p.color = color
    _body.add_child(p)
    return p


func _line(points: Array[Vector2], color: Color, width: float) -> Line2D:
    var line := Line2D.new()
    line.points = PackedVector2Array(points)
    line.default_color = color
    line.width = width
    line.begin_cap_mode = Line2D.LINE_CAP_ROUND
    line.end_cap_mode = Line2D.LINE_CAP_ROUND
    _body.add_child(line)
    return line


func _c(key: String) -> Color:
    return _skin.get(key, Color.WHITE)
