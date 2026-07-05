## Boot scene controller.
##
## Renders the SHIFT // ZERO splash for a brief moment, then hands off to
## the M1.1 player-controller test chamber. Fixes an M0 latent issue where
## APP_BOOTED had already fired by the time this scene's _ready() ran.
extends Control

const _SPLASH_HOLD_S := 0.6
const _TEST_CHAMBER_PATH := "res://src/gameplay/test_chamber/test_chamber.tscn"

@onready var _status: Label = $Center/V/Status


func _ready() -> void:
    _status.text = "ready · " + Config.version_string()
    Logger.info("Boot", "splash shown, handing off in %.2fs" % _SPLASH_HOLD_S)
    _handoff_after_delay()


func _handoff_after_delay() -> void:
    await get_tree().create_timer(_SPLASH_HOLD_S).timeout
    if not is_inside_tree():
        return
    var result: Result = SceneRouter.push(_TEST_CHAMBER_PATH)
    if not result.ok:
        Logger.error("Boot", "handoff failed: %s" % result.error)
