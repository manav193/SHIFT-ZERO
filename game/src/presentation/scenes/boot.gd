## Boot scene controller.
##
## Renders the SHIFT // ZERO splash for a brief moment, then hands off to
## the main menu.
extends Control

const _SPLASH_HOLD_S := 0.6
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _status: Label = $Center/V/Status


func _ready() -> void:
    _status.text = "ready · " + Config.version_string()
    print("Boot", "splash shown, handing off in %.2fs" % _SPLASH_HOLD_S)
    _handoff_after_delay()


func _handoff_after_delay() -> void:
    await get_tree().create_timer(_SPLASH_HOLD_S).timeout
    if not is_inside_tree():
        return
    var result: Result = SceneRouter.push(_MAIN_MENU_PATH)
    if not result.ok:
        push_error("Boot", "handoff failed: %s" % result.error)
