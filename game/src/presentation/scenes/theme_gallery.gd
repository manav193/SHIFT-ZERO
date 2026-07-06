## ThemeGallery
##
## Preview and unlock-state browser for procedural world themes.
extends Control

const ThemeCatalog := preload("res://src/core/theme_catalog.gd")
const PremiumUI := preload("res://src/presentation/ui/premium_ui.gd")

const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _title: Label = $Root/Header/Title
@onready var _list: VBoxContainer = $Root/Body/Scroll/List
@onready var _preview_name: Label = $Root/Body/Preview/V/Name
@onready var _preview_state: Label = $Root/Body/Preview/V/State
@onready var _sky_top: ColorRect = $Root/Body/Preview/V/Stage/SkyTop
@onready var _sky_bottom: ColorRect = $Root/Body/Preview/V/Stage/SkyBottom
@onready var _band_a: ColorRect = $Root/Body/Preview/V/Stage/BandA
@onready var _band_b: ColorRect = $Root/Body/Preview/V/Stage/BandB
@onready var _ground: ColorRect = $Root/Body/Preview/V/Stage/Ground
@onready var _obstacle_a: ColorRect = $Root/Body/Preview/V/Stage/ObstacleA
@onready var _obstacle_b: Polygon2D = $Root/Body/Preview/V/Stage/ObstacleB
@onready var _coin: Polygon2D = $Root/Body/Preview/V/Stage/Coin
@onready var _powerup: Polygon2D = $Root/Body/Preview/V/Stage/Powerup
@onready var _particles: CPUParticles2D = $Root/Body/Preview/V/Stage/Particles

var _unlocked: Array = []


func _ready() -> void:
    PremiumUI.apply_screen(self)
    _back_btn.pressed.connect(_on_back_pressed)
    _load_unlocks()
    _populate()
    _show_theme(ThemeCatalog.all()[0])


func _load_unlocks() -> void:
    _unlocked = ThemeCatalog.default_unlocked()
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = ThemeCatalog.unlock_available(state.get("progression", {}))
        state["progression"] = progression
        return state)
    if not result.ok:
        return
    var loaded: Result = save.load_state()
    if not loaded.ok:
        return
    var state: Dictionary = loaded.value
    _unlocked = ThemeCatalog.unlocked_theme_ids(state.get("progression", {}))


func _populate() -> void:
    for child in _list.get_children():
        child.queue_free()
    for theme in ThemeCatalog.all():
        var row := Button.new()
        var owned := _unlocked.has(str(theme.id))
        row.custom_minimum_size = Vector2(0.0, 82.0)
        row.text = "%s%s" % [str(theme.name).to_upper(), "" if owned else "  LOCKED"]
        row.add_theme_font_size_override("font_size", 26)
        row.modulate = Color.WHITE if owned else Color(0.58, 0.62, 0.68, 1.0)
        row.pressed.connect(func() -> void: _show_theme(theme))
        _list.add_child(row)
        PremiumUI.style_button(row, theme.get("light", Color(0.0, 0.941, 1.0, 1.0)))


func _show_theme(theme: Dictionary) -> void:
    var owned := _unlocked.has(str(theme.id))
    _preview_name.text = str(theme.name).to_upper()
    _preview_state.text = "UNLOCKED" if owned else ThemeCatalog.unlock_text(theme).to_upper()
    _preview_state.modulate = Color(0.3, 1.0, 0.55, 1.0) if owned else Color(1.0, 0.82, 0.26, 1.0)
    _sky_top.color = theme.get("sky_top", Color.BLACK)
    _sky_bottom.color = theme.get("sky_bottom", Color.BLACK)
    var bands: Array = theme.get("bands", [])
    _band_a.color = bands[1] if bands.size() > 1 else theme.get("sky_bottom", Color.BLACK)
    _band_b.color = bands[2] if bands.size() > 2 else theme.get("ground", Color.WHITE)
    _ground.color = theme.get("ground", Color.WHITE)
    var obstacles: Array = theme.get("obstacles", [])
    _obstacle_a.color = obstacles[0] if obstacles.size() > 0 else Color.WHITE
    _obstacle_b.color = obstacles[1] if obstacles.size() > 1 else Color.WHITE
    _coin.color = theme.get("coin", Color.YELLOW)
    _powerup.color = theme.get("powerup", Color.CYAN)
    _particles.color = theme.get("particle", Color.WHITE)
    _particles.restart()


func _on_back_pressed() -> void:
    var result: Result = SceneRouter.push(_MAIN_MENU_PATH)
    if not result.ok:
        push_error("ThemeGallery", "back failed: %s" % result.error)
