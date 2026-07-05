## TimeSource
##
## Provides three time domains so modifiers like Time-Slow can affect only game_time.
##
##   wall_time — OS wall clock (never scaled)
##   real_time — engine unscaled seconds since boot
##   game_time — scaled by ModifierManager; freezes when paused
class_name TimeSource
extends RefCounted

static var _scale: float = 1.0
static var _game_time: float = 0.0
static var _paused: bool = false


static func advance(delta: float) -> void:
    if _paused:
        return
    _game_time += delta * _scale


static func set_scale(s: float) -> void:
    _scale = maxf(0.0, s)


static func set_paused(p: bool) -> void:
    _paused = p


static func reset() -> void:
    _scale = 1.0
    _game_time = 0.0
    _paused = false


static func game_time() -> float:
    return _game_time


static func real_time() -> float:
    return float(Time.get_ticks_msec()) / 1000.0


static func wall_time_iso() -> String:
    return Time.get_datetime_string_from_system(true, true)


static func wall_time_unix() -> int:
    return Time.get_unix_time_from_system() as int
