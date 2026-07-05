## Contract tests for IAnalyticsService and MockAnalyticsService.
extends "res://addons/gut/test.gd"

const MockAnalyticsService := preload("res://src/services/analytics/mock_analytics_service.gd")


func test_events_recorded_with_params():
    var a := MockAnalyticsService.new()
    a.init({"analytics": true})
    a.log_event("run_started", {"seed": 42, "difficulty": "normal"})
    a.log_event("player_died", {"score": 128})

    assert_eq(a.events.size(), 2)
    assert_eq(a.events[0].name, "run_started")
    assert_eq(a.events[0].params.seed, 42)
    assert_eq(a.events[1].params.score, 128)


func test_user_properties_are_captured():
    var a := MockAnalyticsService.new()
    a.set_user_property("cohort", "beta")
    assert_eq(a.user_properties.cohort, "beta")


func test_consent_can_be_updated():
    var a := MockAnalyticsService.new()
    a.init({"analytics": false})
    a.set_consent({"analytics": true})
    assert_true(a.consent.analytics)
