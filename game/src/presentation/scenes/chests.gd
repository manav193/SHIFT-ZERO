## Chests
extends Control

const RewardEconomy := preload("res://src/core/reward_economy.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _chest_list: VBoxContainer = $Root/Body/Chests/Scroll/List
@onready var _booster_list: VBoxContainer = $Root/Body/Boosters/Scroll/List
@onready var _result: Label = $Root/Result


func _ready() -> void:
    _back_btn.pressed.connect(_on_back_pressed)
    _reload()


func _reload() -> void:
    for child in _chest_list.get_children():
        child.queue_free()
    for child in _booster_list.get_children():
        child.queue_free()
    var progression := _load_progression()
    var chests: Dictionary = progression.get("chest_inventory", {})
    for chest_id in RewardEconomy.CHESTS:
        var button := Button.new()
        button.custom_minimum_size = Vector2(0, 72)
        button.text = "%s CHEST  x%d" % [str(chest_id).to_upper(), int(chests.get(chest_id, 0))]
        button.disabled = int(chests.get(chest_id, 0)) <= 0
        button.pressed.connect(func() -> void: _open_chest(chest_id))
        _chest_list.add_child(button)
    var boosters: Dictionary = progression.get("booster_inventory", {})
    var equipped: Array = progression.get("equipped_boosters", [])
    for booster_id in RewardEconomy.BOOSTERS:
        var button := Button.new()
        button.custom_minimum_size = Vector2(0, 72)
        var is_equipped := equipped.has(booster_id)
        button.text = "%s  x%d%s" % [str(booster_id).replace("_", " ").to_upper(), int(boosters.get(booster_id, 0)), "  EQUIPPED" if is_equipped else ""]
        button.disabled = int(boosters.get(booster_id, 0)) <= 0 and not is_equipped
        button.pressed.connect(func() -> void: _toggle_booster(booster_id, not is_equipped))
        _booster_list.add_child(button)


func _open_chest(chest_id: String) -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var seed := Time.get_ticks_msec()
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        state["progression"] = RewardEconomy.open_chest(state.get("progression", {}), chest_id, seed)
        return state)
    if result.ok:
        var progression := _load_progression()
        var pending: Array = progression.get("pending_rewards", [])
        var last: Dictionary = pending.back() if not pending.is_empty() else {}
        _result.text = RewardEconomy.reward_text(last.get("reward", {})).to_upper()
        _result.scale = Vector2(0.84, 0.84)
        create_tween().tween_property(_result, "scale", Vector2.ONE, 0.2)
        _reload()


func _toggle_booster(booster_id: String, equipped: bool) -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        state["progression"] = RewardEconomy.set_booster_equipped(state.get("progression", {}), booster_id, equipped)
        return state)
    if result.ok:
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
        push_error("Chests", "back failed: %s" % result.error)
