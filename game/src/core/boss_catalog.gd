## BossCatalog
##
## Static boss encounter definitions, scheduling, rewards, and progression
## helpers. Runtime visuals live in BossEventController.
class_name BossCatalog
extends RefCounted

const RewardEconomy := preload("res://src/core/reward_economy.gd")

const SKY_HUNTER := "sky_hunter"
const LASER_WALL := "laser_wall"
const METEOR_STORM := "meteor_storm"
const GRAVITY_STORM := "gravity_storm"


static func all() -> Array:
    return [
        {
            "id": SKY_HUNTER,
            "name": "Sky Hunter",
            "distance_m": 5000,
            "duration_s": 24.0,
            "reward": {"coins": 180, "xp": 320, "rare_chest_chance": 0.08, "fragments": {"dragon": 2}},
            "color": Color(0.0, 0.941, 1.0, 1.0),
        },
        {
            "id": LASER_WALL,
            "name": "Laser Wall",
            "distance_m": 10000,
            "duration_s": 26.0,
            "reward": {"coins": 240, "xp": 420, "rare_chest_chance": 0.10, "fragments": {"dragon": 3}},
            "color": Color(1.0, 0.169, 0.839, 1.0),
        },
        {
            "id": METEOR_STORM,
            "name": "Meteor Storm",
            "distance_m": 15000,
            "duration_s": 30.0,
            "reward": {"coins": 320, "xp": 560, "rare_chest_chance": 0.12, "fragments": {"dragon": 4, "phoenix": 2}},
            "color": Color(1.0, 0.42, 0.04, 1.0),
        },
        {
            "id": GRAVITY_STORM,
            "name": "Gravity Storm",
            "distance_m": 20000,
            "duration_s": 32.0,
            "reward": {"coins": 420, "xp": 720, "rare_chest_chance": 0.15, "fragments": {"dragon": 5, "phoenix": 3}},
            "color": Color(0.58, 0.38, 1.0, 1.0),
        },
    ]


static func by_id(id: String) -> Dictionary:
    for boss in all():
        if str(boss.id) == id:
            return boss
    return all()[0]


static func boss_for_distance(distance_m: int, defeated_ids: Array = []) -> Dictionary:
    if distance_m >= 25000:
        var pool := defeated_ids.duplicate()
        if pool.is_empty():
            pool = [SKY_HUNTER, LASER_WALL, METEOR_STORM, GRAVITY_STORM]
        var index: int = int(distance_m / 5000) % pool.size()
        return by_id(str(pool[index]))
    var chosen: Dictionary = {}
    for boss in all():
        if distance_m >= int(boss.distance_m):
            chosen = boss
    return chosen


static func next_scheduled_boss(distance_m: int, seen_ids: Array) -> Dictionary:
    for boss in all():
        if distance_m >= int(boss.distance_m) and not seen_ids.has(str(boss.id)):
            return boss
    if distance_m >= 25000:
        return boss_for_distance(distance_m, seen_ids)
    return {}


static func default_stats_patch() -> Dictionary:
    return {
        "bosses_seen": 0,
        "bosses_defeated": 0,
        "longest_boss_survival_s": 0,
        "boss_no_damage_defeats": 0,
    }


static func ensure_progression(progression: Dictionary) -> Dictionary:
    if not progression.has("bosses_seen"):
        progression["bosses_seen"] = []
    if not progression.has("bosses_defeated"):
        progression["bosses_defeated"] = []
    if not progression.has("rare_chests"):
        progression["rare_chests"] = 0
    progression = RewardEconomy.ensure_progression(progression)
    var stats: Dictionary = progression.get("player_stats", {})
    for key in default_stats_patch().keys():
        if not stats.has(key):
            stats[key] = default_stats_patch()[key]
    progression["player_stats"] = stats
    return progression


static func apply_boss_seen(progression: Dictionary, boss_id: String) -> Dictionary:
    progression = ensure_progression(progression)
    var seen: Array = progression.get("bosses_seen", [])
    if not seen.has(boss_id):
        seen.append(boss_id)
    progression["bosses_seen"] = seen
    var stats: Dictionary = progression.get("player_stats", {})
    stats["bosses_seen"] = maxi(int(stats.get("bosses_seen", 0)), seen.size())
    progression["player_stats"] = stats
    return progression


static func apply_boss_defeat(progression: Dictionary, boss_id: String, survived_s: int, no_damage: bool) -> Dictionary:
    progression = ensure_progression(progression)
    var defeated: Array = progression.get("bosses_defeated", [])
    if not defeated.has(boss_id):
        defeated.append(boss_id)
    progression["bosses_defeated"] = defeated
    var boss := by_id(boss_id)
    var reward: Dictionary = boss.get("reward", {})
    progression = RewardEconomy.apply_reward(progression, reward)
    if float(reward.get("rare_chest_chance", 0.0)) >= 0.1:
        progression["rare_chests"] = int(progression.get("rare_chests", 0)) + 1
    var stats: Dictionary = progression.get("player_stats", {})
    stats["bosses_defeated"] = maxi(int(stats.get("bosses_defeated", 0)), defeated.size())
    stats["longest_boss_survival_s"] = maxi(int(stats.get("longest_boss_survival_s", 0)), survived_s)
    if no_damage:
        stats["boss_no_damage_defeats"] = int(stats.get("boss_no_damage_defeats", 0)) + 1
    progression["player_stats"] = stats
    return progression


static func boss_achievements() -> Array:
    return [
        {"id": "first_boss", "title": "First Boss", "desc": "See your first boss.", "type": "bosses_seen", "target": 1, "reward": {"coins": 150, "xp": 200}},
        {"id": "defeat_sky_hunter", "title": "Defeat Giant Bird", "desc": "Survive Sky Hunter.", "type": "boss_defeated_id", "target": SKY_HUNTER, "reward": {"coins": 300, "xp": 400}},
        {"id": "defeat_all_bosses", "title": "Defeat All Bosses", "desc": "Survive every boss type.", "type": "bosses_defeated", "target": all().size(), "reward": {"coins": 1200, "xp": 1600}},
        {"id": "survive_5_bosses", "title": "Survive 5 Bosses", "desc": "Win five boss events.", "type": "bosses_defeated", "target": 5, "reward": {"coins": 800, "xp": 1000}},
        {"id": "boss_no_damage", "title": "Untouched", "desc": "Survive a boss without damage.", "type": "boss_no_damage_defeats", "target": 1, "reward": {"coins": 500, "xp": 700}},
    ]
