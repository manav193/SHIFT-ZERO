## Contract tests for the Remote Config abstraction.
extends "res://addons/gut/test.gd"

const StaticRemoteConfigService := preload("res://src/services/remote_config/static_remote_config_service.gd")


func test_defaults_load_and_read():
    var rc := StaticRemoteConfigService.new()
    rc.init()
    # Values live in data/config/remote_config_defaults.json
    var speed := rc.get_float("gameplay.player_base_speed", 0.0)
    assert_gt(speed, 0.0)


func test_fetch_and_activate_marks_activated():
    var rc := StaticRemoteConfigService.new()
    rc.init()
    var result := rc.fetch_and_activate(1.0)
    assert_true(result.ok)
    assert_true(rc.is_activated())


func test_missing_key_returns_default():
    var rc := StaticRemoteConfigService.new()
    rc.init()
    assert_eq(rc.get_string("does.not.exist", "fallback"), "fallback")
    assert_eq(rc.get_int("does.not.exist", 7), 7)
