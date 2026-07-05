## GameplayConfig
##
## Three-layer lookup for every tunable gameplay value.
##   1. Remote Config override      (if activated)
##   2. game_config.tres defaults   (build-time)
##   3. Hardcoded safe fallback     (last resort)
##
## Nothing gameplay-affecting should live outside this system.
## See docs/15_M0_ADDENDA.md §A5.
class_name GameplayConfig
extends RefCounted

const _KEY_PREFIX := "gameplay."

# Hardcoded safe fallbacks. Real defaults come from game_config.json.
const _HARDCODED_FALLBACK := {
    "player_base_speed":               420.0,
    "gravity_magnitude":               1600.0,
    "terminal_velocity":                1800.0,
    "tap_flip_cooldown_ms":              80,
    "invulnerability_after_continue_s":  1.5,
    "modifier_default_duration_s":       20.0,
    "modifier_min_gap_s":                 8.0,
    "score_distance_per_point":           4.0,
    "world_chunk_width":               2000.0,
    "world_stream_ahead_chunks":            3,
    "world_stream_behind_chunks":           1,
    "camera_smoothing_speed":             5.0,
    "camera_look_ahead_x":              200.0,
    "obstacle_spacing_min":             800.0,
    "obstacle_spacing_max":            1400.0,
    "obstacle_first_spawn_x":          1500.0,
    "obstacle_spawn_horizon_x":        2500.0,
    "obstacle_despawn_distance_behind": 1500.0,
    "run_restart_tap_cooldown_ms":       500,
}

const _BUILD_DEFAULTS_PATH := "res://data/config/game_config.json"

static var _build_defaults: Dictionary = {}
static var _remote_config: Object = null
static var _loaded: bool = false


static func attach(remote_config: Object) -> void:
    _remote_config = remote_config
    if not _loaded:
        _load_defaults()


static func get_float(key: String, fallback: float = NAN) -> float:
    if _remote_config != null and _remote_config.is_activated():
        var v: Variant = _remote_config.get_float(_KEY_PREFIX + key, NAN)
        if not is_nan(v):
            return v
    if _build_defaults.has(key):
        return float(_build_defaults[key])
    if _HARDCODED_FALLBACK.has(key):
        return float(_HARDCODED_FALLBACK[key])
    return fallback


static func get_int(key: String, fallback: int = 0) -> int:
    if _remote_config != null and _remote_config.is_activated():
        var v: Variant = _remote_config.get_int(_KEY_PREFIX + key, -2147483648)
        if v != -2147483648:
            return v
    if _build_defaults.has(key):
        return int(_build_defaults[key])
    if _HARDCODED_FALLBACK.has(key):
        return int(_HARDCODED_FALLBACK[key])
    return fallback


static func snapshot() -> Dictionary:
    var out: Dictionary = _HARDCODED_FALLBACK.duplicate()
    for k in _build_defaults.keys():
        out[k] = _build_defaults[k]
    return out


static func _load_defaults() -> void:
    _loaded = true
    var f := FileAccess.open(_BUILD_DEFAULTS_PATH, FileAccess.READ)
    if f == null:
        return
    var parsed: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    if parsed is Dictionary:
        _build_defaults = parsed
