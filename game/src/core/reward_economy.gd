## RewardEconomy
##
## Shared reward application, login calendar, spin, chests, boosters, and
## fragments. Keeps currency/XP/chest/booster logic in one progression helper.
class_name RewardEconomy
extends RefCounted

const ProgressionRules := preload("res://src/core/progression_rules.gd")

const BOOSTERS := ["shield", "magnet", "double_score", "coin_booster", "xp_booster"]
const CHESTS := ["common", "rare", "epic", "legendary"]
const FRAGMENT_SKINS := {"dragon": 80, "phoenix": 100}


static func today_key() -> String:
    var d := Time.get_date_dict_from_system()
    return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]


static func ensure_progression(progression: Dictionary) -> Dictionary:
    if not progression.has("daily_login"):
        progression["daily_login"] = {"streak": 0, "last_claim_date": ""}
    if not progression.has("lucky_spin"):
        progression["lucky_spin"] = {"last_spin_date": "", "free_available": true}
    if not progression.has("chest_inventory"):
        progression["chest_inventory"] = {"common": 0, "rare": 0, "epic": 0, "legendary": 0}
    else:
        _ensure_keys(progression["chest_inventory"], {"common": 0, "rare": 0, "epic": 0, "legendary": 0})
    if not progression.has("booster_inventory"):
        progression["booster_inventory"] = {"shield": 0, "magnet": 0, "double_score": 0, "coin_booster": 0, "xp_booster": 0}
    else:
        _ensure_keys(progression["booster_inventory"], {"shield": 0, "magnet": 0, "double_score": 0, "coin_booster": 0, "xp_booster": 0})
    if not progression.has("equipped_boosters"):
        progression["equipped_boosters"] = []
    if not progression.has("skin_fragments"):
        progression["skin_fragments"] = {"dragon": 0, "phoenix": 0}
    else:
        _ensure_keys(progression["skin_fragments"], {"dragon": 0, "phoenix": 0})
    if not progression.has("pending_rewards"):
        progression["pending_rewards"] = []
    return progression


static func login_calendar() -> Array:
    return [
        {"day": 1, "title": "100 Coins", "reward": {"coins": 100}},
        {"day": 2, "title": "150 Coins", "reward": {"coins": 150}},
        {"day": 3, "title": "Small Chest", "reward": {"chests": {"common": 1}}},
        {"day": 4, "title": "250 XP", "reward": {"xp": 250}},
        {"day": 5, "title": "Rare Chest", "reward": {"chests": {"rare": 1}}},
        {"day": 6, "title": "Lucky Spin", "reward": {"spins": 1}},
        {"day": 7, "title": "Epic Chest", "reward": {"chests": {"epic": 1}}},
    ]


static func current_login_day(progression: Dictionary) -> int:
    progression = ensure_progression(progression)
    return int(progression.daily_login.get("streak", 0)) % 7 + 1


static func can_claim_login(progression: Dictionary, date_key: String = today_key()) -> bool:
    progression = ensure_progression(progression)
    return str(progression.daily_login.get("last_claim_date", "")) != date_key


static func claim_login(progression: Dictionary, date_key: String = today_key()) -> Dictionary:
    progression = ensure_progression(progression)
    if not can_claim_login(progression, date_key):
        return progression
    var day := current_login_day(progression)
    var entry: Dictionary = login_calendar()[day - 1]
    progression = apply_reward(progression, entry.reward)
    progression["daily_login"] = {
        "streak": day % 7,
        "last_claim_date": date_key,
    }
    return _append_pending(progression, "Daily Login", entry.reward)


static func spin_rewards() -> Array:
    return [
        {"title": "120 Coins", "weight": 24, "reward": {"coins": 120}},
        {"title": "250 XP", "weight": 18, "reward": {"xp": 250}},
        {"title": "Small Chest", "weight": 12, "reward": {"chests": {"common": 1}}},
        {"title": "Rare Chest", "weight": 8, "reward": {"chests": {"rare": 1}}},
        {"title": "Epic Chest", "weight": 3, "reward": {"chests": {"epic": 1}}},
        {"title": "Shield", "weight": 10, "reward": {"boosters": {"shield": 1}}},
        {"title": "Magnet", "weight": 9, "reward": {"boosters": {"magnet": 1}}},
        {"title": "Double Score", "weight": 7, "reward": {"boosters": {"double_score": 1}}},
        {"title": "Coin Booster", "weight": 5, "reward": {"boosters": {"coin_booster": 1}}},
        {"title": "XP Booster", "weight": 5, "reward": {"boosters": {"xp_booster": 1}}},
        {"title": "Skin Fragments", "weight": 6, "reward": {"fragments": {"dragon": 3, "phoenix": 2}}},
    ]


static func can_spin(progression: Dictionary, date_key: String = today_key()) -> bool:
    progression = ensure_progression(progression)
    return str(progression.lucky_spin.get("last_spin_date", "")) != date_key or int(progression.get("bonus_spins", 0)) > 0


static func claim_spin(progression: Dictionary, date_key: String = today_key(), seed: int = 0) -> Dictionary:
    progression = ensure_progression(progression)
    if not can_spin(progression, date_key):
        return progression
    var rewards := spin_rewards()
    var picked := _weighted_pick(rewards, seed + int(date_key.replace("-", "")))
    progression = apply_reward(progression, picked.reward)
    if int(progression.get("bonus_spins", 0)) > 0:
        progression["bonus_spins"] = int(progression.get("bonus_spins", 0)) - 1
    else:
        progression["lucky_spin"] = {"last_spin_date": date_key, "free_available": false}
    return _append_pending(progression, "Lucky Spin: %s" % str(picked.title), picked.reward)


static func chest_reward(chest_id: String, seed: int = 0) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = hash(chest_id) + seed
    match chest_id:
        "rare":
            return {"coins": rng.randi_range(220, 420), "xp": rng.randi_range(250, 520), "boosters": {_random_booster(rng): 1}, "fragments": {"dragon": rng.randi_range(2, 5)}}
        "epic":
            return {"coins": rng.randi_range(500, 900), "xp": rng.randi_range(650, 1100), "boosters": {_random_booster(rng): 2}, "fragments": {"dragon": rng.randi_range(5, 9), "phoenix": rng.randi_range(3, 7)}}
        "legendary":
            return {"coins": rng.randi_range(1200, 2200), "xp": rng.randi_range(1400, 2400), "boosters": {_random_booster(rng): 3}, "fragments": {"dragon": rng.randi_range(10, 18), "phoenix": rng.randi_range(8, 16)}}
        _:
            return {"coins": rng.randi_range(80, 180), "xp": rng.randi_range(80, 180), "boosters": {_random_booster(rng): 1}}


static func open_chest(progression: Dictionary, chest_id: String, seed: int = 0) -> Dictionary:
    progression = ensure_progression(progression)
    var inv: Dictionary = progression.get("chest_inventory", {})
    if int(inv.get(chest_id, 0)) <= 0:
        return progression
    inv[chest_id] = int(inv.get(chest_id, 0)) - 1
    progression["chest_inventory"] = inv
    var reward := chest_reward(chest_id, seed)
    progression = apply_reward(progression, reward)
    return _append_pending(progression, "%s Chest" % chest_id.capitalize(), reward)


static func set_booster_equipped(progression: Dictionary, booster_id: String, equipped: bool) -> Dictionary:
    progression = ensure_progression(progression)
    if not (booster_id in BOOSTERS):
        return progression
    var equipped_list: Array = progression.get("equipped_boosters", [])
    if equipped and int(progression.booster_inventory.get(booster_id, 0)) > 0 and not equipped_list.has(booster_id):
        equipped_list.append(booster_id)
    elif not equipped:
        equipped_list.erase(booster_id)
    progression["equipped_boosters"] = equipped_list
    return progression


static func consume_equipped_boosters(progression: Dictionary) -> Dictionary:
    progression = ensure_progression(progression)
    var equipped_list: Array = progression.get("equipped_boosters", [])
    var inv: Dictionary = progression.get("booster_inventory", {})
    var active: Array = []
    for booster_id in equipped_list:
        var id := str(booster_id)
        if int(inv.get(id, 0)) <= 0:
            continue
        inv[id] = int(inv.get(id, 0)) - 1
        active.append(id)
    progression["booster_inventory"] = inv
    progression["active_run_boosters"] = active
    progression["equipped_boosters"] = []
    return progression


static func fragment_requirement(skin_id: String) -> int:
    return int(FRAGMENT_SKINS.get(skin_id, 0))


static func apply_reward(progression: Dictionary, reward: Dictionary) -> Dictionary:
    progression = ensure_progression(progression)
    progression["total_coins"] = int(progression.get("total_coins", 0)) + int(reward.get("coins", 0))
    var xp := int(progression.get("player_xp", 0)) + int(reward.get("xp", 0))
    progression["player_xp"] = xp
    progression["player_level"] = ProgressionRules.level_for_total_xp(xp)
    if reward.has("chests"):
        _add_dict_counts(progression["chest_inventory"], reward.chests)
    if reward.has("boosters"):
        _add_dict_counts(progression["booster_inventory"], reward.boosters)
    if reward.has("fragments"):
        _add_dict_counts(progression["skin_fragments"], reward.fragments)
    if reward.has("spins"):
        progression["bonus_spins"] = int(progression.get("bonus_spins", 0)) + int(reward.get("spins", 0))
    return progression


static func reward_text(reward: Dictionary) -> String:
    var parts: Array[String] = []
    if int(reward.get("coins", 0)) > 0:
        parts.append("%d coins" % int(reward.coins))
    if int(reward.get("xp", 0)) > 0:
        parts.append("%d XP" % int(reward.xp))
    for key in ["chests", "boosters", "fragments"]:
        if reward.has(key):
            var values: Dictionary = reward[key]
            for id in values.keys():
                parts.append("%d %s" % [int(values[id]), str(id).replace("_", " ")])
    if int(reward.get("spins", 0)) > 0:
        parts.append("%d spin" % int(reward.spins))
    return ", ".join(parts)


static func _weighted_pick(entries: Array, seed: int) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed
    var total := 0
    for item in entries:
        total += int(item.weight)
    var roll := rng.randi_range(1, maxi(1, total))
    var cursor := 0
    for item in entries:
        cursor += int(item.weight)
        if roll <= cursor:
            return item
    return entries[0]


static func _random_booster(rng: RandomNumberGenerator) -> String:
    return BOOSTERS[rng.randi_range(0, BOOSTERS.size() - 1)]


static func _add_dict_counts(target: Dictionary, add: Dictionary) -> void:
    for key in add.keys():
        target[key] = int(target.get(key, 0)) + int(add[key])


static func _ensure_keys(target: Dictionary, defaults: Dictionary) -> void:
    for key in defaults.keys():
        if not target.has(key):
            target[key] = defaults[key]


static func _append_pending(progression: Dictionary, source: String, reward: Dictionary) -> Dictionary:
    var pending: Array = progression.get("pending_rewards", [])
    pending.append({"source": source, "reward": reward, "t_ms": Time.get_ticks_msec()})
    progression["pending_rewards"] = pending
    return progression
