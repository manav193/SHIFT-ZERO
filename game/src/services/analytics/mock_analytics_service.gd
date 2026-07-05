## MockAnalyticsService
##
## Test double — records every call for assertion.
class_name MockAnalyticsService
extends "res://src/services/analytics/i_analytics_service.gd"

var events: Array = []
var user_properties: Dictionary = {}
var consent: Dictionary = {}


func init(c: Dictionary) -> void:
    consent = c.duplicate()


func set_user_property(key: String, value: Variant) -> void:
    user_properties[key] = value


func log_event(name: String, params: Dictionary = {}) -> void:
    events.append({"name": name, "params": params.duplicate(true)})


func set_consent(c: Dictionary) -> void:
    consent = c.duplicate()


func clear() -> void:
    events.clear()
    user_properties.clear()
