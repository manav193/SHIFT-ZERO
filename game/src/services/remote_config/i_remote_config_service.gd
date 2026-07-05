## IRemoteConfigService
##
## Remote Config provider abstraction. Ships live from day one with
## build-time defaults. Firebase implementation lands in M4.
## See docs/15_M0_ADDENDA.md §A2.
class_name IRemoteConfigService
extends RefCounted

signal activated


func init() -> void:
    pass


func fetch_and_activate(_timeout_s: float = 1.0) -> Result:
    return Result.ok_(false)


func get_bool(_key: String, default: bool = false) -> bool:
    return default


func get_int(_key: String, default: int = 0) -> int:
    return default


func get_float(_key: String, default: float = 0.0) -> float:
    return default


func get_string(_key: String, default: String = "") -> String:
    return default


func get_json(_key: String, default: Dictionary = {}) -> Dictionary:
    return default


func is_activated() -> bool:
    return false
