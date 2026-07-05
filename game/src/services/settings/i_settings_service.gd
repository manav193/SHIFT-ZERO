## ISettingsService
##
## Accessibility + audio + language preferences.
## Schema includes ALL A3 accessibility fields from day one
## (see docs/15_M0_ADDENDA.md §A3).
class_name ISettingsService
extends RefCounted


func load_settings() -> Dictionary:
    return default_settings()


func set_value(_key: String, _value: Variant) -> void:
    pass


func get_value(key: String, default: Variant = null) -> Variant:
    return default_settings().get(key, default)


static func default_settings() -> Dictionary:
    return {
        # accessibility
        "color_palette_id": "default_neon",     # default_neon | deuteranopia | protanopia | tritanopia | high_contrast
        "visual_effects_level": 3,              # 0 (reduce-motion) .. 3 (full)
        "haptics_enabled": true,
        "haptics_strength": 1,                  # 0..2
        # audio
        "audio_master": 1.0,
        "audio_music": 0.8,
        "audio_sfx": 1.0,
        "audio_ui": 0.9,
        # locale
        "locale": "system",
        # gameplay preference
        "orientation": "auto",                  # auto | portrait | landscape
    }
