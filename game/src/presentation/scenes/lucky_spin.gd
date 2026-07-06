## LuckySpin
extends Control

const RewardEconomy := preload("res://src/core/reward_economy.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _spin_btn: Button = $Root/SpinBtn
@onready var _wheel: Label = $Root/Wheel
@onready var _result: Label = $Root/Result


func _ready() -> void:
    _back_btn.pressed.connect(_on_back_pressed)
    _spin_btn.pressed.connect(_on_spin_pressed)
    _reload()


func _reload() -> void:
    var progression := _load_progression()
    _spin_btn.disabled = not RewardEconomy.can_spin(progression)
    _result.text = "FREE SPIN READY" if not _spin_btn.disabled else "NEXT FREE SPIN TOMORROW"


func _on_spin_pressed() -> void:
    _spin_btn.disabled = true
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(_wheel, "rotation", TAU * 5.5, 1.2)
    tween.tween_callback(_claim_spin)


func _claim_spin() -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var seed := Time.get_ticks_msec()
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        state["progression"] = RewardEconomy.claim_spin(state.get("progression", {}), RewardEconomy.today_key(), seed)
        return state)
    if result.ok:
        var progression := _load_progression()
        var pending: Array = progression.get("pending_rewards", [])
        var last: Dictionary = pending.back() if not pending.is_empty() else {}
        _result.text = "%s\n%s" % [str(last.get("source", "REWARD")).to_upper(), RewardEconomy.reward_text(last.get("reward", {})).to_upper()]
        _wheel.rotation = 0.0
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
        push_error("LuckySpin", "back failed: %s" % result.error)
