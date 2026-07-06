## Statistics
extends Control

const ProgressionContent := preload("res://src/core/progression_content.gd")
const ProgressionRules := preload("res://src/core/progression_rules.gd")
const PremiumUI := preload("res://src/presentation/ui/premium_ui.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _list: GridContainer = $Root/Scroll/List


func _ready() -> void:
    var shell := PremiumUI.screen(self, "PROFILE STATS", _on_back_pressed)
    _back_btn = shell.back
    var grid := GridContainer.new()
    grid.columns = 2
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 16)
    grid.add_theme_constant_override("v_separation", 16)
    shell.list.add_child(grid)
    _list = grid
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
    var runs := maxf(1.0, float(stats.get("total_runs", 0)))
    var bosses_seen := maxf(1.0, float(stats.get("bosses_seen", 0)))
    var season: Dictionary = progression.get("season", ProgressionContent.default_season())
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
        ["Longest Combo", stats.get("longest_combo", 0)],
        ["Average Distance", "%d m" % int(float(stats.get("total_distance", 0)) / runs)],
        ["Average Score", int(float(stats.get("total_score", 0)) / runs)],
        ["Boss Success Rate", "%d%%" % int(float(stats.get("bosses_defeated", 0)) / bosses_seen * 100.0)],
        ["Coins Per Run", "%.1f" % (float(stats.get("coins_collected", 0)) / runs)],
        ["Powerups Per Run", "%.1f" % (float(stats.get("powerups_collected", 0)) / runs)],
        ["Total Play Sessions", stats.get("total_play_sessions", 0)],
        ["Highest Prestige", stats.get("highest_prestige", ProgressionRules.prestige_rank_for_level(int(progression.get("player_level", 1))))],
        ["Total Seasons Played", stats.get("total_seasons_played", 1)],
        ["Season Level", season.get("season_level", 1)],
        ["Season XP", season.get("season_xp", 0)],
        ["Season Coins", season.get("season_coins", 0)],
        ["Bosses Seen", stats.get("bosses_seen", 0)],
        ["Bosses Defeated", stats.get("bosses_defeated", 0)],
        ["Longest Boss Survival", "%ds" % int(stats.get("longest_boss_survival_s", 0))],
        ["No-Damage Boss Wins", stats.get("boss_no_damage_defeats", 0)],
        ["Rare Chests", progression.get("rare_chests", 0)],
    ]
    for row in rows:
        _add_stat_card(str(row[0]), str(row[1]))
    PremiumUI.style_tree(_list)


func _add_stat_card(title: String, value: String) -> void:
    var card := PremiumUI.card(Color(0.0, 0.82, 1.0, 1.0), 126)
    var v := VBoxContainer.new()
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    card.add_child(v)
    v.add_child(PremiumUI.label(value, 32, Color(1.0, 0.933, 0.0, 1.0)))
    v.add_child(PremiumUI.label(title.to_upper(), 18, Color(0.72, 0.84, 0.95, 1.0)))
    _list.add_child(card)
