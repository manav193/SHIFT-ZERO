## Contract tests for the accessibility settings schema.
extends "res://addons/gut/test.gd"

const InMemorySettingsService := preload("res://src/services/settings/in_memory_settings_service.gd")


func test_default_settings_include_all_a11y_keys():
    var s := InMemorySettingsService.new()
    var cur := s.load_settings()
    for key in [
        "color_palette_id",
        "visual_effects_level",
        "ui_scale",
        "reduced_screen_shake",
        "reduced_particles",
        "battery_30fps",
        "haptics_enabled",
        "haptics_strength",
        "audio_master",
        "audio_music",
        "audio_sfx",
        "audio_ui",
    ]:
        assert_true(cur.has(key), "settings should include '%s'" % key)


func test_setting_a_value_updates_it():
    var s := InMemorySettingsService.new()
    s.set_value("color_palette_id", "deuteranopia")
    assert_eq(s.get_value("color_palette_id"), "deuteranopia")


func test_visual_effects_level_range():
    var s := InMemorySettingsService.new()
    s.set_value("visual_effects_level", 0)
    assert_eq(s.get_value("visual_effects_level"), 0)
