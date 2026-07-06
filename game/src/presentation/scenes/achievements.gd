## Achievements
extends Control

const ProgressionContent := preload("res://src/core/progression_content.gd")
const PremiumUI := preload("res://src/presentation/ui/premium_ui.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _list: VBoxContainer = $Root/Scroll/List


func _ready() -> void:
    PremiumUI.apply_screen(self)
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
    var row := HBoxContainer.new()
    row.custom_minimum_size = Vector2(0, 108)
    row.add_theme_constant_override("separation", 18)
    var unlocked: Array = progression.get("achievements_unlocked", [])
    var claimed: Array = progression.get("achievement_rewards_claimed", [])
    var id := str(achievement.id)
    var icon := Label.new()
    icon.custom_minimum_size = Vector2(54, 0)
    icon.text = "*" if unlocked.has(id) else "[]"
    icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    icon.add_theme_font_size_override("font_size", 34)
    row.add_child(icon)
    var text := Label.new()
    text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    var progress := ProgressionContent.achievement_progress(progression, achievement)
    var reward: Dictionary = achievement.reward
    text.text = "%s\n%s  %d/%d  +%dc +%d XP" % [
        str(achievement.title),
        str(achievement.desc),
        progress,
        int(achievement.target),
        int(reward.get("coins", 0)),
        int(reward.get("xp", 0)),
    ]
    text.add_theme_font_size_override("font_size", 24)
    row.add_child(text)
    var button := Button.new()
    button.custom_minimum_size = Vector2(150, 70)
    button.text = "CLAIM" if unlocked.has(id) and not claimed.has(id) else ("DONE" if claimed.has(id) else "LOCKED")
    button.disabled = not unlocked.has(id) or claimed.has(id)
    button.pressed.connect(func() -> void: _claim(id))
    row.add_child(button)
    _list.add_child(row)
    PremiumUI.style_tree(row)


func _claim(id: String) -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    save.mutate(func(state: Dictionary) -> Dictionary:
        state["progression"] = ProgressionContent.claim_achievement(state.get("progression", {}), id)
        return state)
    _reload()
