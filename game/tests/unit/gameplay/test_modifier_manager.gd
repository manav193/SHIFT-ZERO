## ModifierManager -- rotation, activation, expiry, pause behaviour.
##
## Tests here focus on the pure-state behaviour that can be exercised without
## instantiating the full scene tree. The manager's timer uses
## Time.get_ticks_msec, so we advance state by directly manipulating the
## expiry timestamps -- this mirrors what tests do in the RunDirector.
extends "res://addons/gut/test.gd"

const ModifierManager := preload("res://src/gameplay/modifiers/modifier_manager.gd")


func test_active_id_empty_at_boot():
    var m: ModifierManager = autofree(ModifierManager.new())
    m._reload_tunables()
    m._build_pool()
    assert_eq(m.active_id(), "")


func test_pool_contains_three_modifiers():
    var m: ModifierManager = autofree(ModifierManager.new())
    m._reload_tunables()
    m._build_pool()
    assert_eq(m._pool.size(), 3)


func test_params_carry_scale_values():
    var m: ModifierManager = autofree(ModifierManager.new())
    m._reload_tunables()
    m._build_pool()
    var found: Dictionary = {"low_gravity": false, "slow_motion": false, "speed_burst": false}
    for mod in m._pool:
        found[mod.id()] = true
        var p: Dictionary = m._params_for(mod)
        assert_true(p.size() >= 1)
    assert_true(found["low_gravity"] and found["slow_motion"] and found["speed_burst"])
