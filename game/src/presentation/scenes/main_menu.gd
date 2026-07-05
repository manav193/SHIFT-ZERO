## MainMenu
##
## Minimal M2 entry point. Keeps scene transitions routed through SceneRouter.
extends Control

const _GAME_WORLD_PATH := "res://src/gameplay/game_world/game_world.tscn"
const _SETTINGS_PATH := "res://src/presentation/scenes/settings.tscn"

@onready var _play_btn: Button = $Center/V/PlayBtn
@onready var _settings_btn: Button = $Center/V/SettingsBtn
@onready var _quit_btn: Button = $Center/V/QuitBtn


func _ready() -> void:
    _play_btn.pressed.connect(_on_play_pressed)
    _settings_btn.pressed.connect(_on_settings_pressed)
    _quit_btn.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
    var result: Result = SceneRouter.push(_GAME_WORLD_PATH)
    if not result.ok:
        push_error("MainMenu", "play failed: %s" % result.error)


func _on_settings_pressed() -> void:
    var result: Result = SceneRouter.push(_SETTINGS_PATH)
    if not result.ok:
        push_error("MainMenu", "settings failed: %s" % result.error)


func _on_quit_pressed() -> void:
    get_tree().quit()
