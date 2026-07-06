## MainMenu
##
## Minimal M2 entry point. Keeps scene transitions routed through SceneRouter.
extends Control

const ProgressionRules := preload("res://src/core/progression_rules.gd")

const _GAME_WORLD_PATH := "res://src/gameplay/game_world/game_world.tscn"
const _SETTINGS_PATH := "res://src/presentation/scenes/settings.tscn"
const _SHOP_PATH := "res://src/presentation/scenes/shop.tscn"
const _DAILY_PATH := "res://src/presentation/scenes/daily_missions.tscn"
const _ACHIEVEMENTS_PATH := "res://src/presentation/scenes/achievements.tscn"
const _STATISTICS_PATH := "res://src/presentation/scenes/statistics.tscn"
const _THEME_GALLERY_PATH := "res://src/presentation/scenes/theme_gallery.tscn"
const _DAILY_LOGIN_PATH := "res://src/presentation/scenes/daily_login.tscn"
const _LUCKY_SPIN_PATH := "res://src/presentation/scenes/lucky_spin.tscn"
const _CHESTS_PATH := "res://src/presentation/scenes/chests.tscn"

@onready var _play_btn: Button = $Center/V/PlayBtn
@onready var _shop_btn: Button = $Center/V/ShopBtn
@onready var _daily_login_btn: Button = $Center/V/DailyLoginBtn
@onready var _lucky_spin_btn: Button = $Center/V/LuckySpinBtn
@onready var _chests_btn: Button = $Center/V/ChestsBtn
@onready var _daily_btn: Button = $Center/V/DailyBtn
@onready var _achievements_btn: Button = $Center/V/AchievementsBtn
@onready var _statistics_btn: Button = $Center/V/StatisticsBtn
@onready var _theme_gallery_btn: Button = $Center/V/ThemeGalleryBtn
@onready var _settings_btn: Button = $Center/V/SettingsBtn
@onready var _quit_btn: Button = $Center/V/QuitBtn
@onready var _coins_label: Label = $Center/V/Coins
@onready var _level_label: Label = $Center/V/PlayerLevel


func _ready() -> void:
    _play_btn.pressed.connect(_on_play_pressed)
    _shop_btn.pressed.connect(_on_shop_pressed)
    _daily_login_btn.pressed.connect(_on_daily_login_pressed)
    _lucky_spin_btn.pressed.connect(_on_lucky_spin_pressed)
    _chests_btn.pressed.connect(_on_chests_pressed)
    _daily_btn.pressed.connect(_on_daily_pressed)
    _achievements_btn.pressed.connect(_on_achievements_pressed)
    _statistics_btn.pressed.connect(_on_statistics_pressed)
    _theme_gallery_btn.pressed.connect(_on_theme_gallery_pressed)
    _settings_btn.pressed.connect(_on_settings_pressed)
    _quit_btn.pressed.connect(_on_quit_pressed)
    _wire_button(_play_btn)
    _wire_button(_shop_btn)
    _wire_button(_daily_login_btn)
    _wire_button(_lucky_spin_btn)
    _wire_button(_chests_btn)
    _wire_button(_daily_btn)
    _wire_button(_achievements_btn)
    _wire_button(_statistics_btn)
    _wire_button(_theme_gallery_btn)
    _wire_button(_settings_btn)
    _wire_button(_quit_btn)
    _load_progress_summary()


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


func _on_daily_login_pressed() -> void:
    var result: Result = SceneRouter.push(_DAILY_LOGIN_PATH)
    if not result.ok:
        push_error("MainMenu", "daily login failed: %s" % result.error)


func _on_lucky_spin_pressed() -> void:
    var result: Result = SceneRouter.push(_LUCKY_SPIN_PATH)
    if not result.ok:
        push_error("MainMenu", "lucky spin failed: %s" % result.error)


func _on_chests_pressed() -> void:
    var result: Result = SceneRouter.push(_CHESTS_PATH)
    if not result.ok:
        push_error("MainMenu", "chests failed: %s" % result.error)


func _on_daily_pressed() -> void:
    var result: Result = SceneRouter.push(_DAILY_PATH)
    if not result.ok:
        push_error("MainMenu", "daily failed: %s" % result.error)


func _on_achievements_pressed() -> void:
    var result: Result = SceneRouter.push(_ACHIEVEMENTS_PATH)
    if not result.ok:
        push_error("MainMenu", "achievements failed: %s" % result.error)


func _on_statistics_pressed() -> void:
    var result: Result = SceneRouter.push(_STATISTICS_PATH)
    if not result.ok:
        push_error("MainMenu", "statistics failed: %s" % result.error)


func _on_theme_gallery_pressed() -> void:
    var result: Result = SceneRouter.push(_THEME_GALLERY_PATH)
    if not result.ok:
        push_error("MainMenu", "theme gallery failed: %s" % result.error)


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


func _load_progress_summary() -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        _coins_label.text = "TOTAL COINS 0"
        _level_label.text = "LEVEL 1  0/160 XP"
        return
    var result: Result = save.load_state()
    if not result.ok:
        _coins_label.text = "TOTAL COINS 0"
        _level_label.text = "LEVEL 1  0/160 XP"
        return
    var state: Dictionary = result.value
    var progression: Dictionary = state.get("progression", {})
    var total_xp := int(progression.get("player_xp", 0))
    var level := int(progression.get("player_level", ProgressionRules.level_for_total_xp(total_xp)))
    var into := ProgressionRules.xp_into_level(total_xp)
    var need := ProgressionRules.required_xp_for_level(level)
    _coins_label.text = "TOTAL COINS %d" % int(progression.get("total_coins", 0))
    _level_label.text = "LEVEL %d  %d/%d XP" % [level, into, need]
