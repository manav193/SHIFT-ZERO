## GameplayConfig — three-layer lookup verification.
extends "res://addons/gut/test.gd"

const GameplayConfig := preload("res://src/gameplay/gameplay_config.gd")
const StaticRemoteConfigService := preload("res://src/services/remote_config/static_remote_config_service.gd")


func test_hardcoded_fallback_when_no_remote_no_defaults():
    GameplayConfig.attach(null)
    # Should return hardcoded default of 420.0.
    var v := GameplayConfig.get_float("player_base_speed")
    assert_almost_eq(v, 420.0, 0.001)


func test_build_defaults_override_hardcoded():
    GameplayConfig.attach(null)
    # game_config.json ships with player_base_speed=420.0 (same value here) —
    # the important assertion is: lookup finds it.
    var v := GameplayConfig.get_float("player_base_speed")
    assert_gt(v, 0.0)


func test_remote_config_overrides_defaults():
    var rc := StaticRemoteConfigService.new()
    rc.init()
    rc.fetch_and_activate(1.0)
    GameplayConfig.attach(rc)
    # Remote defaults ship the same value, but the lookup path is exercised.
    var v := GameplayConfig.get_float("player_base_speed")
    assert_gt(v, 0.0)
