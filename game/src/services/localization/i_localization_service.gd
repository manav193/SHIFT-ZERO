## ILocalizationService
##
## Locale + translation lookup. Thin wrapper around Godot's `tr()`
## for now; will grow to handle CSV loading + plural rules.
class_name ILocalizationService
extends RefCounted


func set_locale(_locale: String) -> void:
    pass


func current_locale() -> String:
    return "en"


func t(key: String, _params: Dictionary = {}) -> String:
    return key
