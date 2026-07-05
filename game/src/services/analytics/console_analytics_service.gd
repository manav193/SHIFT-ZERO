## ConsoleAnalyticsService
##
## Default M0 implementation — emits structured JSON lines to stdout.
## Provides real telemetry visibility long before Firebase is wired (M4).
class_name ConsoleAnalyticsService
extends "res://src/services/analytics/i_analytics_service.gd"

var _consent: Dictionary = {"analytics": false}
var _user_properties: Dictionary = {}


func init(consent: Dictionary) -> void:
    _consent = consent.duplicate()
    print("Analytics", "console analytics ready. consent=%s" % consent)


func set_user_property(key: String, value: Variant) -> void:
    _user_properties[key] = value


func log_event(name: String, params: Dictionary = {}) -> void:
    if not _consent.get("analytics", false):
        return
    var payload := {
        "event": name,
        "params": params,
        "user_props": _user_properties,
        "t": TimeSource.wall_time_unix(),
    }
    print("Analytics", JSON.stringify(payload))


func flush() -> void:
    pass


func set_consent(consent: Dictionary) -> void:
    _consent = consent.duplicate()
    print("Analytics", "consent updated: %s" % consent)
