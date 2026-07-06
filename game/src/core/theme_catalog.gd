## ThemeCatalog
##
## Procedural biome definitions and unlock rules. Visual systems consume this
## data; gameplay generation stays unchanged.
class_name ThemeCatalog
extends RefCounted

const NEON_CITY := "neon_city"


static func all() -> Array:
    return [
        {
            "id": NEON_CITY,
            "name": "Neon City",
            "unlock": {"type": "default", "value": 0},
            "sky_top": Color(0.025, 0.035, 0.09, 1.0),
            "sky_bottom": Color(0.06, 0.02, 0.12, 1.0),
            "ground": Color(1.0, 0.169, 0.839, 1.0),
            "obstacles": [Color(1.0, 0.271, 0.325, 1.0), Color(0.0, 0.941, 1.0, 1.0), Color(1.0, 0.933, 0.0, 1.0)],
            "coin": Color(1.0, 0.933, 0.0, 1.0),
            "powerup": Color(0.0, 0.941, 1.0, 1.0),
            "particle": Color(0.0, 0.941, 1.0, 0.85),
            "light": Color(0.72, 0.88, 1.0, 1.0),
            "bands": [Color(0.035, 0.05, 0.12, 1.0), Color(0.055, 0.03, 0.12, 0.85), Color(0.02, 0.11, 0.14, 0.65)],
        },
        {
            "id": "desert",
            "name": "Desert",
            "unlock": {"type": "distance", "value": 2000},
            "sky_top": Color(0.88, 0.48, 0.19, 1.0),
            "sky_bottom": Color(0.98, 0.74, 0.34, 1.0),
            "ground": Color(0.92, 0.55, 0.18, 1.0),
            "obstacles": [Color(0.7, 0.32, 0.12, 1.0), Color(0.98, 0.65, 0.18, 1.0), Color(0.45, 0.22, 0.1, 1.0)],
            "coin": Color(1.0, 0.82, 0.18, 1.0),
            "powerup": Color(0.25, 0.95, 0.85, 1.0),
            "particle": Color(1.0, 0.75, 0.28, 0.8),
            "light": Color(1.0, 0.86, 0.58, 1.0),
            "bands": [Color(0.35, 0.18, 0.08, 0.75), Color(0.56, 0.29, 0.1, 0.6), Color(0.85, 0.5, 0.16, 0.45)],
        },
        {
            "id": "snow",
            "name": "Snow",
            "unlock": {"type": "distance", "value": 5000},
            "sky_top": Color(0.1, 0.19, 0.3, 1.0),
            "sky_bottom": Color(0.46, 0.67, 0.86, 1.0),
            "ground": Color(0.78, 0.93, 1.0, 1.0),
            "obstacles": [Color(0.6, 0.9, 1.0, 1.0), Color(0.35, 0.62, 0.92, 1.0), Color(0.9, 0.98, 1.0, 1.0)],
            "coin": Color(0.82, 0.95, 1.0, 1.0),
            "powerup": Color(0.55, 0.74, 1.0, 1.0),
            "particle": Color(0.86, 0.97, 1.0, 0.9),
            "light": Color(0.82, 0.92, 1.0, 1.0),
            "bands": [Color(0.12, 0.22, 0.34, 0.75), Color(0.3, 0.48, 0.66, 0.55), Color(0.7, 0.85, 0.95, 0.5)],
        },
        {
            "id": "forest",
            "name": "Forest",
            "unlock": {"type": "distance", "value": 9000},
            "sky_top": Color(0.03, 0.16, 0.1, 1.0),
            "sky_bottom": Color(0.18, 0.42, 0.2, 1.0),
            "ground": Color(0.18, 0.62, 0.22, 1.0),
            "obstacles": [Color(0.22, 0.42, 0.13, 1.0), Color(0.42, 0.78, 0.22, 1.0), Color(0.1, 0.32, 0.16, 1.0)],
            "coin": Color(0.82, 1.0, 0.25, 1.0),
            "powerup": Color(0.24, 1.0, 0.54, 1.0),
            "particle": Color(0.35, 1.0, 0.42, 0.8),
            "light": Color(0.76, 1.0, 0.68, 1.0),
            "bands": [Color(0.02, 0.1, 0.06, 0.85), Color(0.06, 0.22, 0.1, 0.65), Color(0.12, 0.36, 0.14, 0.55)],
        },
        {
            "id": "volcano",
            "name": "Volcano",
            "unlock": {"type": "distance", "value": 13000},
            "sky_top": Color(0.08, 0.025, 0.02, 1.0),
            "sky_bottom": Color(0.48, 0.08, 0.02, 1.0),
            "ground": Color(1.0, 0.23, 0.02, 1.0),
            "obstacles": [Color(0.95, 0.08, 0.02, 1.0), Color(1.0, 0.55, 0.02, 1.0), Color(0.18, 0.04, 0.03, 1.0)],
            "coin": Color(1.0, 0.58, 0.08, 1.0),
            "powerup": Color(1.0, 0.18, 0.06, 1.0),
            "particle": Color(1.0, 0.32, 0.02, 0.9),
            "light": Color(1.0, 0.5, 0.25, 1.0),
            "bands": [Color(0.1, 0.02, 0.015, 0.85), Color(0.3, 0.035, 0.015, 0.7), Color(0.65, 0.11, 0.02, 0.55)],
        },
        {
            "id": "space",
            "name": "Space",
            "unlock": {"type": "distance", "value": 18000},
            "sky_top": Color(0.005, 0.005, 0.025, 1.0),
            "sky_bottom": Color(0.03, 0.02, 0.08, 1.0),
            "ground": Color(0.48, 0.34, 1.0, 1.0),
            "obstacles": [Color(0.72, 0.5, 1.0, 1.0), Color(0.2, 0.85, 1.0, 1.0), Color(1.0, 0.6, 0.95, 1.0)],
            "coin": Color(0.75, 0.9, 1.0, 1.0),
            "powerup": Color(0.95, 0.48, 1.0, 1.0),
            "particle": Color(0.72, 0.78, 1.0, 0.9),
            "light": Color(0.7, 0.76, 1.0, 1.0),
            "bands": [Color(0.01, 0.01, 0.05, 0.9), Color(0.04, 0.02, 0.12, 0.65), Color(0.08, 0.08, 0.22, 0.45)],
        },
        {
            "id": "cyber_grid",
            "name": "Cyber Grid",
            "unlock": {"type": "level", "value": 8},
            "sky_top": Color(0.0, 0.025, 0.04, 1.0),
            "sky_bottom": Color(0.0, 0.12, 0.18, 1.0),
            "ground": Color(0.0, 1.0, 0.86, 1.0),
            "obstacles": [Color(0.0, 0.92, 1.0, 1.0), Color(0.2, 1.0, 0.5, 1.0), Color(1.0, 0.08, 0.9, 1.0)],
            "coin": Color(0.2, 1.0, 0.72, 1.0),
            "powerup": Color(1.0, 0.12, 0.9, 1.0),
            "particle": Color(0.0, 1.0, 0.86, 0.9),
            "light": Color(0.62, 1.0, 0.95, 1.0),
            "bands": [Color(0.0, 0.05, 0.08, 0.9), Color(0.0, 0.16, 0.18, 0.65), Color(0.0, 0.32, 0.28, 0.45)],
        },
        {
            "id": "ancient_temple",
            "name": "Ancient Temple",
            "unlock": {"type": "achievement", "value": "distance_5000"},
            "sky_top": Color(0.12, 0.09, 0.05, 1.0),
            "sky_bottom": Color(0.46, 0.34, 0.17, 1.0),
            "ground": Color(0.76, 0.64, 0.36, 1.0),
            "obstacles": [Color(0.5, 0.42, 0.22, 1.0), Color(0.82, 0.72, 0.45, 1.0), Color(0.24, 0.36, 0.22, 1.0)],
            "coin": Color(1.0, 0.78, 0.28, 1.0),
            "powerup": Color(0.35, 1.0, 0.74, 1.0),
            "particle": Color(1.0, 0.78, 0.34, 0.8),
            "light": Color(1.0, 0.84, 0.55, 1.0),
            "bands": [Color(0.12, 0.09, 0.04, 0.85), Color(0.35, 0.25, 0.12, 0.65), Color(0.62, 0.5, 0.28, 0.5)],
        },
    ]


static func by_id(id: String) -> Dictionary:
    for theme in all():
        if str(theme.id) == id:
            return theme
    return all()[0]


static func default_unlocked() -> Array:
    return [NEON_CITY]


static func ensure_progression(progression: Dictionary) -> Dictionary:
    if not progression.has("unlocked_themes"):
        progression["unlocked_themes"] = default_unlocked()
    var unlocked: Array = progression.get("unlocked_themes", default_unlocked())
    if not unlocked.has(NEON_CITY):
        unlocked.append(NEON_CITY)
    progression["unlocked_themes"] = unlocked
    return progression


static func unlocked_theme_ids(progression: Dictionary) -> Array:
    progression = ensure_progression(progression)
    var unlocked: Array = progression.get("unlocked_themes", default_unlocked())
    var out: Array = []
    for id in unlocked:
        if not out.has(str(id)):
            out.append(str(id))
    return out


static func unlock_available(progression: Dictionary) -> Dictionary:
    progression = ensure_progression(progression)
    var unlocked: Array = progression.get("unlocked_themes", default_unlocked())
    for theme in all():
        var id := str(theme.id)
        if unlocked.has(id):
            continue
        if _is_unlocked_by_progress(theme, progression):
            unlocked.append(id)
    progression["unlocked_themes"] = unlocked
    return progression


static func unlock_text(theme: Dictionary) -> String:
    var unlock: Dictionary = theme.get("unlock", {})
    match str(unlock.get("type", "default")):
        "distance":
            return "Reach %dm" % int(unlock.get("value", 0))
        "level":
            return "Reach player level %d" % int(unlock.get("value", 1))
        "achievement":
            return "Unlock achievement"
        _:
            return "Unlocked"


static func theme_for_distance(distance_m: float, unlocked_ids: Array, seed: int = 0) -> Dictionary:
    if distance_m < 2000.0:
        return by_id(NEON_CITY)
    if distance_m < 5000.0:
        return by_id("desert")
    if distance_m < 9000.0:
        return by_id("snow")
    if distance_m < 13000.0:
        return by_id("forest")
    if distance_m < 18000.0:
        return by_id("volcano")
    if distance_m < 25000.0:
        return by_id("space")
    var available := unlocked_ids.duplicate()
    if available.is_empty():
        available = default_unlocked()
    var idx: int = abs(seed + int(distance_m / 2500.0)) % available.size()
    return by_id(str(available[idx]))


static func _is_unlocked_by_progress(theme: Dictionary, progression: Dictionary) -> bool:
    var unlock: Dictionary = theme.get("unlock", {})
    match str(unlock.get("type", "default")):
        "distance":
            var stats: Dictionary = progression.get("player_stats", {})
            return int(stats.get("best_distance", 0)) >= int(unlock.get("value", 0))
        "level":
            return int(progression.get("player_level", 1)) >= int(unlock.get("value", 1))
        "achievement":
            var achievements: Array = progression.get("achievements_unlocked", [])
            return achievements.has(str(unlock.get("value", "")))
        _:
            return true
