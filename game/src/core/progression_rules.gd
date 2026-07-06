## ProgressionRules
##
## Pure progression math shared by HUD/menu/tests.
extends RefCounted


static func required_xp_for_level(level: int) -> int:
    var l := maxi(1, level)
    return 100 + l * 50 + l * l * 10


static func level_for_total_xp(total_xp: int) -> int:
    var xp := maxi(0, total_xp)
    var level := 1
    while xp >= required_xp_for_level(level):
        xp -= required_xp_for_level(level)
        level += 1
    return level


static func xp_into_level(total_xp: int) -> int:
    var xp := maxi(0, total_xp)
    var level := 1
    while xp >= required_xp_for_level(level):
        xp -= required_xp_for_level(level)
        level += 1
    return xp


static func prestige_rank_for_level(level: int) -> String:
    if level <= 50:
        return "LEVEL %d" % maxi(1, level)
    var ranks := [
        "Bronze I", "Bronze II", "Bronze III", "Bronze IV", "Bronze V",
        "Silver I", "Silver II", "Silver III", "Silver IV", "Silver V",
        "Gold I", "Gold II", "Gold III", "Gold IV", "Gold V",
        "Platinum I", "Platinum II", "Platinum III", "Platinum IV", "Platinum V",
        "Diamond I", "Diamond II", "Diamond III", "Diamond IV", "Diamond V",
        "Master", "Grandmaster", "SHIFT ZERO",
    ]
    var index := mini(level - 51, ranks.size() - 1)
    return ranks[index]


static func prestige_rank_for_xp(total_xp: int) -> String:
    return prestige_rank_for_level(level_for_total_xp(total_xp))


static func run_xp(distance_m: int, coins: int, powerups: int, score: int) -> int:
    return int(distance_m / 10) + coins * 5 + powerups * 25 + int(score / 10)


static func run_level_for_distance_m(distance_m: int) -> Dictionary:
    if distance_m < 500:
        return {"level": 1, "name": "Easy"}
    if distance_m < 1500:
        return {"level": 2, "name": "Medium"}
    if distance_m < 3000:
        return {"level": 3, "name": "Hard"}
    if distance_m < 6000:
        return {"level": 4, "name": "Extreme"}
    return {"level": 5, "name": "SHIFT ZERO"}
