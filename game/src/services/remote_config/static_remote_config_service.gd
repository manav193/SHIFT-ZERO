## StaticRemoteConfigService
##
## Loads defaults from `data/config/remote_config_defaults.json`. Acts as if
## Remote Config had activated with the defaults. Fetch is a no-op.
class_name StaticRemoteConfigService
extends "res://src/services/remote_config/i_remote_config_service.gd"

const Events := preload("res://src/core/events.gd")
const DEFAULTS_PATH := "res://data/config/remote_config_defaults.json"

var _values: Dictionary = {}
var _activated: bool = false


func init() -> void:
    var f := FileAccess.open(DEFAULTS_PATH, FileAccess.READ)
    if f == null:
        Logger.warn("RemoteConfig", "no defaults file at %s" % DEFAULTS_PATH)
        _values = {}
        return
    var text := f.get_as_text()
    f.close()
    var parsed: Variant = JSON.parse_string(text)
    _values = parsed if parsed is Dictionary else {}
    Logger.info("RemoteConfig", "loaded %d default keys" % _values.size())


func fetch_and_activate(_timeout_s: float = 1.0) -> Result:
    _activated = true
    activated.emit()
    EventBus.emit(Events.REMOTE_CONFIG_ACTIVATED, {"source": "static_defaults"})
    return Result.ok_(true)


func get_bool(key: String, default: bool = false) -> bool:
    var v: Variant = _values.get(key, default)
    return bool(v) if v != null else default


func get_int(key: String, default: int = 0) -> int:
    var v: Variant = _values.get(key, default)
    return int(v) if v != null else default


func get_float(key: String, default: float = 0.0) -> float:
    var v: Variant = _values.get(key, default)
    return float(v) if v != null else default


func get_string(key: String, default: String = "") -> String:
    var v: Variant = _values.get(key, default)
    return str(v) if v != null else default


func get_json(key: String, default: Dictionary = {}) -> Dictionary:
    var v: Variant = _values.get(key, default)
    return v if v is Dictionary else default


func is_activated() -> bool:
    return _activated
