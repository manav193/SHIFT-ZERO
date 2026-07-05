## SkinCatalog
##
## Small data table for placeholder player skins.
extends RefCounted

const CLASSIC := "classic"

const SKINS := [
    {
        "id": "classic",
        "name": "Classic",
        "cost": 0,
        "player": Color(0.0, 0.941, 1.0, 1.0),
        "trail": Color(0.0, 0.941, 1.0, 0.65),
        "flash": Color(0.0, 0.941, 1.0, 1.0),
        "death": Color(1.0, 0.271, 0.325, 1.0),
    },
    {
        "id": "neon_blue",
        "name": "Neon Blue",
        "cost": 250,
        "player": Color(0.0, 0.38, 1.0, 1.0),
        "trail": Color(0.0, 0.62, 1.0, 0.7),
        "flash": Color(0.35, 0.85, 1.0, 1.0),
        "death": Color(0.2, 0.6, 1.0, 1.0),
    },
    {
        "id": "neon_pink",
        "name": "Neon Pink",
        "cost": 500,
        "player": Color(1.0, 0.169, 0.839, 1.0),
        "trail": Color(1.0, 0.169, 0.839, 0.7),
        "flash": Color(1.0, 0.62, 0.95, 1.0),
        "death": Color(1.0, 0.2, 0.7, 1.0),
    },
    {
        "id": "emerald",
        "name": "Emerald",
        "cost": 800,
        "player": Color(0.0, 0.9, 0.45, 1.0),
        "trail": Color(0.0, 0.9, 0.45, 0.65),
        "flash": Color(0.55, 1.0, 0.72, 1.0),
        "death": Color(0.0, 0.75, 0.3, 1.0),
    },
    {
        "id": "gold",
        "name": "Gold",
        "cost": 1200,
        "player": Color(1.0, 0.76, 0.05, 1.0),
        "trail": Color(1.0, 0.8, 0.18, 0.72),
        "flash": Color(1.0, 0.94, 0.45, 1.0),
        "death": Color(1.0, 0.62, 0.08, 1.0),
    },
    {
        "id": "crimson",
        "name": "Crimson",
        "cost": 1800,
        "player": Color(1.0, 0.12, 0.18, 1.0),
        "trail": Color(1.0, 0.1, 0.2, 0.65),
        "flash": Color(1.0, 0.45, 0.5, 1.0),
        "death": Color(1.0, 0.08, 0.12, 1.0),
    },
    {
        "id": "cyber",
        "name": "Cyber",
        "cost": 2500,
        "player": Color(0.45, 1.0, 0.1, 1.0),
        "trail": Color(0.0, 0.941, 1.0, 0.72),
        "flash": Color(1.0, 0.169, 0.839, 1.0),
        "death": Color(0.55, 1.0, 0.15, 1.0),
    },
    {
        "id": "void",
        "name": "Void",
        "cost": 4000,
        "player": Color(0.42, 0.24, 0.95, 1.0),
        "trail": Color(0.42, 0.24, 0.95, 0.68),
        "flash": Color(0.85, 0.75, 1.0, 1.0),
        "death": Color(0.75, 0.45, 1.0, 1.0),
    },
]


static func all() -> Array:
    return SKINS


static func by_id(id: String) -> Dictionary:
    for skin in SKINS:
        if str(skin.id) == id:
            return skin
    return SKINS[0]


static func default_unlocked() -> Array[String]:
    return [CLASSIC]
