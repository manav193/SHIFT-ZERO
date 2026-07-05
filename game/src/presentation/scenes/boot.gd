## Boot scene controller.
##
## Renders the SHIFT // ZERO splash and reports app-boot status. In M1
## it will hand off to the Main Menu scene once assets are pre-warmed.
extends Control

const Events := preload("res://src/core/events.gd")

@onready var _status: Label = $Center/V/Status


func _ready() -> void:
    _status.text = "booting %s…" % Config.version_string()
    EventBus.subscribe(Events.APP_BOOTED, _on_app_booted)


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.APP_BOOTED, _on_app_booted)


func _on_app_booted(payload: Dictionary) -> void:
    _status.text = "ready · " + str(payload.get("version", ""))
    Logger.info("Boot", "app booted successfully")
    # M1 will hand off to the Main Menu here.
