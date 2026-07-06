## ObstacleSpawner -- fair-pattern gap enforcement.
##
## The `_apply_fair_min_gap` computation is pure and testable without
## instantiating scenes. We instantiate an ObstacleSpawner via load()
## so we can call the private method on a bare Node2D.
extends "res://addons/gut/test.gd"

const ObstacleSpawner := preload("res://src/gameplay/obstacles/obstacle_spawner.gd")


func _make() -> ObstacleSpawner:
    var s := ObstacleSpawner.new()
    autofree(s)
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
    # Easy tier keeps a larger safety window: 800 * 1.15 = 920.
    var g := s._apply_fair_min_gap({"safe_side": "ceiling"}, 200.0)
    assert_almost_eq(g, 920.0, 0.001)


func test_flip_keeps_larger_raw_gap():
    var s := _make()
    s._last_safe_side = "ceiling"
    var g := s._apply_fair_min_gap({"safe_side": "floor"}, 1600.0)
    assert_almost_eq(g, 1600.0, 0.001)


func test_min_spawn_x_blocks_late_obstacles_early():
    var s := _make()
    s._last_safe_side = "either"
    var fair := s._is_fair({"safe_side": "either", "category": "bird", "min_spawn_x": 15000.0}, 2000.0)
    assert_false(fair)


func test_min_spawn_x_allows_late_obstacles_after_gate():
    var s := _make()
    s._last_safe_side = "either"
    var fair := s._is_fair({"safe_side": "either", "category": "bird", "min_spawn_x": 15000.0}, 16000.0)
    assert_true(fair)


func test_easy_tier_blocks_birds_even_if_min_spawn_allows():
    var s := _make()
    var fair := s._is_fair({"safe_side": "either", "category": "bird", "min_spawn_x": 0.0}, 1000.0)
    assert_false(fair)


func test_consecutive_same_obstacle_type_is_not_fair():
    var s := _make()
    s._last_type_id = "floor_spike"
    var fair := s._is_fair({
        "id": "floor_spike",
        "safe_side": "ceiling",
        "category": "ground",
        "min_spawn_x": 0.0,
    }, 6000.0)
    assert_false(fair)


func test_medium_spacing_is_noticeably_tighter_than_easy():
    var s := _make()
    s._spacing_min = 1000.0
    s._spacing_max = 1000.0
    s._rng = RandomNumberGenerator.new()
    s._rng.seed = 11
    var type := {"category": "ground"}
    var easy := s._gap_for(type, 1000.0)
    s._rng.seed = 11
    var medium := s._gap_for(type, 6000.0)
    assert_lt(medium, easy * 0.75)


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


func test_lane_from_y_covers_five_vertical_bands():
    var s := _make()
    assert_eq(s._lane_from_y(240.0), "upper")
    assert_eq(s._lane_from_y(720.0), "mid_upper")
    assert_eq(s._lane_from_y(1200.0), "center")
    assert_eq(s._lane_from_y(1660.0), "mid_lower")
    assert_eq(s._lane_from_y(2140.0), "lower")


func test_registry_covers_middle_lanes():
    var s := _make()
    s._load_registry()
    var lanes := {}
    for t in s._types:
        lanes[s._lane_for(t)] = true
    assert_true(lanes.has("upper"))
    assert_true(lanes.has("mid_upper"))
    assert_true(lanes.has("center"))
    assert_true(lanes.has("mid_lower"))
    assert_true(lanes.has("lower"))


func test_same_lane_is_not_fair_when_alternative_lane_exists():
    var s := _make()
    s._types = [
        {"id": "center_a", "weight": 1.0, "safe_side": "either", "category": "ground", "lane": "center", "min_spawn_x": 0.0},
        {"id": "mid_lower_a", "weight": 1.0, "safe_side": "either", "category": "ground", "lane": "mid_lower", "min_spawn_x": 0.0},
    ]
    s._last_lane = "center"
    assert_false(s._is_fair(s._types[0], 6000.0))
    assert_true(s._is_fair(s._types[1], 6000.0))


func test_spawn_selection_does_not_leave_persistent_middle_blind_zone():
    var s := _make()
    s._rng = RandomNumberGenerator.new()
    s._rng.seed = 12345
    s._load_registry()
    var lanes := {}
    var last_lane := ""
    for i in 30:
        var picked := s._pick_type_fair(18000.0 + float(i) * 900.0)
        assert_false(picked.is_empty())
        var lane := s._lane_for(picked)
        assert_ne(lane, last_lane)
        lanes[lane] = true
        s._last_safe_side = str(picked.get("safe_side", "either"))
        s._last_type_id = str(picked.get("id", ""))
        s._remember_lane(lane)
        last_lane = lane
    assert_true(lanes.has("mid_upper"))
    assert_true(lanes.has("center"))
    assert_true(lanes.has("mid_lower"))
