## DailyLogin
extends Control

const RewardEconomy := preload("res://src/core/reward_economy.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _claim_btn: Button = $Root/ClaimBtn
@onready var _list: VBoxContainer = $Root/Scroll/List
@onready var _status: Label = $Root/Status


func _ready() -> void:
    _back_btn.pressed.connect(_on_back_pressed)
    _claim_btn.pressed.connect(_on_claim_pressed)
    _reload()


func _reload() -> void:
    for child in _list.get_children():
        child.queue_free()
    var progression := _load_progression()
    var day := RewardEconomy.current_login_day(progression)
    var can_claim := RewardEconomy.can_claim_login(progression)
    _status.text = "DAY %d READY" % day if can_claim else "CLAIMED TODAY"
    _claim_btn.disabled = not can_claim
    for entry in RewardEconomy.login_calendar():
        var row := Label.new()
        row.custom_minimum_size = Vector2(0, 66)
        row.text = "DAY %d   %s%s" % [int(entry.day), str(entry.title), "   NEXT" if int(entry.day) == day else ""]
        row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        row.add_theme_font_size_override("font_size", 30)
        row.add_theme_color_override("font_color", Color(1.0, 0.933, 0.0, 1.0) if int(entry.day) == day else Color(0.75, 0.85, 0.9, 1.0))
        _list.add_child(row)


func _on_claim_pressed() -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        state["progression"] = RewardEconomy.claim_login(state.get("progression", {}))
        return state)
    if result.ok:
        _status.text = "REWARD CLAIMED"
        _status.scale = Vector2(0.82, 0.82)
        create_tween().tween_property(_status, "scale", Vector2.ONE, 0.2)
        _reload()


func _load_progression() -> Dictionary:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return RewardEconomy.ensure_progression({})
    save.mutate(func(state: Dictionary) -> Dictionary:
        state["progression"] = RewardEconomy.ensure_progression(state.get("progression", {}))
        return state)
    var loaded: Result = save.load_state()
    if not loaded.ok:
        return RewardEconomy.ensure_progression({})
    var state: Dictionary = loaded.value
    return RewardEconomy.ensure_progression(state.get("progression", {}))


func _on_back_pressed() -> void:
    var result: Result = SceneRouter.push(_MAIN_MENU_PATH)
    if not result.ok:
        push_error("DailyLogin", "back failed: %s" % result.error)
