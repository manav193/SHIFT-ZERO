## InMemorySettingsService
##
## Default settings implementation for M0. Emits SETTINGS_CHANGED via EventBus.
class_name InMemorySettingsService
extends "res://src/services/settings/i_settings_service.gd"

const Events := preload("res://src/core/events.gd")

var _values: Dictionary


func _init() -> void:
    _values = default_settings()


func load_settings() -> Dictionary:
    return _values.duplicate(true)


func set_value(key: String, value: Variant) -> void:
    var prev: Variant = _values.get(key)
    if prev == value:
        return
    _values[key] = value
    EventBus.emit(Events.SETTINGS_CHANGED, {"key": key, "value": value, "previous": prev})
    # Fan-out to a11y-specific channels so subsystems don't have to filter.
    match key:
        "color_palette_id":
            EventBus.emit(Events.A11Y_PALETTE_CHANGED, {"id": value})
        "visual_effects_level":
            EventBus.emit(Events.A11Y_VFX_LEVEL_CHANGED, {"level": value})
        "haptics_enabled", "haptics_strength":
            EventBus.emit(Events.A11Y_HAPTICS_CHANGED, {
                "enabled": _values.get("haptics_enabled", true),
                "strength": _values.get("haptics_strength", 1),
            })


func get_value(key: String, default: Variant = null) -> Variant:
    return _values.get(key, default)
