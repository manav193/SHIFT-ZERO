## IAnalyticsService
##
## Analytics provider abstraction. Ships live from day one.
## See docs/15_M0_ADDENDA.md §A1.
class_name IAnalyticsService
extends RefCounted


func init(_consent: Dictionary) -> void:
    pass


func set_user_property(_key: String, _value: Variant) -> void:
    pass


func log_event(_name: String, _params: Dictionary = {}) -> void:
    pass


func flush() -> void:
    pass


func set_consent(_consent: Dictionary) -> void:
    pass
