## ProgressionContent
##
## Daily missions, achievements, rewards, and statistics helpers.
extends RefCounted

const ProgressionRules := preload("res://src/core/progression_rules.gd")
const SkinCatalog := preload("res://src/core/skin_catalog.gd")


static func today_key() -> String:
    var d := Time.get_date_dict_from_system()
    return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]


static func default_stats() -> Dictionary:
    return {
        "total_runs": 0,
        "total_deaths": 0,
        "best_distance": 0,
        "best_score": 0,
        "total_play_time_s": 0,
        "gravity_flips": 0,
        "obstacles_avoided": 0,
        "birds_avoided": 0,
        "coins_collected": 0,
        "powerups_collected": 0,
        "highest_run_level": 1,
    }


static func ensure_progression(progression: Dictionary) -> Dictionary:
    if not progression.has("player_xp"):
        progression["player_xp"] = 0
    if not progression.has("player_level"):
        progression["player_level"] = ProgressionRules.level_for_total_xp(int(progression.get("player_xp", 0)))
    if not progression.has("daily"):
        progression["daily"] = {"last_refresh_date": "", "missions": []}
    if not progression.has("achievements_unlocked"):
        progression["achievements_unlocked"] = []
    if not progression.has("achievement_rewards_claimed"):
        progression["achievement_rewards_claimed"] = []
    if not progression.has("player_stats"):
        progression["player_stats"] = default_stats()
    else:
        var defaults := default_stats()
        var stats: Dictionary = progression["player_stats"]
        for key in defaults.keys():
            if not stats.has(key):
                stats[key] = defaults[key]
        progression["player_stats"] = stats
    return progression


static func generate_daily(date_key: String) -> Dictionary:
    var seed := int(date_key.replace("-", ""))
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    var pool := _mission_pool()
    var missions: Array = []
    var used: Dictionary = {}
    while missions.size() < 3:
        var index := rng.randi_range(0, pool.size() - 1)
        if used.has(index):
            continue
        used[index] = true
        var base: Dictionary = pool[index].duplicate(true)
        base["id"] = "%s_%s" % [date_key, str(base.type)]
        base["progress"] = 0
        base["completed"] = false
        base["claimed"] = false
        missions.append(base)
    return {"last_refresh_date": date_key, "missions": missions}


static func refresh_daily_if_needed(progression: Dictionary, date_key: String = today_key()) -> Dictionary:
    progression = ensure_progression(progression)
    var daily: Dictionary = progression.get("daily", {})
    if str(daily.get("last_refresh_date", "")) != date_key or not (daily.get("missions", []) is Array) or daily.get("missions", []).is_empty():
        progression["daily"] = generate_daily(date_key)
    return progression


static func update_daily_progress(progression: Dictionary, counters: Dictionary) -> Dictionary:
    progression = ensure_progression(progression)
    var daily: Dictionary = progression["daily"]
    if not (daily.get("missions", []) is Array) or daily.get("missions", []).is_empty():
        progression = refresh_daily_if_needed(progression)
        daily = progression["daily"]
    var missions: Array = daily.get("missions", [])
    for i in missions.size():
        var mission: Dictionary = missions[i]
        var value := int(counters.get(str(mission.get("type", "")), 0))
        mission["progress"] = mini(int(mission.get("target", 0)), maxf(int(mission.get("progress", 0)), value))
        mission["completed"] = int(mission.progress) >= int(mission.target)
        missions[i] = mission
    daily["missions"] = missions
    progression["daily"] = daily
    return progression


static func claim_daily(progression: Dictionary, mission_id: String) -> Dictionary:
    progression = ensure_progression(progression)
    var daily: Dictionary = progression["daily"]
    if not (daily.get("missions", []) is Array) or daily.get("missions", []).is_empty():
        progression = refresh_daily_if_needed(progression)
        daily = progression["daily"]
    var missions: Array = daily.get("missions", [])
    for i in missions.size():
        var mission: Dictionary = missions[i]
        if str(mission.get("id", "")) == mission_id and bool(mission.get("completed", false)) and not bool(mission.get("claimed", false)):
            mission["claimed"] = true
            progression = apply_reward(progression, mission.get("reward", {}))
            missions[i] = mission
            break
    daily["missions"] = missions
    progression["daily"] = daily
    return progression


static func achievements() -> Array:
    return [
        {"id": "first_run", "title": "First Run", "desc": "Complete one run.", "type": "total_runs", "target": 1, "reward": {"coins": 25, "xp": 50}},
        {"id": "first_coin", "title": "First Coin", "desc": "Collect one coin.", "type": "coins_collected", "target": 1, "reward": {"coins": 25, "xp": 50}},
        {"id": "coins_100", "title": "100 Coins", "desc": "Collect 100 coins total.", "type": "coins_collected", "target": 100, "reward": {"coins": 100, "xp": 100}},
        {"id": "coins_500", "title": "500 Coins", "desc": "Collect 500 coins total.", "type": "coins_collected", "target": 500, "reward": {"coins": 250, "xp": 250}},
        {"id": "coins_1000", "title": "1000 Coins", "desc": "Collect 1000 coins total.", "type": "coins_collected", "target": 1000, "reward": {"coins": 500, "xp": 500}},
        {"id": "level_5", "title": "Reach Level 5", "desc": "Reach player level 5.", "type": "player_level", "target": 5, "reward": {"coins": 300, "xp": 300}},
        {"id": "level_10", "title": "Reach Level 10", "desc": "Reach player level 10.", "type": "player_level", "target": 10, "reward": {"coins": 800, "xp": 800}},
        {"id": "distance_5000", "title": "Reach 5000m", "desc": "Reach 5000m in a run.", "type": "best_distance", "target": 5000, "reward": {"coins": 400, "xp": 400}},
        {"id": "distance_10000", "title": "Reach 10000m", "desc": "Reach 10000m in a run.", "type": "best_distance", "target": 10000, "reward": {"coins": 1000, "xp": 1000}},
        {"id": "skins_5", "title": "Unlock 5 Skins", "desc": "Own 5 skins.", "type": "skins_owned", "target": 5, "reward": {"coins": 350, "xp": 350}},
        {"id": "skins_all", "title": "Unlock All Skins", "desc": "Own every skin.", "type": "skins_owned", "target": SkinCatalog.all().size(), "reward": {"coins": 1500, "xp": 1500}},
        {"id": "all_powerups", "title": "Every Powerup", "desc": "Collect 3 powerups total.", "type": "powerups_collected", "target": 3, "reward": {"coins": 250, "xp": 250}},
        {"id": "survive_10m", "title": "Survive 10 Minutes", "desc": "Play for 10 minutes total.", "type": "total_play_time_s", "target": 600, "reward": {"coins": 1000, "xp": 1000}},
    ]


static func update_achievements(progression: Dictionary) -> Dictionary:
    progression = ensure_progression(progression)
    var unlocked: Array = progression.get("achievements_unlocked", [])
    for achievement in achievements():
        var id := str(achievement.id)
        if unlocked.has(id):
            continue
        if achievement_progress(progression, achievement) >= int(achievement.target):
            unlocked.append(id)
    progression["achievements_unlocked"] = unlocked
    return progression


static func claim_achievement(progression: Dictionary, achievement_id: String) -> Dictionary:
    progression = update_achievements(progression)
    var unlocked: Array = progression.get("achievements_unlocked", [])
    var claimed: Array = progression.get("achievement_rewards_claimed", [])
    if not unlocked.has(achievement_id) or claimed.has(achievement_id):
        return progression
    for achievement in achievements():
        if str(achievement.id) == achievement_id:
            progression = apply_reward(progression, achievement.reward)
            claimed.append(achievement_id)
            break
    progression["achievement_rewards_claimed"] = claimed
    return progression


static func achievement_progress(progression: Dictionary, achievement: Dictionary) -> int:
    var stats: Dictionary = progression.get("player_stats", {})
    var kind := str(achievement.type)
    match kind:
        "player_level":
            return int(progression.get("player_level", 1))
        "skins_owned":
            return (progression.get("purchased_skins", []) as Array).size()
        _:
            return int(stats.get(kind, 0))


static func apply_reward(progression: Dictionary, reward: Dictionary) -> Dictionary:
    progression = ensure_progression(progression)
    progression["total_coins"] = int(progression.get("total_coins", 0)) + int(reward.get("coins", 0))
    var xp := int(progression.get("player_xp", 0)) + int(reward.get("xp", 0))
    progression["player_xp"] = xp
    progression["player_level"] = ProgressionRules.level_for_total_xp(xp)
    return progression


static func daily_counters(stats: Dictionary, run: Dictionary, progression: Dictionary) -> Dictionary:
    return {
        "coins": int(run.get("coins", 0)),
        "distance": int(run.get("distance_m", 0)),
        "runs": int(stats.get("total_runs", 0)),
        "run_level": int(run.get("highest_run_level", 1)),
        "powerups": int(run.get("powerups", 0)),
        "flips": int(run.get("flips", 0)),
        "birds": int(run.get("birds_avoided", 0)),
        "player_level": int(progression.get("player_level", 1)),
    }


static func _mission_pool() -> Array:
    return [
        {"type": "coins", "title": "Collect 25 coins", "target": 25, "reward": {"coins": 75, "xp": 100}},
        {"type": "distance", "title": "Reach 750m", "target": 750, "reward": {"coins": 100, "xp": 100}},
        {"type": "runs", "title": "Complete 3 runs", "target": 3, "reward": {"coins": 80, "xp": 120}},
        {"type": "run_level", "title": "Reach Run Level 3", "target": 3, "reward": {"coins": 125, "xp": 150}},
        {"type": "powerups", "title": "Collect 3 powerups", "target": 3, "reward": {"coins": 120, "xp": 160}},
        {"type": "flips", "title": "Flip gravity 40 times", "target": 40, "reward": {"coins": 90, "xp": 100}},
        {"type": "birds", "title": "Avoid 5 birds", "target": 5, "reward": {"coins": 140, "xp": 180}},
        {"type": "player_level", "title": "Reach Player Level 5", "target": 5, "reward": {"coins": 200, "xp": 250}},
    ]
