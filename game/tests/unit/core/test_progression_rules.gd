## ProgressionRules tests.
extends "res://addons/gut/test.gd"

const ProgressionRules := preload("res://src/core/progression_rules.gd")


func test_required_xp_curve_grows_by_level():
    assert_eq(ProgressionRules.required_xp_for_level(1), 160)
    assert_eq(ProgressionRules.required_xp_for_level(2), 240)
    assert_gt(ProgressionRules.required_xp_for_level(5), ProgressionRules.required_xp_for_level(4))


func test_total_xp_maps_to_level_and_progress():
    assert_eq(ProgressionRules.level_for_total_xp(0), 1)
    assert_eq(ProgressionRules.level_for_total_xp(159), 1)
    assert_eq(ProgressionRules.level_for_total_xp(160), 2)
    assert_eq(ProgressionRules.xp_into_level(175), 15)


func test_run_xp_sources_stack():
    assert_eq(ProgressionRules.run_xp(120, 3, 2, 90), 12 + 15 + 50 + 9)


func test_run_level_by_distance():
    assert_eq(ProgressionRules.run_level_for_distance_m(0).level, 1)
    assert_eq(ProgressionRules.run_level_for_distance_m(500).level, 2)
    assert_eq(ProgressionRules.run_level_for_distance_m(1500).name, "Hard")
    assert_eq(ProgressionRules.run_level_for_distance_m(3000).name, "Extreme")
    assert_eq(ProgressionRules.run_level_for_distance_m(6000).name, "SHIFT ZERO")


func test_prestige_rank_continues_after_level_50():
    assert_eq(ProgressionRules.prestige_rank_for_level(50), "LEVEL 50")
    assert_eq(ProgressionRules.prestige_rank_for_level(51), "Bronze I")
    assert_eq(ProgressionRules.prestige_rank_for_level(56), "Silver I")
    assert_eq(ProgressionRules.prestige_rank_for_level(78), "SHIFT ZERO")
