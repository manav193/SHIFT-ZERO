## Achievements
extends Control

const ProgressionContent := preload("res://src/core/progression_content.gd")
const PremiumUI := preload("res://src/presentation/ui/premium_ui.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _list: Container = $Root/Scroll/List


func _ready() -> void:
    var shell := PremiumUI.screen(self, "ACHIEVEMENTS", _on_back_pressed)
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
        push_error("Achievements", "back failed: %s" % result.error)


func _reload() -> void:
    for child in _list.get_children():
        child.queue_free()
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    save.mutate(func(state: Dictionary) -> Dictionary:
        state["progression"] = ProgressionContent.update_achievements(state.get("progression", {}))
        return state)
    var loaded: Result = save.load_state()
    if not loaded.ok:
        return
    var progression: Dictionary = loaded.value.get("progression", {})
    for achievement in ProgressionContent.achievements():
        _add_row(progression, achievement)
    PremiumUI.style_tree(_list)


func _add_row(progression: Dictionary, achievement: Dictionary) -> void:
    var unlocked: Array = progression.get("achievements_unlocked", [])
    var claimed: Array = progression.get("achievement_rewards_claimed", [])
    var id := str(achievement.id)
    var progress := ProgressionContent.achievement_progress(progression, achievement)
    var reward: Dictionary = achievement.reward
    var accent := Color(1.0, 0.76, 0.05, 1.0) if unlocked.has(id) else Color(0.28, 0.34, 0.46, 1.0)
    var card := PremiumUI.card(accent, 218)
    card.modulate = Color.WHITE if unlocked.has(id) else Color(0.58, 0.62, 0.72, 0.92)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    card.add_child(v)
    v.add_child(PremiumUI.label("*" if unlocked.has(id) else "LOCKED", 22, accent, HORIZONTAL_ALIGNMENT_LEFT))
    v.add_child(PremiumUI.label(str(achievement.title).to_upper(), 26, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
    v.add_child(PremiumUI.label(str(achievement.desc), 18, Color(0.72, 0.84, 0.95, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
    v.add_child(PremiumUI.progress(progress, int(achievement.target)))
    var button := PremiumUI.button("CLAIM" if unlocked.has(id) and not claimed.has(id) else ("DONE" if claimed.has(id) else "LOCKED"), "+%dc +%d XP" % [int(reward.get("coins", 0)), int(reward.get("xp", 0))], accent, Callable())
    button.disabled = not unlocked.has(id) or claimed.has(id)
    button.pressed.connect(func() -> void: _claim(id))
    v.add_child(button)
    _list.add_child(card)


func _claim(id: String) -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    save.mutate(func(state: Dictionary) -> Dictionary:
        state["progression"] = ProgressionContent.claim_achievement(state.get("progression", {}), id)
        return state)
    _reload()
