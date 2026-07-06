## DailyLogin
extends Control

const RewardEconomy := preload("res://src/core/reward_economy.gd")
const PremiumUI := preload("res://src/presentation/ui/premium_ui.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _claim_btn: Button = $Root/ClaimBtn
@onready var _list: VBoxContainer = $Root/Scroll/List
@onready var _status: Label = $Root/Status


func _ready() -> void:
    var shell := PremiumUI.screen(self, "DAILY LOGIN", _on_back_pressed)
    _back_btn = shell.back
    _list = shell.list
    _back_btn.pressed.connect(_on_back_pressed)
    _reload()


func _reload() -> void:
    for child in _list.get_children():
        child.queue_free()
    var progression := _load_progression()
    var day := RewardEconomy.current_login_day(progression)
    var can_claim := RewardEconomy.can_claim_login(progression)
    _status = PremiumUI.label("", 34, Color(1.0, 0.933, 0.0, 1.0))
    _list.add_child(_status)
    _claim_btn = PremiumUI.button("CLAIM", "TODAY'S REWARD", Color(0.2, 1.0, 0.38, 1.0), _on_claim_pressed)
    _claim_btn.custom_minimum_size = Vector2(0, 112)
    _list.add_child(_claim_btn)
    _status.text = "DAY %d READY" % day if can_claim else "CLAIMED TODAY"
    _claim_btn.disabled = not can_claim
    for entry in RewardEconomy.login_calendar():
        var accent := Color(1.0, 0.76, 0.05, 1.0) if int(entry.day) == day else Color(0.0, 0.82, 1.0, 1.0)
        var card := PremiumUI.card(accent, 116)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 16)
        card.add_child(row)
        row.add_child(PremiumUI.label("DAY\n%d" % int(entry.day), 24, accent))
        var text := VBoxContainer.new()
        text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(text)
        text.add_child(PremiumUI.label(str(entry.title).to_upper(), 28, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
        text.add_child(PremiumUI.label("NEXT" if int(entry.day) == day else "CALENDAR REWARD", 18, Color(0.72, 0.84, 0.95, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
        _list.add_child(card)
    PremiumUI.style_tree(_list)


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
