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
