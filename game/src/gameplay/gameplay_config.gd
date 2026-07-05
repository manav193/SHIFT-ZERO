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
    "modifier_default_duration_s":        6.0,
    "modifier_min_gap_s":                 8.0,
    "modifier_max_gap_s":                15.0,
    "modifier_first_activation_s":       12.0,
    "modifier_low_gravity_scale":         0.5,
    "modifier_slow_motion_scale":         0.55,
    "modifier_speed_burst_scale":         1.55,
    "score_distance_per_point":           4.0,
    "world_chunk_width":               2000.0,
    "world_stream_ahead_chunks":            3,
    "world_stream_behind_chunks":           1,
    "camera_smoothing_speed":             5.0,
    "camera_look_ahead_x":              200.0,
    "camera_shake_decay_per_s":           1.4,
    "camera_shake_max_offset_px":        80.0,
    "camera_impact_trauma":              0.65,
    "camera_design_view_height":       2400.0,
    "obstacle_spacing_min":             800.0,
    "obstacle_spacing_max":            1400.0,
    "obstacle_first_spawn_x":          1500.0,
    "obstacle_spawn_horizon_x":        2500.0,
    "obstacle_despawn_distance_behind": 1500.0,
    "obstacle_difficulty_scale_distance": 12000.0,
    "run_restart_tap_cooldown_ms":       500,
    "difficulty_speed_mult_start":       1.0,
    "difficulty_speed_mult_max":         2.0,
    "difficulty_speed_growth_per_s":     0.02,
    "difficulty_spacing_shrink_per_s":   0.008,
    "difficulty_spacing_min_mult":       0.55,
    "fair_min_flip_gap":               1000.0,
    "fair_min_flip_time_s":               0.55,
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
