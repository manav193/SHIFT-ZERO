## Statistics
extends Control

const ProgressionContent := preload("res://src/core/progression_content.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _list: GridContainer = $Root/Scroll/List


func _ready() -> void:
    _back_btn.pressed.connect(_on_back_pressed)
    _reload()


func _on_back_pressed() -> void:
    var result: Result = SceneRouter.push(_MAIN_MENU_PATH)
    if not result.ok:
        push_error("Statistics", "back failed: %s" % result.error)


func _reload() -> void:
    for child in _list.get_children():
        child.queue_free()
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    save.mutate(func(state: Dictionary) -> Dictionary:
        state["progression"] = ProgressionContent.ensure_progression(state.get("progression", {}))
        return state)
    var loaded: Result = save.load_state()
    if not loaded.ok:
        return
    var state: Dictionary = loaded.value
    var progression: Dictionary = state.get("progression", {})
    var stats: Dictionary = progression.get("player_stats", ProgressionContent.default_stats())
    var rows := [
        ["Total Runs", stats.total_runs],
        ["Total Deaths", stats.total_deaths],
        ["Best Distance", "%d m" % int(stats.best_distance)],
        ["Best Score", stats.best_score],
        ["Total Coins", progression.get("total_coins", 0)],
        ["Total XP", progression.get("player_xp", 0)],
        ["Total Play Time", "%d:%02d" % [int(stats.total_play_time_s) / 60, int(stats.total_play_time_s) % 60]],
        ["Gravity Flips", stats.gravity_flips],
        ["Obstacles Avoided", stats.obstacles_avoided],
        ["Birds Avoided", stats.birds_avoided],
        ["Coins Collected", stats.coins_collected],
        ["Powerups Collected", stats.powerups_collected],
        ["Highest Run Level", stats.highest_run_level],
    ]
    for row in rows:
        _add_cell(str(row[0]), true)
        _add_cell(str(row[1]), false)


func _add_cell(text: String, is_label: bool) -> void:
    var label := Label.new()
    label.custom_minimum_size = Vector2(260, 58)
    label.text = text
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 28 if is_label else 30)
    label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.9, 1.0) if is_label else Color(1.0, 0.933, 0.0, 1.0))
    _list.add_child(label)
