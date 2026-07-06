## WorldThemeController
##
## Drives procedural biome visuals from run distance. It emits theme changes;
## gameplay spawners keep their existing generation logic.
extends Node2D

const Events := preload("res://src/core/events.gd")
const ThemeCatalog := preload("res://src/core/theme_catalog.gd")

@export var target: NodePath
@export var background: NodePath

var _target: Node2D
var _background: ColorRect
var _start_x: float = 0.0
var _current_theme_id: String = ""
var _unlocked_ids: Array = []
var _title: Label
var _flash: ColorRect
var _particles: CPUParticles2D


func _ready() -> void:
    _resolve_nodes()
    _load_unlocked()
    _build_transition_nodes()
    if _target != null:
        _start_x = _target.position.x
    _apply_theme(ThemeCatalog.by_id(ThemeCatalog.NEON_CITY), true)


func _process(_delta: float) -> void:
    if _target == null:
        return
    var distance_m := maxf(0.0, _target.position.x - _start_x) / 10.0
    var next := ThemeCatalog.theme_for_distance(distance_m, _unlocked_ids, int(_start_x))
    if str(next.id) != _current_theme_id:
        _apply_theme(next, false)


func _resolve_nodes() -> void:
    var n := get_node_or_null(target)
    if n is Node2D:
        _target = n
    var bg := get_node_or_null(background)
    if bg is ColorRect:
        _background = bg


func _load_unlocked() -> void:
    _unlocked_ids = ThemeCatalog.default_unlocked()
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var result: Result = save.load_state()
    if not result.ok:
        return
    var state: Dictionary = result.value
    var progression: Dictionary = ThemeCatalog.ensure_progression(state.get("progression", {}))
    _unlocked_ids = ThemeCatalog.unlocked_theme_ids(progression)


func _build_transition_nodes() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 8
    add_child(layer)

    _flash = ColorRect.new()
    _flash.anchor_right = 1.0
    _flash.anchor_bottom = 1.0
    _flash.color = Color(1.0, 1.0, 1.0, 0.0)
    _flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(_flash)

    _title = Label.new()
    _title.anchor_left = 0.0
    _title.anchor_right = 1.0
    _title.anchor_top = 0.18
    _title.anchor_bottom = 0.34
    _title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _title.add_theme_font_size_override("font_size", 82)
    _title.add_theme_color_override("font_color", Color.WHITE)
    _title.modulate.a = 0.0
    layer.add_child(_title)

    _particles = CPUParticles2D.new()
    _particles.one_shot = true
    _particles.emitting = false
    _particles.amount = 42
    _particles.lifetime = 0.7
    _particles.explosiveness = 0.85
    _particles.spread = 180.0
    _particles.initial_velocity_min = 80.0
    _particles.initial_velocity_max = 260.0
    _particles.gravity = Vector2.ZERO
    _particles.scale_amount_min = 3.0
    _particles.scale_amount_max = 7.0
    _particles.position = Vector2(540.0, 960.0)
    add_child(_particles)


func _apply_theme(theme: Dictionary, instant: bool) -> void:
    _current_theme_id = str(theme.id)
    if _background != null:
        if instant:
            _background.color = theme.get("sky_top", Color.BLACK)
        else:
            var tween := create_tween()
            tween.tween_property(_background, "color", theme.get("sky_top", Color.BLACK), 0.65)
    EventBus.emit(Events.WORLD_THEME_CHANGED, {
        "id": _current_theme_id,
        "name": str(theme.name),
        "theme": theme,
        "instant": instant,
    })
    if not instant:
        _play_transition(theme)


func _play_transition(theme: Dictionary) -> void:
    _title.text = str(theme.name).to_upper()
    _title.modulate = theme.get("light", Color.WHITE)
    _title.modulate.a = 0.0
    _flash.color = Color(1.0, 1.0, 1.0, 0.24)
    _particles.color = theme.get("particle", Color.WHITE)
    _particles.global_position = _target.global_position if _target != null else Vector2(540.0, 960.0)
    _particles.restart()
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(_flash, "color:a", 0.0, 0.28)
    tween.parallel().tween_property(_title, "modulate:a", 1.0, 0.16)
    tween.tween_interval(0.7)
    tween.tween_property(_title, "modulate:a", 0.0, 0.24)
