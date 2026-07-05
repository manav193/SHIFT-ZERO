## Config
##
## Read-only view over build-time configuration + game version.
## Values here are the fallback layer under Remote Config for any tunable value.
extends Node

const _CONFIG_PATH := "res://data/config/game_config.json"
const _VERSION_PATH := "res://data/config/game_version.json"

var _config: Dictionary = {}
var _version: Dictionary = {}


func _ready() -> void:
    _config = _load_json(_CONFIG_PATH, {
        "target_fps": 60,
        "physics_fps": 60,
        "boot_timeout_ms": 800,
    })
    _version = _load_json(_VERSION_PATH, {
        "major": 0, "minor": 1, "patch": 0,
        "pre_release": "m0", "build": "dev",
    })
    Log.info("Config", "version=%s" % version_string())


func get_value(key: String, default: Variant = null) -> Variant:
    return _config.get(key, default)


func version_string() -> String:
    var v := "%d.%d.%d" % [_version.major, _version.minor, _version.patch]
    if _version.pre_release != "":
        v += "-" + str(_version.pre_release)
    if _version.build != "":
        v += "+" + str(_version.build)
    return v


func version_code() -> int:
    return int(_version.major) * 10000 + int(_version.minor) * 100 + int(_version.patch)


func _load_json(path: String, fallback: Dictionary) -> Dictionary:
    if not FileAccess.file_exists(path):
        Log.warn("Config", "missing %s, using fallback" % path)
        return fallback
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        Log.error("Config", "failed to open %s" % path)
        return fallback
    var text := f.get_as_text()
    f.close()
    var parsed: Variant = JSON.parse_string(text)
    if parsed is Dictionary:
        return parsed
    Log.warn("Config", "invalid JSON in %s" % path)
    return fallback
