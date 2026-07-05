## MainMenu
##
## Minimal M2 entry point. Keeps scene transitions routed through SceneRouter.
extends Control

const _GAME_WORLD_PATH := "res://src/gameplay/game_world/game_world.tscn"
const _SETTINGS_PATH := "res://src/presentation/scenes/settings.tscn"
const _SHOP_PATH := "res://src/presentation/scenes/shop.tscn"

@onready var _play_btn: Button = $Center/V/PlayBtn
@onready var _shop_btn: Button = $Center/V/ShopBtn
@onready var _settings_btn: Button = $Center/V/SettingsBtn
@onready var _quit_btn: Button = $Center/V/QuitBtn
@onready var _coins_label: Label = $Center/V/Coins


func _ready() -> void:
    _play_btn.pressed.connect(_on_play_pressed)
    _shop_btn.pressed.connect(_on_shop_pressed)
    _settings_btn.pressed.connect(_on_settings_pressed)
    _quit_btn.pressed.connect(_on_quit_pressed)
    _wire_button(_play_btn)
    _wire_button(_shop_btn)
    _wire_button(_settings_btn)
    _wire_button(_quit_btn)
    _coins_label.text = "TOTAL COINS %d" % _load_total_coins()


func _on_play_pressed() -> void:
    var result: Result = SceneRouter.push(_GAME_WORLD_PATH)
    if not result.ok:
        push_error("MainMenu", "play failed: %s" % result.error)


func _on_settings_pressed() -> void:
    var result: Result = SceneRouter.push(_SETTINGS_PATH)
    if not result.ok:
        push_error("MainMenu", "settings failed: %s" % result.error)


func _on_shop_pressed() -> void:
    var result: Result = SceneRouter.push(_SHOP_PATH)
    if not result.ok:
        push_error("MainMenu", "shop failed: %s" % result.error)


func _on_quit_pressed() -> void:
    get_tree().quit()


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


func _load_total_coins() -> int:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return 0
    var result: Result = save.load_state()
    if not result.ok:
        return 0
    var state: Dictionary = result.value
    var progression: Dictionary = state.get("progression", {})
    return int(progression.get("total_coins", 0))
