## SettingsScreen
##
## Basic M2 settings. Values flow through ISettingsService so persistence and
## EventBus fan-out stay centralized.
extends Control

const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _master_slider: HSlider = $Center/V/MasterRow/MasterSlider
@onready var _master_value: Label = $Center/V/MasterRow/MasterValue
@onready var _haptics_toggle: CheckButton = $Center/V/HapticsToggle
@onready var _back_btn: Button = $Center/V/BackBtn

var _settings: Object
var _loading: bool = true


func _ready() -> void:
    _settings = ServiceLocator.get_service("ISettingsService")
    _master_slider.value_changed.connect(_on_master_changed)
    _haptics_toggle.toggled.connect(_on_haptics_toggled)
    _back_btn.pressed.connect(_on_back_pressed)
    _wire_button(_haptics_toggle)
    _wire_button(_back_btn)
    _load_current_values()
    _loading = false


func _load_current_values() -> void:
    var master := 1.0
    var haptics := true
    if _settings != null:
        master = float(_settings.get_value("audio_master", 1.0))
        haptics = bool(_settings.get_value("haptics_enabled", true))
    _master_slider.value = clampf(master, 0.0, 1.0)
    _haptics_toggle.button_pressed = haptics
    _apply_master_volume(_master_slider.value)
    _update_master_label(_master_slider.value)


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
