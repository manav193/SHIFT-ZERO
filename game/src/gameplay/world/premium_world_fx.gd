## PremiumWorldFx
##
## Lightweight procedural presentation layer for gameplay: vignette, theme
## weather, scene flashes, and encounter transitions. It reuses nodes and
## responds to existing EventBus channels so gameplay generation stays intact.
extends Node2D

const Events := preload("res://src/core/events.gd")
const ThemeCatalog := preload("res://src/core/theme_catalog.gd")

var _layer: CanvasLayer
var _vignette: ColorRect
var _top_glow: ColorRect
var _bottom_glow: ColorRect
var _flash: ColorRect
var _weather: CPUParticles2D
var _fog: CPUParticles2D
var _boss_label: Label
var _settings: Object
var _theme: Dictionary = ThemeCatalog.by_id(ThemeCatalog.NEON_CITY)
var _phase: float = 0.0
var _particles_scale: float = 1.0
var _shake_scale: float = 1.0


func _ready() -> void:
    _settings = ServiceLocator.get_service("ISettingsService") if ServiceLocator.has("ISettingsService") else null
    _read_accessibility()
    _build_nodes()
    _apply_theme(_theme, true)
    EventBus.subscribe(Events.WORLD_THEME_CHANGED, _on_world_theme_changed)
    EventBus.subscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.subscribe(Events.BOSS_WARNING, _on_boss_warning)
    EventBus.subscribe(Events.BOSS_STARTED, _on_boss_started)
    EventBus.subscribe(Events.BOSS_DEFEATED, _on_boss_defeated)
    EventBus.subscribe(Events.SETTINGS_CHANGED, _on_settings_changed)


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.WORLD_THEME_CHANGED, _on_world_theme_changed)
    EventBus.unsubscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.unsubscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.unsubscribe(Events.BOSS_WARNING, _on_boss_warning)
    EventBus.unsubscribe(Events.BOSS_STARTED, _on_boss_started)
    EventBus.unsubscribe(Events.BOSS_DEFEATED, _on_boss_defeated)
    EventBus.unsubscribe(Events.SETTINGS_CHANGED, _on_settings_changed)


func _process(delta: float) -> void:
    _phase += delta
    var light: Color = _theme.get("light", Color.WHITE)
    var pulse := 0.08 + sin(_phase * 1.6) * 0.025
    _top_glow.color = Color(light.r, light.g, light.b, pulse)
    _bottom_glow.color = Color(light.r, light.g, light.b, pulse * 0.7)
    _vignette.color.a = 0.28 + sin(_phase * 0.9) * 0.025
    _weather.position.x = wrapf(_weather.position.x - delta * 32.0, -160.0, 1240.0)
    _fog.position.x = wrapf(_fog.position.x - delta * 14.0, -260.0, 1340.0)


func _build_nodes() -> void:
    _layer = CanvasLayer.new()
    _layer.layer = 6
    add_child(_layer)

    _vignette = _rect(Color(0.0, 0.0, 0.0, 0.28))
    _layer.add_child(_vignette)

    _top_glow = _rect(Color(0.0, 0.941, 1.0, 0.08))
    _top_glow.anchor_bottom = 0.22
    _layer.add_child(_top_glow)

    _bottom_glow = _rect(Color(1.0, 0.169, 0.839, 0.06))
    _bottom_glow.anchor_top = 0.72
    _layer.add_child(_bottom_glow)

    _flash = _rect(Color(1.0, 1.0, 1.0, 0.0))
    _layer.add_child(_flash)

    _boss_label = Label.new()
    _boss_label.anchor_left = 0.0
    _boss_label.anchor_right = 1.0
    _boss_label.anchor_top = 0.34
    _boss_label.anchor_bottom = 0.52
    _boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _boss_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _boss_label.add_theme_font_size_override("font_size", 78)
    _boss_label.add_theme_color_override("font_color", Color.WHITE)
    _boss_label.modulate.a = 0.0
    _layer.add_child(_boss_label)

    _weather = _weather_particles()
    add_child(_weather)
    _fog = _weather_particles()
    _fog.amount = 18
    _fog.lifetime = 3.8
    _fog.initial_velocity_min = 15.0
    _fog.initial_velocity_max = 45.0
    _fog.scale_amount_min = 10.0
    _fog.scale_amount_max = 28.0
    add_child(_fog)


func _rect(color: Color) -> ColorRect:
    var r := ColorRect.new()
    r.anchor_right = 1.0
    r.anchor_bottom = 1.0
    r.mouse_filter = Control.MOUSE_FILTER_IGNORE
    r.color = color
    return r


func _weather_particles() -> CPUParticles2D:
    var p := CPUParticles2D.new()
    p.position = Vector2(540.0, 300.0)
    p.emitting = true
    p.one_shot = false
    p.amount = 52
    p.lifetime = 2.4
    p.spread = 35.0
    p.direction = Vector2.DOWN
    p.initial_velocity_min = 90.0
    p.initial_velocity_max = 220.0
    p.gravity = Vector2(0.0, 90.0)
    p.scale_amount_min = 2.0
    p.scale_amount_max = 5.0
    return p


func _on_world_theme_changed(payload: Dictionary) -> void:
    _theme = payload.get("theme", _theme)
    _apply_theme(_theme, bool(payload.get("instant", false)))


func _apply_theme(theme: Dictionary, instant: bool) -> void:
    var id := str(theme.get("id", "neon_city"))
    var particle: Color = theme.get("particle", Color.WHITE)
    _weather.color = particle
    _fog.color = Color(particle.r, particle.g, particle.b, 0.18)
    _weather.emitting = _particles_scale > 0.0
    _fog.emitting = _particles_scale > 0.0
    match id:
        "snow":
            _configure_weather(78, Vector2.DOWN, 35.0, 95.0, 0.0, 3.2, 3.0, 7.0)
        "desert":
            _configure_weather(46, Vector2.LEFT, 60.0, 135.0, 18.0, 2.0, 3.0, 8.0)
        "volcano":
            _configure_weather(38, Vector2.UP, 70.0, 180.0, -18.0, 1.8, 4.0, 9.0)
        "space":
            _configure_weather(30, Vector2.LEFT, 18.0, 65.0, 0.0, 4.2, 3.0, 7.0)
        "forest":
            _configure_weather(42, Vector2.DOWN, 30.0, 90.0, 20.0, 2.8, 3.0, 8.0)
        _:
            _configure_weather(58, Vector2.DOWN + Vector2.LEFT * 0.45, 110.0, 260.0, 80.0, 1.7, 2.0, 5.0)
    if not instant:
        _flash_to(theme.get("light", Color.WHITE), 0.18)


func _configure_weather(amount: int, direction: Vector2, v_min: float, v_max: float, gravity_y: float, lifetime: float, s_min: float, s_max: float) -> void:
    var scaled_amount := int(float(amount) * _particles_scale)
    _weather.amount = max(0, scaled_amount)
    _weather.direction = direction.normalized()
    _weather.initial_velocity_min = v_min
    _weather.initial_velocity_max = v_max
    _weather.gravity = Vector2(0.0, gravity_y)
    _weather.lifetime = lifetime
    _weather.scale_amount_min = s_min
    _weather.scale_amount_max = s_max


func _on_run_started(_payload: Dictionary) -> void:
    _flash_to(Color(0.0, 0.941, 1.0, 1.0), 0.12)


func _on_run_finished(_payload: Dictionary) -> void:
    _flash_to(Color(1.0, 0.1, 0.16, 1.0), 0.34)
    _banner("GAME OVER", Color(1.0, 0.22, 0.28, 1.0))


func _on_boss_warning(payload: Dictionary) -> void:
    _banner("WARNING\n%s" % str(payload.get("name", "BOSS")), Color(1.0, 0.84, 0.18, 1.0))
    _flash_to(Color(1.0, 0.6, 0.0, 1.0), 0.22)


func _on_boss_started(payload: Dictionary) -> void:
    _flash_to(payload.get("color", Color(1.0, 0.24, 0.24, 1.0)), 0.18)


func _on_boss_defeated(payload: Dictionary) -> void:
    _banner("BOSS DEFEATED", payload.get("color", Color(1.0, 0.933, 0.0, 1.0)))
    _flash_to(Color(1.0, 0.933, 0.0, 1.0), 0.24)


func _banner(text: String, color: Color) -> void:
    _boss_label.text = text
    _boss_label.modulate = color
    _boss_label.modulate.a = 0.0
    _boss_label.scale = Vector2(0.82, 0.82)
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(_boss_label, "modulate:a", 1.0, 0.16)
    tween.parallel().tween_property(_boss_label, "scale", Vector2.ONE, 0.22)
    tween.tween_interval(0.7)
    tween.tween_property(_boss_label, "modulate:a", 0.0, 0.22)


func _flash_to(color: Color, alpha: float) -> void:
    _flash.color = Color(color.r, color.g, color.b, alpha * _shake_scale)
    var tween := create_tween()
    tween.tween_property(_flash, "color:a", 0.0, 0.28)


func _on_settings_changed(_payload: Dictionary) -> void:
    _read_accessibility()
    _apply_theme(_theme, true)


func _read_accessibility() -> void:
    if _settings == null:
        return
    var level := int(_settings.get_value("visual_effects_level", 3))
    _particles_scale = 0.0 if bool(_settings.get_value("reduced_particles", false)) else clampf(float(level) / 3.0, 0.0, 1.0)
    _shake_scale = 0.35 if bool(_settings.get_value("reduced_screen_shake", false)) else 1.0
    Engine.max_fps = 30 if bool(_settings.get_value("battery_30fps", false)) else 60
