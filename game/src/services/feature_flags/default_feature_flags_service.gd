## DefaultFeatureFlagsService
##
## Reads build-time defaults from `data/config/feature_flags.json`, layers
## Remote Config on top, and honours in-memory local overrides for DEV builds.
class_name DefaultFeatureFlagsService
extends "res://src/services/feature_flags/i_feature_flags_service.gd"

const DEFAULTS_PATH := "res://data/config/feature_flags.json"

var _build_defaults: Dictionary = {}
var _local_overrides: Dictionary = {}
var _remote_config: Object   # duck-typed IRemoteConfigService


func _init(remote_config: Object = null) -> void:
    _remote_config = remote_config
    var f := FileAccess.open(DEFAULTS_PATH, FileAccess.READ)
    if f != null:
        var parsed: Variant = JSON.parse_string(f.get_as_text())
        f.close()
        if parsed is Dictionary:
            _build_defaults = parsed


func is_enabled(flag: String) -> bool:
    if OS.is_debug_build() and _local_overrides.has(flag):
        return bool(_local_overrides[flag])
    if _remote_config != null and _remote_config.is_activated():
        return _remote_config.get_bool(flag, _build_defaults.get(flag, false))
    return bool(_build_defaults.get(flag, false))


func set_local_override(flag: String, enabled: bool) -> void:
    _local_overrides[flag] = enabled


func clear_local_overrides() -> void:
    _local_overrides.clear()


func list_flags() -> Dictionary:
    return _build_defaults.duplicate()
