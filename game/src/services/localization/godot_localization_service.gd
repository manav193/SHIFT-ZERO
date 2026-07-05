## GodotLocalizationService
##
## M0 implementation — delegates to Godot's built-in TranslationServer.
## CSV loading + plural rules land in M2/M5 as translations arrive.
class_name GodotLocalizationService
extends "res://src/services/localization/i_localization_service.gd"


func set_locale(locale: String) -> void:
    if locale == "system":
        TranslationServer.set_locale(OS.get_locale())
    else:
        TranslationServer.set_locale(locale)
    print("Localization", "locale=%s" % TranslationServer.get_locale())


func current_locale() -> String:
    return TranslationServer.get_locale()


func t(key: String, params: Dictionary = {}) -> String:
    var s := tr(key)
    for k in params.keys():
        s = s.replace("{" + str(k) + "}", str(params[k]))
    return s
