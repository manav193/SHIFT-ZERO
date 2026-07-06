## DailyMissions
extends Control

const ProgressionContent := preload("res://src/core/progression_content.gd")
const PremiumUI := preload("res://src/presentation/ui/premium_ui.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _date_label: Label = $Root/Header/Date
@onready var _list: VBoxContainer = $Root/Scroll/List


func _ready() -> void:
    var shell := PremiumUI.screen(self, "MISSIONS", _on_back_pressed)
    _back_btn = shell.back
    _list = shell.list
    _date_label = PremiumUI.label("DAILY RESET", 22, Color(0.62, 0.82, 1.0, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
    shell.header.add_child(_date_label)
    _back_btn.pressed.connect(_on_back_pressed)
    _reload()


func _on_back_pressed() -> void:
    var result: Result = SceneRouter.push(_MAIN_MENU_PATH)
    if not result.ok:
        push_error("Daily", "back failed: %s" % result.error)


func _reload() -> void:
    for child in _list.get_children():
        child.queue_free()
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        state["progression"] = ProgressionContent.refresh_daily_if_needed(state.get("progression", {}))
        return state)
    if not result.ok:
        return
    var loaded: Result = save.load_state()
    if not loaded.ok:
        return
    var progression: Dictionary = loaded.value.get("progression", {})
    var daily: Dictionary = progression.get("daily", {})
    _date_label.text = "RESET %s" % str(daily.get("last_refresh_date", "TODAY"))
    _list.add_child(PremiumUI.card_text("BATTLE PASS TASKS", "Complete three daily objectives for coins and XP.", PremiumUI.PINK, 112))
    for mission in daily.get("missions", []):
        _add_mission_row(mission)
    PremiumUI.style_tree(_list)


func _add_mission_row(mission: Dictionary) -> void:
    var card := PremiumUI.card(Color(0.8, 0.24, 1.0, 1.0), 178)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 18)
    card.add_child(row)
    var icon := PremiumUI.label("XP", 28, Color(1.0, 0.76, 0.05, 1.0))
    icon.custom_minimum_size = Vector2(92, 0)
    row.add_child(icon)
    var text := VBoxContainer.new()
    text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text.add_theme_constant_override("separation", 8)
    var progress := int(mission.get("progress", 0))
    var target := int(mission.get("target", 1))
    var reward: Dictionary = mission.get("reward", {})
    text.add_child(PremiumUI.label(str(mission.get("title", "Mission")).to_upper(), 30, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
    text.add_child(PremiumUI.label("+%d COINS  +%d XP" % [int(reward.get("coins", 0)), int(reward.get("xp", 0))], 20, Color(1.0, 0.933, 0.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
    text.add_child(PremiumUI.progress(progress, target))
    row.add_child(text)
    var completed := bool(mission.get("completed", false))
    var claimed := bool(mission.get("claimed", false))
    var button := PremiumUI.button("CLAIM" if completed and not claimed else ("DONE" if claimed else "LOCKED"), "%d/%d" % [progress, target], Color(0.2, 1.0, 0.38, 1.0), Callable())
    button.custom_minimum_size = Vector2(150, 96)
    button.text = "CLAIM" if completed and not claimed else ("DONE" if claimed else "LOCKED")
    button.disabled = not completed or claimed
    var id := str(mission.get("id", ""))
    button.pressed.connect(func() -> void: _claim(id))
    row.add_child(button)
    _list.add_child(card)


func _claim(id: String) -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    save.mutate(func(state: Dictionary) -> Dictionary:
        state["progression"] = ProgressionContent.claim_daily(state.get("progression", {}), id)
        return state)
    _reload()
