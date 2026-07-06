## ProgressionContent tests.
extends "res://addons/gut/test.gd"

const ProgressionContent := preload("res://src/core/progression_content.gd")


func test_daily_generation_is_three_for_date():
    var daily: Dictionary = ProgressionContent.generate_daily("2026-07-05")
    assert_eq((daily.missions as Array).size(), 3)
    assert_eq(daily.last_refresh_date, "2026-07-05")


func test_daily_progress_and_claim_reward():
    var progression := ProgressionContent.refresh_daily_if_needed({}, "2026-07-05")
    var missions: Array = progression.daily.missions
    var first: Dictionary = missions[0]
    var counters := {str(first.type): int(first.target)}
    progression = ProgressionContent.update_daily_progress(progression, counters)
    assert_true(bool(progression.daily.missions[0].completed))
    progression = ProgressionContent.claim_daily(progression, str(first.id))
    assert_true(bool(progression.daily.missions[0].claimed))
    assert_gt(int(progression.total_coins), 0)
    assert_gt(int(progression.player_xp), 0)


func test_achievement_unlock_and_claim_reward():
    var progression := ProgressionContent.ensure_progression({})
    var stats: Dictionary = progression.player_stats
    stats["total_runs"] = 1
    progression["player_stats"] = stats
    progression = ProgressionContent.update_achievements(progression)
    assert_true((progression.achievements_unlocked as Array).has("first_run"))
    progression = ProgressionContent.claim_achievement(progression, "first_run")
    assert_true((progression.achievement_rewards_claimed as Array).has("first_run"))
    assert_gt(int(progression.total_coins), 0)


func test_stats_defaults_include_tracked_fields():
    var stats := ProgressionContent.default_stats()
    assert_true(stats.has("total_runs"))
    assert_true(stats.has("birds_avoided"))
    assert_true(stats.has("highest_run_level"))
