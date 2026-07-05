## Log
##
## Structured, level-based logger with static state so it can be called from
## any script scope -- including `class_name` scripts and RefCounted helpers
## where Godot 4.7's parser resolves the identifier to the class type.
##
## Levels: TRACE(0) < DEBUG(1) < INFO(2) < WARN(3) < ERROR(4)
##
## Sinks:
##   - stdout (always)
##   - ring buffer in memory (last 500 lines, for crash reports)
##
## In M4 we attach a Crashlytics sink for ERROR-level messages.
class_name Log
extends RefCounted

enum Level { TRACE = 0, DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }

const MAX_RING := 500

static var _level: int = Level.INFO
static var _ring: Array[String] = []
static var _initialized: bool = false


static func _ensure_init() -> void:
    if _initialized:
        return
    _initialized = true
    _level = Level.DEBUG if OS.is_debug_build() else Level.INFO


static func set_level(level: int) -> void:
    _ensure_init()
    _level = clamp(level, Level.TRACE, Level.ERROR)


static func trace(tag: String, msg: String) -> void:
    _emit(Level.TRACE, tag, msg)


static func debug(tag: String, msg: String) -> void:
    _emit(Level.DEBUG, tag, msg)


static func info(tag: String, msg: String) -> void:
    _emit(Level.INFO, tag, msg)


static func warn(tag: String, msg: String) -> void:
    _emit(Level.WARN, tag, msg)


static func error(tag: String, msg: String) -> void:
    _emit(Level.ERROR, tag, msg)


## Returns the last N lines, useful for crash-report bundles.
static func snapshot(n: int = 100) -> Array[String]:
    _ensure_init()
    var start: int = maxi(0, _ring.size() - n)
    return _ring.slice(start, _ring.size())


static func _emit(level: int, tag: String, msg: String) -> void:
    _ensure_init()
    if level < _level:
        return
    var line: String = "[%s] %s | %s | %s" % [_level_name(level), _timestamp(), tag, msg]
    _ring.append(line)
    if _ring.size() > MAX_RING:
        _ring.pop_front()
    # The single allowed print() in the whole codebase (see scripts/check_forbidden.py).
    print(line)


static func _level_name(level: int) -> String:
    match level:
        Level.TRACE: return "TRACE"
        Level.DEBUG: return "DEBUG"
        Level.INFO:  return "INFO "
        Level.WARN:  return "WARN "
        Level.ERROR: return "ERROR"
        _:           return "?"


static func _timestamp() -> String:
    var t: Dictionary = Time.get_time_dict_from_system()
    return "%02d:%02d:%02d" % [t.hour, t.minute, t.second]
