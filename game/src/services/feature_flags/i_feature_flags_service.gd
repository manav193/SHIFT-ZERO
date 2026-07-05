## IFeatureFlagsService
##
## Feature flag precedence (see docs/13_VERSIONING_STRATEGY.md §6):
##     local override (dev)  >  Remote Config  >  build-time default
class_name IFeatureFlagsService
extends RefCounted


func is_enabled(_flag: String) -> bool:
    return false


func set_local_override(_flag: String, _enabled: bool) -> void:
    pass


func clear_local_overrides() -> void:
    pass


func list_flags() -> Dictionary:
    return {}
