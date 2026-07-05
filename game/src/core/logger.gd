## Logger
##
## Structured, level-based logger. Autoloaded FIRST so every other autoload
## can log during its own init.
##
## Levels: TRACE(0) < DEBUG(1) < INFO(2) < WARN(3) < ERROR(4)
##
## Sinks (attached at boot):
##   - stdout (always)
##   - ring buffer in memory (last 500 lines, for crash reports)
##
## In M4 we attach a Crashlytics sink for ERROR-level messages.
extends Node

enum Level { TRACE = 0, DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }

const MAX_RING := 500

var _level: int = Level.INFO
var _ring: Array[String] = []


func _ready() -> void:
    _level = Level.DEBUG if OS.is_debug_build() else Level.INFO
    info("Logger", "ready. level=%s build=%s" % [_level_name(_level), _build_tag()])


func set_level(level: int) -> void:
    _level = clamp(level, Level.TRACE, Level.ERROR)


func trace(tag: String, msg: String) -> void:
    _emit(Level.TRACE, tag, msg)


func debug(tag: String, msg: String) -> void:
    _emit(Level.DEBUG, tag, msg)


func info(tag: String, msg: String) -> void:
    _emit(Level.INFO, tag, msg)


func warn(tag: String, msg: String) -> void:
    _emit(Level.WARN, tag, msg)


func error(tag: String, msg: String) -> void:
    _emit(Level.ERROR, tag, msg)


## Returns the last N lines, useful for crash-report bundles.
func snapshot(n: int = 100) -> Array[String]:
    var start := maxi(0, _ring.size() - n)
    return _ring.slice(start, _ring.size())


func _emit(level: int, tag: String, msg: String) -> void:
    if level < _level:
        return
    var line := "[%s] %s | %s | %s" % [_level_name(level), _timestamp(), tag, msg]
    _ring.append(line)
    if _ring.size() > MAX_RING:
        _ring.pop_front()
    # The single allowed print() in the whole codebase (see scripts/check_forbidden.py).
    print(line)


func _level_name(level: int) -> String:
    match level:
        Level.TRACE: return "TRACE"
        Level.DEBUG: return "DEBUG"
        Level.INFO:  return "INFO "
        Level.WARN:  return "WARN "
        Level.ERROR: return "ERROR"
        _:           return "?"


func _timestamp() -> String:
    var t := Time.get_time_dict_from_system()
    return "%02d:%02d:%02d" % [t.hour, t.minute, t.second]


func _build_tag() -> String:
    return "debug" if OS.is_debug_build() else "release"
