## HUD
##
## In-game overlay:
##   - Current score (top-center)
##   - Best score (top-right)
##   - Distance (below score)
##   - Pause button (top-left)
##   - Modifier badge (below best, appears while a modifier is active)
##   - Pause modal (hidden by default)
##   - Game Over modal (hidden by default, shown on RUN_FINISHED)
##
## Reads live score/distance by polling RunDirector each frame. Reads best
## score from ISaveService at boot and on RUN_FINISHED. Persists a new
## best via SaveService.mutate.
##
## Layer: presentation.
extends Control

const Events := preload("res://src/core/events.gd")

@export var run_director: NodePath
@export var modifier_manager: NodePath

@onready var _score_label: Label = $Top/Score
@onready var _best_label: Label = $Top/Best
@onready var _distance_label: Label = $Top/Distance
@onready var _coins_label: Label = $Top/Coins
@onready var _pause_btn: Button = $Top/PauseBtn
@onready var _modifier_badge: Control = $Top/ModifierBadge
@onready var _modifier_label: Label = $Top/ModifierBadge/Label
@onready var _modifier_time: Label = $Top/ModifierBadge/Time
@onready var _pause_modal: Control = $PauseModal
@onready var _pause_panel: Control = $PauseModal/Panel
@onready var _pause_resume_btn: Button = $PauseModal/Panel/V/ResumeBtn
@onready var _pause_restart_btn: Button = $PauseModal/Panel/V/RestartBtn
@onready var _go_modal: Control = $GameOverModal
@onready var _go_dim: ColorRect = $GameOverModal/Dim
@onready var _go_panel: Control = $GameOverModal/Panel
@onready var _go_score: Label = $GameOverModal/Panel/V/Score
@onready var _go_best: Label = $GameOverModal/Panel/V/Best
@onready var _go_distance: Label = $GameOverModal/Panel/V/Distance
@onready var _go_coins: Label = $GameOverModal/Panel/V/Coins
@onready var _go_restart_btn: Button = $GameOverModal/Panel/V/RestartBtn

var _director: Node
var _mod_mgr: Node
var _best_score: int = 0
var _display_score: float = 0.0
var _target_score: int = 0
var _flash: ColorRect
var _run_coins: int = 0
var _total_coins: int = 0
var _active_powerups: Dictionary = {}


func _ready() -> void:
    _director = get_node_or_null(run_director)
    _mod_mgr = get_node_or_null(modifier_manager)
    _pause_modal.visible = false
    _go_modal.visible = false
    _modifier_badge.visible = false
    _pause_btn.pressed.connect(_on_pause_pressed)
    _pause_resume_btn.pressed.connect(_on_resume_pressed)
    _pause_restart_btn.pressed.connect(_on_restart_pressed)
    _go_restart_btn.pressed.connect(_on_restart_pressed)
    _wire_button(_pause_btn)
    _wire_button(_pause_resume_btn)
    _wire_button(_pause_restart_btn)
    _wire_button(_go_restart_btn)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.subscribe(Events.COIN_COLLECTED, _on_coin_collected)
    EventBus.subscribe(Events.POWERUP_ACTIVATED, _on_powerup_activated)
    EventBus.subscribe(Events.POWERUP_EXPIRED, _on_powerup_expired)
    EventBus.subscribe(Events.SHIELD_USED, _on_shield_used)
    EventBus.subscribe(Events.MODIFIER_ACTIVATED, _on_modifier_activated)
    EventBus.subscribe(Events.MODIFIER_EXPIRED, _on_modifier_expired)
    _load_saved_progress()
    _best_label.text = "BEST %d" % _best_score
    _score_label.text = "0"
    _distance_label.text = "0 m"
    _coins_label.text = "COINS 0"
    _make_flash()


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.unsubscribe(Events.COIN_COLLECTED, _on_coin_collected)
    EventBus.unsubscribe(Events.POWERUP_ACTIVATED, _on_powerup_activated)
    EventBus.unsubscribe(Events.POWERUP_EXPIRED, _on_powerup_expired)
    EventBus.unsubscribe(Events.SHIELD_USED, _on_shield_used)
    EventBus.unsubscribe(Events.MODIFIER_ACTIVATED, _on_modifier_activated)
    EventBus.unsubscribe(Events.MODIFIER_EXPIRED, _on_modifier_expired)


func _process(delta: float) -> void:
    if _director == null or _go_modal.visible or _pause_modal.visible:
        return
    _target_score = _director.current_score()
    _display_score = lerpf(_display_score, float(_target_score), 1.0 - exp(-10.0 * delta))
    if abs(_display_score - float(_target_score)) < 0.05:
        _display_score = float(_target_score)
    _score_label.text = str(int(round(_display_score)))
    _distance_label.text = "%d m" % int(_director.current_distance() / 100.0)
    _update_powerup_badge()
    if _mod_mgr != null and _mod_mgr.has_method("active_id"):
        var id: String = _mod_mgr.active_id()
        if id != "" and _modifier_badge.visible:
            _modifier_time.text = "%.1fs" % _mod_mgr.active_remaining_s()


func _on_pause_pressed() -> void:
    if _go_modal.visible:
        return
    get_tree().paused = true
    _pause_modal.visible = true
    _animate_modal(_pause_panel)
    EventBus.emit(Events.RUN_PAUSED, {})


func _on_resume_pressed() -> void:
    _pause_modal.visible = false
    get_tree().paused = false
    EventBus.emit(Events.RUN_RESUMED, {})


func _on_restart_pressed() -> void:
    get_tree().paused = false
    Engine.time_scale = 1.0
    get_tree().reload_current_scene()


func _on_run_finished(_payload: Dictionary) -> void:
    _flash_screen(Color(1.0, 1.0, 1.0, 0.55), 0.18)
    Engine.time_scale = 0.25
    await get_tree().create_timer(0.3, true, false, true).timeout
    Engine.time_scale = 1.0
    var current: int = 0 if _director == null else _director.current_score()
    var distance: int = 0 if _director == null else int(_director.current_distance())
    var new_best: bool = current > _best_score
    _persist_run_coins()
    if new_best:
        _best_score = current
        _persist_best_score(_best_score, distance)
    _best_label.text = "BEST %d" % _best_score
    _go_score.text = "SCORE %d" % current
    _go_best.text = "BEST %d%s" % [_best_score, "  NEW!" if new_best else ""]
    _go_distance.text = "DISTANCE %d m" % int(distance / 100.0)
    _go_coins.text = "COINS +%d  TOTAL %d" % [_run_coins, _total_coins]
    _go_modal.visible = true
    _animate_modal(_go_panel)
    _go_dim.modulate.a = 0.0
    create_tween().tween_property(_go_dim, "modulate:a", 1.0, 0.18)
    _modifier_badge.visible = false


func _on_modifier_activated(payload: Dictionary) -> void:
    var name: String = str(payload.get("display_name", "MOD"))
    _modifier_label.text = name
    _modifier_time.text = "%.1fs" % float(payload.get("duration_s", 0.0))
    _modifier_badge.visible = true


func _on_modifier_expired(_payload: Dictionary) -> void:
    _modifier_badge.visible = false


func _on_coin_collected(payload: Dictionary) -> void:
    _run_coins += int(payload.get("value", 1))
    _coins_label.text = "COINS %d" % _run_coins


func _on_powerup_activated(payload: Dictionary) -> void:
    var id := str(payload.get("id", ""))
    var duration_s := float(payload.get("duration_s", 0.0))
    if id == "":
        return
    _active_powerups[id] = Time.get_ticks_msec() + int(duration_s * 1000.0)
    _update_powerup_badge()


func _on_powerup_expired(payload: Dictionary) -> void:
    _active_powerups.erase(str(payload.get("id", "")))
    _update_powerup_badge()


func _on_shield_used(_payload: Dictionary) -> void:
    _active_powerups.erase("shield")
    _update_powerup_badge()


func _load_saved_progress() -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var r: Result = save.load_state()
    if not r.ok:
        return
    var state: Dictionary = r.value
    var stats: Dictionary = state.get("stats", {})
    var progression: Dictionary = state.get("progression", {})
    _best_score = int(stats.get("best_score", 0))
    _total_coins = int(progression.get("total_coins", 0))


func _persist_best_score(score: int, distance: int) -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    save.mutate(func(state: Dictionary) -> Dictionary:
        var stats: Dictionary = state.get("stats", {})
        stats["best_score"] = score
        stats["best_distance"] = float(distance)
        state["stats"] = stats
        return state)
    EventBus.emit(Events.BEST_SCORE_CHANGED, {"best_score": score})


func _persist_run_coins() -> void:
    if _run_coins <= 0:
        return
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        _total_coins += _run_coins
        return
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = state.get("progression", {})
        progression["total_coins"] = int(progression.get("total_coins", 0)) + _run_coins
        state["progression"] = progression
        return state)
    if result.ok:
        _total_coins += _run_coins


func _update_powerup_badge() -> void:
    if _modifier_badge.visible and _mod_mgr != null and _mod_mgr.has_method("active_id") and _mod_mgr.active_id() != "":
        return
    var now := Time.get_ticks_msec()
    for id in _active_powerups.keys():
        if id != "shield" and now >= int(_active_powerups[id]):
            _active_powerups.erase(id)
    if _active_powerups.has("shield"):
        _modifier_label.text = "SHIELD"
        _modifier_time.text = "READY"
        _modifier_badge.visible = true
        return
    for id in ["magnet", "double_score"]:
        if _active_powerups.has(id):
            _modifier_label.text = "MAGNET" if id == "magnet" else "2X SCORE"
            var remaining := maxf(0.0, float(int(_active_powerups[id]) - now) / 1000.0)
            _modifier_time.text = "%.1fs" % remaining
            _modifier_badge.visible = true
            return
    if _mod_mgr == null or not _mod_mgr.has_method("active_id") or _mod_mgr.active_id() == "":
        _modifier_badge.visible = false


func _make_flash() -> void:
    _flash = ColorRect.new()
    _flash.anchor_right = 1.0
    _flash.anchor_bottom = 1.0
    _flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _flash.color = Color(1.0, 1.0, 1.0, 0.0)
    add_child(_flash)


func _flash_screen(color: Color, duration: float) -> void:
    if _flash == null:
        return
    _flash.color = color
    var tween := create_tween()
    tween.tween_property(_flash, "color:a", 0.0, duration)


func _animate_modal(panel: Control) -> void:
    panel.scale = Vector2(0.86, 0.86)
    panel.modulate.a = 0.0
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(panel, "scale", Vector2.ONE, 0.22)
    tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.16)


func _wire_button(button: Button) -> void:
    button.mouse_entered.connect(func() -> void: _button_to(button, Vector2(1.04, 1.04), 0.08))
    button.mouse_exited.connect(func() -> void: _button_to(button, Vector2.ONE, 0.10))
    button.button_down.connect(func() -> void: _button_to(button, Vector2(0.94, 0.94), 0.05))
    button.button_up.connect(func() -> void: _button_to(button, Vector2(1.04, 1.04), 0.08))


func _button_to(button: Button, target_scale: Vector2, duration: float) -> void:
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", target_scale, duration)
