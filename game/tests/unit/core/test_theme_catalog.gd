## ThemeCatalog tests.
extends "res://addons/gut/test.gd"

const ThemeCatalog := preload("res://src/core/theme_catalog.gd")


func test_theme_for_distance_uses_progression_bands():
    assert_eq(ThemeCatalog.theme_for_distance(0.0, ["neon_city"]).id, "neon_city")
    assert_eq(ThemeCatalog.theme_for_distance(2000.0, ["neon_city"]).id, "desert")
    assert_eq(ThemeCatalog.theme_for_distance(5000.0, ["neon_city"]).id, "snow")
    assert_eq(ThemeCatalog.theme_for_distance(9000.0, ["neon_city"]).id, "forest")
    assert_eq(ThemeCatalog.theme_for_distance(13000.0, ["neon_city"]).id, "volcano")
    assert_eq(ThemeCatalog.theme_for_distance(18000.0, ["neon_city"]).id, "space")


func test_default_unlock_includes_neon_city():
    var progression := ThemeCatalog.ensure_progression({})
    assert_true(progression.unlocked_themes.has("neon_city"))


func test_distance_and_level_unlock_themes():
    var progression := {
        "player_level": 8,
        "player_stats": {"best_distance": 5000},
        "achievements_unlocked": [],
    }
    progression = ThemeCatalog.unlock_available(progression)
    assert_true(progression.unlocked_themes.has("desert"))
    assert_true(progression.unlocked_themes.has("snow"))
    assert_true(progression.unlocked_themes.has("cyber_grid"))
