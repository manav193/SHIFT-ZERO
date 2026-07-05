## SkinCatalog
##
## Procedural player skin data. Visuals are built from Godot 2D nodes by
## SkinModel; save data stores only purchased/equipped ids.
extends RefCounted

const CLASSIC := "classic_runner"

const SKINS := [
    {"id": "classic_runner", "name": "Classic Runner", "cost": 0, "shape": "runner", "idle": "run", "trail_style": "dash", "player": Color(0.0, 0.941, 1.0, 1.0), "accent": Color(1.0, 1.0, 1.0, 1.0), "trail": Color(0.0, 0.941, 1.0, 0.65), "flash": Color(0.0, 0.941, 1.0, 1.0), "land": Color(1.0, 0.169, 0.839, 1.0), "death": Color(1.0, 0.271, 0.325, 1.0), "trail_width": 12.0, "flip_amount": 34, "land_amount": 18, "death_amount": 90},
    {"id": "cube", "name": "Cube", "cost": 250, "shape": "cube", "idle": "tilt", "trail_style": "blocks", "player": Color(0.0, 0.38, 1.0, 1.0), "accent": Color(0.35, 0.85, 1.0, 1.0), "trail": Color(0.0, 0.62, 1.0, 0.72), "flash": Color(0.35, 0.85, 1.0, 1.0), "land": Color(0.0, 0.62, 1.0, 1.0), "death": Color(0.2, 0.6, 1.0, 1.0), "trail_width": 15.0, "flip_amount": 24, "land_amount": 28, "death_amount": 80},
    {"id": "robot", "name": "Robot", "cost": 500, "shape": "robot", "idle": "servo", "trail_style": "sparks", "player": Color(0.62, 0.7, 0.78, 1.0), "accent": Color(1.0, 0.933, 0.0, 1.0), "trail": Color(1.0, 0.933, 0.0, 0.7), "flash": Color(1.0, 0.95, 0.45, 1.0), "land": Color(0.85, 0.9, 1.0, 1.0), "death": Color(1.0, 0.62, 0.08, 1.0), "trail_width": 8.0, "flip_amount": 42, "land_amount": 20, "death_amount": 95},
    {"id": "ninja", "name": "Ninja", "cost": 800, "shape": "ninja", "idle": "stealth", "trail_style": "slash", "player": Color(0.04, 0.045, 0.07, 1.0), "accent": Color(1.0, 0.169, 0.839, 1.0), "trail": Color(1.0, 0.169, 0.839, 0.62), "flash": Color(1.0, 0.62, 0.95, 1.0), "land": Color(0.7, 0.1, 1.0, 1.0), "death": Color(1.0, 0.2, 0.7, 1.0), "trail_width": 5.0, "flip_amount": 18, "land_amount": 12, "death_amount": 70},
    {"id": "alien", "name": "Alien", "cost": 1200, "shape": "alien", "idle": "bob", "trail_style": "bubbles", "player": Color(0.15, 0.95, 0.4, 1.0), "accent": Color(0.0, 0.18, 0.12, 1.0), "trail": Color(0.2, 1.0, 0.55, 0.62), "flash": Color(0.55, 1.0, 0.72, 1.0), "land": Color(0.0, 0.9, 0.45, 1.0), "death": Color(0.0, 0.75, 0.3, 1.0), "trail_width": 10.0, "flip_amount": 38, "land_amount": 16, "death_amount": 105},
    {"id": "ufo", "name": "UFO", "cost": 1800, "shape": "ufo", "idle": "hover", "trail_style": "beam", "player": Color(0.72, 0.78, 0.88, 1.0), "accent": Color(0.0, 0.941, 1.0, 1.0), "trail": Color(0.0, 0.941, 1.0, 0.48), "flash": Color(0.85, 0.95, 1.0, 1.0), "land": Color(0.0, 0.941, 1.0, 1.0), "death": Color(0.75, 0.45, 1.0, 1.0), "trail_width": 20.0, "flip_amount": 46, "land_amount": 10, "death_amount": 86},
    {"id": "rocket", "name": "Rocket", "cost": 2500, "shape": "rocket", "idle": "thrust", "trail_style": "flame", "player": Color(1.0, 0.18, 0.2, 1.0), "accent": Color(1.0, 0.92, 0.26, 1.0), "trail": Color(1.0, 0.45, 0.08, 0.72), "flash": Color(1.0, 0.94, 0.45, 1.0), "land": Color(1.0, 0.62, 0.08, 1.0), "death": Color(1.0, 0.08, 0.12, 1.0), "trail_width": 18.0, "flip_amount": 52, "land_amount": 30, "death_amount": 120},
    {"id": "spider", "name": "Spider", "cost": 3200, "shape": "spider", "idle": "crawl", "trail_style": "web", "player": Color(0.12, 0.08, 0.16, 1.0), "accent": Color(0.75, 0.45, 1.0, 1.0), "trail": Color(0.72, 0.72, 0.86, 0.58), "flash": Color(0.75, 0.45, 1.0, 1.0), "land": Color(0.72, 0.72, 0.86, 1.0), "death": Color(0.55, 0.2, 0.9, 1.0), "trail_width": 6.0, "flip_amount": 26, "land_amount": 24, "death_amount": 92},
    {"id": "crystal", "name": "Crystal", "cost": 4000, "shape": "crystal", "idle": "shimmer", "trail_style": "shards", "player": Color(0.42, 0.92, 1.0, 1.0), "accent": Color(1.0, 1.0, 1.0, 1.0), "trail": Color(0.65, 0.95, 1.0, 0.68), "flash": Color(0.9, 1.0, 1.0, 1.0), "land": Color(0.65, 0.95, 1.0, 1.0), "death": Color(0.4, 0.75, 1.0, 1.0), "trail_width": 9.0, "flip_amount": 44, "land_amount": 34, "death_amount": 130},
    {"id": "ghost", "name": "Ghost", "cost": 5200, "shape": "ghost", "idle": "float", "trail_style": "mist", "player": Color(0.88, 0.96, 1.0, 0.92), "accent": Color(0.42, 0.24, 0.95, 1.0), "trail": Color(0.8, 0.9, 1.0, 0.45), "flash": Color(0.85, 0.75, 1.0, 1.0), "land": Color(0.8, 0.9, 1.0, 0.9), "death": Color(0.75, 0.45, 1.0, 1.0), "trail_width": 22.0, "flip_amount": 30, "land_amount": 8, "death_amount": 76},
    {"id": "dragon", "name": "Dragon", "cost": 6500, "shape": "dragon", "idle": "wing", "trail_style": "ember", "player": Color(0.0, 0.72, 0.36, 1.0), "accent": Color(1.0, 0.22, 0.08, 1.0), "trail": Color(1.0, 0.22, 0.08, 0.68), "flash": Color(1.0, 0.45, 0.16, 1.0), "land": Color(0.0, 0.9, 0.45, 1.0), "death": Color(1.0, 0.2, 0.05, 1.0), "trail_width": 14.0, "flip_amount": 58, "land_amount": 28, "death_amount": 140},
    {"id": "cyber_core", "name": "Cyber Core", "cost": 8000, "shape": "core", "idle": "pulse", "trail_style": "circuit", "player": Color(0.04, 0.08, 0.16, 1.0), "accent": Color(0.0, 0.941, 1.0, 1.0), "trail": Color(0.0, 0.941, 1.0, 0.78), "flash": Color(1.0, 0.169, 0.839, 1.0), "land": Color(0.0, 0.941, 1.0, 1.0), "death": Color(1.0, 0.169, 0.839, 1.0), "trail_width": 11.0, "flip_amount": 64, "land_amount": 32, "death_amount": 150},
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
