## BossCatalog tests.
extends "res://addons/gut/test.gd"

const BossCatalog := preload("res://src/core/boss_catalog.gd")
const ProgressionContent := preload("res://src/core/progression_content.gd")


func test_boss_scheduling_uses_distance_gates():
    assert_true(BossCatalog.next_scheduled_boss(4999, []).is_empty())
    assert_eq(BossCatalog.next_scheduled_boss(5000, []).id, BossCatalog.SKY_HUNTER)
    assert_eq(BossCatalog.next_scheduled_boss(10000, [BossCatalog.SKY_HUNTER]).id, BossCatalog.LASER_WALL)
    assert_eq(BossCatalog.next_scheduled_boss(15000, [BossCatalog.SKY_HUNTER, BossCatalog.LASER_WALL]).id, BossCatalog.METEOR_STORM)
    assert_eq(BossCatalog.next_scheduled_boss(20000, [BossCatalog.SKY_HUNTER, BossCatalog.LASER_WALL, BossCatalog.METEOR_STORM]).id, BossCatalog.GRAVITY_STORM)


func test_apply_boss_seen_tracks_unique_seen_stat():
    var progression := BossCatalog.apply_boss_seen({}, BossCatalog.SKY_HUNTER)
    progression = BossCatalog.apply_boss_seen(progression, BossCatalog.SKY_HUNTER)
    assert_eq((progression.bosses_seen as Array).size(), 1)
    assert_eq(int(progression.player_stats.bosses_seen), 1)


func test_apply_boss_defeat_adds_rewards_and_stats():
    var progression := {
        "total_coins": 0,
        "player_xp": 0,
        "player_level": 1,
        "player_stats": {},
    }
    progression = BossCatalog.apply_boss_defeat(progression, BossCatalog.LASER_WALL, 26, true)
    assert_true((progression.bosses_defeated as Array).has(BossCatalog.LASER_WALL))
    assert_gt(int(progression.total_coins), 0)
    assert_gt(int(progression.player_xp), 0)
    assert_eq(int(progression.player_stats.longest_boss_survival_s), 26)
    assert_eq(int(progression.player_stats.boss_no_damage_defeats), 1)


func test_id_based_boss_achievement_waits_for_matching_boss():
    var progression := ProgressionContent.ensure_progression({})
    progression = BossCatalog.apply_boss_seen(progression, BossCatalog.SKY_HUNTER)
    progression = ProgressionContent.update_achievements(progression)
    assert_false((progression.achievements_unlocked as Array).has("defeat_sky_hunter"))
    progression = BossCatalog.apply_boss_defeat(progression, BossCatalog.SKY_HUNTER, 24, false)
    progression = ProgressionContent.update_achievements(progression)
    assert_true((progression.achievements_unlocked as Array).has("defeat_sky_hunter"))
