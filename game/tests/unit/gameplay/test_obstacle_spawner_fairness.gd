## ObstacleSpawner -- fair-pattern gap enforcement.
##
## The `_apply_fair_min_gap` computation is pure and testable without
## instantiating scenes. We instantiate an ObstacleSpawner via load()
## so we can call the private method on a bare Node2D.
extends "res://addons/gut/test.gd"

const ObstacleSpawner := preload("res://src/gameplay/obstacles/obstacle_spawner.gd")


func _make() -> ObstacleSpawner:
    var s := ObstacleSpawner.new()
    # Configure the tunables that _apply_fair_min_gap uses.
    s._base_speed = 500.0
    s._fair_min_flip_time_s = 0.6
    s._fair_min_flip_gap = 800.0
    return s


func test_no_flip_returns_raw_gap():
    var s := _make()
    s._last_safe_side = "floor"
    var g := s._apply_fair_min_gap({"safe_side": "floor"}, 500.0)
    assert_almost_eq(g, 500.0, 0.001)


func test_either_neighbour_returns_raw_gap():
    var s := _make()
    s._last_safe_side = "either"
    var g := s._apply_fair_min_gap({"safe_side": "floor"}, 400.0)
    assert_almost_eq(g, 400.0, 0.001)


func test_flip_enforces_fair_min_gap():
    var s := _make()
    s._last_safe_side = "floor"
    # 500 * 0.6 = 300; floor is max(300, 800) = 800; raw=200 -> 800.
    var g := s._apply_fair_min_gap({"safe_side": "ceiling"}, 200.0)
    assert_almost_eq(g, 800.0, 0.001)


func test_flip_keeps_larger_raw_gap():
    var s := _make()
    s._last_safe_side = "ceiling"
    var g := s._apply_fair_min_gap({"safe_side": "floor"}, 1600.0)
    assert_almost_eq(g, 1600.0, 0.001)


func test_min_spawn_x_blocks_late_obstacles_early():
    var s := _make()
    s._last_safe_side = "either"
    var fair := s._is_fair({"safe_side": "either", "min_spawn_x": 4500.0}, 2000.0)
    assert_false(fair)


func test_min_spawn_x_allows_late_obstacles_after_gate():
    var s := _make()
    s._last_safe_side = "either"
    var fair := s._is_fair({"safe_side": "either", "min_spawn_x": 4500.0}, 5000.0)
    assert_true(fair)


func test_scale_ramps_with_spawn_distance():
    var s := _make()
    s._rng = RandomNumberGenerator.new()
    s._rng.seed = 7
    s._difficulty_scale_distance = 10000.0
    var type := {
        "scale_min": Vector2(1.0, 1.0),
        "scale_max": Vector2(1.8, 1.4),
    }
    var early := s._scale_for(type, 0.0)
    assert_almost_eq(early.x, 1.0, 0.001)
    assert_almost_eq(early.y, 1.0, 0.001)
    var late := s._scale_for(type, 10000.0)
    assert_between(late.x, 1.0, 1.8)
    assert_between(late.y, 1.0, 1.4)
