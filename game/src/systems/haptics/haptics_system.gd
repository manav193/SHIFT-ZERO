## HapticsSystem
##
## Fires Android handheld vibration on key gameplay events. Silently no-ops
## on desktop / web (Godot's Input.vibrate_handheld handles it).
##
## Reads live enablement + strength from ISettingsService and updates itself
## on Events.A11Y_HAPTICS_CHANGED.
extends Node

const Events := preload("res://src/core/events.gd")

# Base durations (ms) at strength=1. Scaled by _strength_scale().
const _FLIP_MS := 15
const _LAND_MS := 25
const _DEATH_MS := 90
const _MOD_MS := 40

var _enabled: bool = true
var _strength: int = 1     # 0 (off) .. 2 (strong)


func _ready() -> void:
    EventBus.subscribe(Events.PLAYER_GRAVITY_FLIPPED, _on_flip)
    EventBus.subscribe(Events.PLAYER_LANDED, _on_landed)
    EventBus.subscribe(Events.RUN_FINISHED, _on_death)
    EventBus.subscribe(Events.MODIFIER_ACTIVATED, _on_modifier)
    EventBus.subscribe(Events.A11Y_HAPTICS_CHANGED, _on_a11y_haptics_changed)
    EventBus.subscribe(Events.APP_BOOTED, _on_app_booted)
    Logger.info("Haptics", "haptics system ready")


func set_enabled(enabled: bool) -> void:
    _enabled = enabled


func _on_app_booted(_p: Dictionary) -> void:
    _sync_from_settings()


func _on_a11y_haptics_changed(payload: Dictionary) -> void:
    _enabled = bool(payload.get("enabled", true))
    _strength = int(payload.get("strength", 1))


func _sync_from_settings() -> void:
    var svc: Object = ServiceLocator.get_service("ISettingsService")
    if svc == null:
        return
    _enabled = bool(svc.get_value("haptics_enabled", true))
    _strength = int(svc.get_value("haptics_strength", 1))


func _vibrate(base_ms: int) -> void:
    if not _enabled or _strength <= 0:
        return
    var ms: int = int(base_ms * _strength_scale())
    if ms <= 0:
        return
    Input.vibrate_handheld(ms)


func _strength_scale() -> float:
    match _strength:
        0:
            return 0.0
        1:
            return 1.0
        2:
            return 1.6
        _:
            return 1.0


func _on_flip(_p: Dictionary) -> void:
    _vibrate(_FLIP_MS)


func _on_landed(_p: Dictionary) -> void:
    _vibrate(_LAND_MS)


func _on_death(_p: Dictionary) -> void:
    _vibrate(_DEATH_MS)


func _on_modifier(_p: Dictionary) -> void:
    _vibrate(_MOD_MS)
