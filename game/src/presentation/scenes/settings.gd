## SettingsScreen
##
## Basic M2 settings. Values flow through ISettingsService so persistence and
## EventBus fan-out stay centralized.
extends Control

const PremiumUI := preload("res://src/presentation/ui/premium_ui.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _master_slider: HSlider = $Center/V/MasterRow/MasterSlider
@onready var _master_value: Label = $Center/V/MasterRow/MasterValue
@onready var _haptics_toggle: CheckButton = $Center/V/HapticsToggle
@onready var _shake_toggle: CheckButton = $Center/V/ShakeToggle
@onready var _particles_toggle: CheckButton = $Center/V/ParticlesToggle
@onready var _battery_toggle: CheckButton = $Center/V/BatteryToggle
@onready var _scale_slider: HSlider = $Center/V/ScaleRow/ScaleSlider
@onready var _scale_value: Label = $Center/V/ScaleRow/ScaleValue
@onready var _palette_options: OptionButton = $Center/V/PaletteRow/PaletteOptions
@onready var _back_btn: Button = $Center/V/BackBtn

var _settings: Object
var _loading: bool = true


func _ready() -> void:
    PremiumUI.apply_screen(self)
    _settings = ServiceLocator.get_service("ISettingsService")
    _master_slider.value_changed.connect(_on_master_changed)
    _haptics_toggle.toggled.connect(_on_haptics_toggled)
    _shake_toggle.toggled.connect(_on_shake_toggled)
    _particles_toggle.toggled.connect(_on_particles_toggled)
    _battery_toggle.toggled.connect(_on_battery_toggled)
    _scale_slider.value_changed.connect(_on_scale_changed)
    _palette_options.item_selected.connect(_on_palette_selected)
    _back_btn.pressed.connect(_on_back_pressed)
    _wire_button(_haptics_toggle)
    _wire_button(_shake_toggle)
    _wire_button(_particles_toggle)
    _wire_button(_battery_toggle)
    _wire_button(_back_btn)
    _populate_palettes()
    _load_current_values()
    _loading = false


func _load_current_values() -> void:
    var master := 1.0
    var haptics := true
    var reduced_shake := false
    var reduced_particles := false
    var battery := false
    var ui_scale := 1.0
    var palette_id := "default_neon"
    if _settings != null:
        master = float(_settings.get_value("audio_master", 1.0))
        haptics = bool(_settings.get_value("haptics_enabled", true))
        reduced_shake = bool(_settings.get_value("reduced_screen_shake", false))
        reduced_particles = bool(_settings.get_value("reduced_particles", false))
        battery = bool(_settings.get_value("battery_30fps", false))
        ui_scale = float(_settings.get_value("ui_scale", 1.0))
        palette_id = str(_settings.get_value("color_palette_id", "default_neon"))
    _master_slider.value = clampf(master, 0.0, 1.0)
    _haptics_toggle.button_pressed = haptics
    _shake_toggle.button_pressed = reduced_shake
    _particles_toggle.button_pressed = reduced_particles
    _battery_toggle.button_pressed = battery
    _scale_slider.value = clampf(ui_scale, 0.85, 1.25)
    _select_palette(palette_id)
    _apply_master_volume(_master_slider.value)
    _update_master_label(_master_slider.value)
    _update_scale_label(_scale_slider.value)


func _on_master_changed(value: float) -> void:
    _apply_master_volume(value)
    _update_master_label(value)
    if _loading or _settings == null:
        return
    _settings.set_value("audio_master", value)


func _on_haptics_toggled(enabled: bool) -> void:
    if _loading or _settings == null:
        return
    _settings.set_value("haptics_enabled", enabled)


func _on_shake_toggled(enabled: bool) -> void:
    if _loading or _settings == null:
        return
    _settings.set_value("reduced_screen_shake", enabled)


func _on_particles_toggled(enabled: bool) -> void:
    if _loading or _settings == null:
        return
    _settings.set_value("reduced_particles", enabled)
    _settings.set_value("visual_effects_level", 1 if enabled else 3)


func _on_battery_toggled(enabled: bool) -> void:
    Engine.max_fps = 30 if enabled else 60
    if _loading or _settings == null:
        return
    _settings.set_value("battery_30fps", enabled)


func _on_scale_changed(value: float) -> void:
    _update_scale_label(value)
    get_tree().root.content_scale_factor = clampf(value, 0.85, 1.25)
    if _loading or _settings == null:
        return
    _settings.set_value("ui_scale", value)


func _on_palette_selected(index: int) -> void:
    if _loading or _settings == null:
        return
    _settings.set_value("color_palette_id", str(_palette_options.get_item_metadata(index)))


func _on_back_pressed() -> void:
    var result: Result = SceneRouter.push(_MAIN_MENU_PATH)
    if not result.ok:
        push_error("Settings", "back failed: %s" % result.error)


func _apply_master_volume(value: float) -> void:
    var idx := AudioServer.get_bus_index("Master")
    if idx >= 0:
        AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(value, 0.0, 1.0)))


func _update_master_label(value: float) -> void:
    _master_value.text = "%d%%" % int(round(clampf(value, 0.0, 1.0) * 100.0))


func _update_scale_label(value: float) -> void:
    _scale_value.text = "%d%%" % int(round(clampf(value, 0.85, 1.25) * 100.0))


func _populate_palettes() -> void:
    var palettes := [
        ["DEFAULT", "default_neon"],
        ["DEUTERANOPIA", "deuteranopia"],
        ["PROTANOPIA", "protanopia"],
        ["TRITANOPIA", "tritanopia"],
        ["HIGH CONTRAST", "high_contrast"],
    ]
    _palette_options.clear()
    for item in palettes:
        _palette_options.add_item(str(item[0]))
        _palette_options.set_item_metadata(_palette_options.item_count - 1, str(item[1]))


func _select_palette(id: String) -> void:
    for i in _palette_options.item_count:
        if str(_palette_options.get_item_metadata(i)) == id:
            _palette_options.select(i)
            return


func _wire_button(button: Button) -> void:
    button.mouse_entered.connect(func() -> void: _button_to(button, Vector2(1.04, 1.04), 0.08))
    button.mouse_exited.connect(func() -> void: _button_to(button, Vector2.ONE, 0.10))
    button.button_down.connect(func() -> void: _button_to(button, Vector2(0.94, 0.94), 0.05))
    button.button_up.connect(func() -> void: _button_to(button, Vector2(1.04, 1.04), 0.08))


func _button_to(button: Button, target_scale: Vector2, duration: float) -> void:
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", target_scale, duration)
