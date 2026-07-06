## DailyMissions
extends Control

const ProgressionContent := preload("res://src/core/progression_content.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _date_label: Label = $Root/Header/Date
@onready var _list: VBoxContainer = $Root/Scroll/List


func _ready() -> void:
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
    _date_label.text = str(daily.get("last_refresh_date", ""))
    for mission in daily.get("missions", []):
        _add_mission_row(mission)


func _add_mission_row(mission: Dictionary) -> void:
    var row := HBoxContainer.new()
    row.custom_minimum_size = Vector2(0, 96)
    row.add_theme_constant_override("separation", 18)
    var icon := Label.new()
    icon.custom_minimum_size = Vector2(48, 0)
    icon.text = "[]"
    icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    icon.add_theme_font_size_override("font_size", 28)
    row.add_child(icon)
    var text := Label.new()
    text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    var progress := int(mission.get("progress", 0))
    var target := int(mission.get("target", 1))
    var reward: Dictionary = mission.get("reward", {})
    text.text = "%s  %d/%d  +%dc +%d XP" % [
        str(mission.get("title", "Mission")),
        progress,
        target,
        int(reward.get("coins", 0)),
        int(reward.get("xp", 0)),
    ]
    text.add_theme_font_size_override("font_size", 26)
    row.add_child(text)
    var button := Button.new()
    button.custom_minimum_size = Vector2(150, 70)
    var completed := bool(mission.get("completed", false))
    var claimed := bool(mission.get("claimed", false))
    button.text = "CLAIM" if completed and not claimed else ("DONE" if claimed else "LOCKED")
    button.disabled = not completed or claimed
    var id := str(mission.get("id", ""))
    button.pressed.connect(func() -> void: _claim(id))
    row.add_child(button)
    _list.add_child(row)


func _claim(id: String) -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    save.mutate(func(state: Dictionary) -> Dictionary:
        state["progression"] = ProgressionContent.claim_daily(state.get("progression", {}), id)
        return state)
    _reload()
