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
const ProgressionRules := preload("res://src/core/progression_rules.gd")
const ProgressionContent := preload("res://src/core/progression_content.gd")
const ThemeCatalog := preload("res://src/core/theme_catalog.gd")
const RewardEconomy := preload("res://src/core/reward_economy.gd")

@export var run_director: NodePath
@export var modifier_manager: NodePath

@onready var _score_label: Label = $Top/Score
@onready var _best_label: Label = $Top/Best
@onready var _distance_label: Label = $Top/Distance
@onready var _coins_label: Label = $Top/Coins
@onready var _player_level_label: Label = $Top/PlayerLevel
@onready var _run_level_label: Label = $Top/RunLevel
@onready var _run_level_notice: Label = $Top/RunLevelNotice
@onready var _pause_btn: Button = $Top/PauseBtn
@onready var _modifier_badge: Control = $Top/ModifierBadge
@onready var _modifier_label: Label = $Top/ModifierBadge/Label
@onready var _modifier_time: Label = $Top/ModifierBadge/Time
@onready var _boss_panel: Control = $Top/BossPanel
@onready var _boss_name: Label = $Top/BossPanel/V/Name
@onready var _boss_timer: ProgressBar = $Top/BossPanel/V/Timer
@onready var _boss_warning: Label = $Top/BossWarning
@onready var _boss_defeated: Label = $Top/BossDefeated
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
@onready var _go_xp: Label = $GameOverModal/Panel/V/XP
@onready var _go_level: Label = $GameOverModal/Panel/V/Level
@onready var _go_level_bar: ProgressBar = $GameOverModal/Panel/V/LevelBar
@onready var _go_restart_btn: Button = $GameOverModal/Panel/V/RestartBtn

var _director: Node
var _mod_mgr: Node
var _best_score: int = 0
var _display_score: float = 0.0
var _target_score: int = 0
var _flash: ColorRect
var _run_coins: int = 0
var _run_powerups: int = 0
var _run_flips: int = 0
var _run_obstacles_avoided: int = 0
var _run_birds_avoided: int = 0
var _run_started_ms: int = 0
var _total_coins: int = 0
var _player_xp: int = 0
var _player_level: int = 1
var _last_run_level: int = 1
var _active_powerups: Dictionary = {}
var _coin_reward_mult: int = 1
var _xp_reward_mult: int = 1


func _ready() -> void:
    _director = get_node_or_null(run_director)
    _mod_mgr = get_node_or_null(modifier_manager)
    _pause_modal.visible = false
    _go_modal.visible = false
    _modifier_badge.visible = false
    _run_level_notice.visible = false
    _boss_panel.visible = false
    _boss_warning.visible = false
    _boss_defeated.visible = false
    _pause_btn.pressed.connect(_on_pause_pressed)
    _pause_resume_btn.pressed.connect(_on_resume_pressed)
    _pause_restart_btn.pressed.connect(_on_restart_pressed)
    _go_restart_btn.pressed.connect(_on_restart_pressed)
    _wire_button(_pause_btn)
    _wire_button(_pause_resume_btn)
    _wire_button(_pause_restart_btn)
    _wire_button(_go_restart_btn)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.subscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.subscribe(Events.PLAYER_GRAVITY_FLIPPED, _on_gravity_flipped)
    EventBus.subscribe(Events.OBSTACLE_AVOIDED, _on_obstacle_avoided)
    EventBus.subscribe(Events.COIN_COLLECTED, _on_coin_collected)
    EventBus.subscribe(Events.POWERUP_COLLECTED, _on_powerup_collected)
    EventBus.subscribe(Events.POWERUP_ACTIVATED, _on_powerup_activated)
    EventBus.subscribe(Events.POWERUP_EXPIRED, _on_powerup_expired)
    EventBus.subscribe(Events.SHIELD_USED, _on_shield_used)
    EventBus.subscribe(Events.MODIFIER_ACTIVATED, _on_modifier_activated)
    EventBus.subscribe(Events.MODIFIER_EXPIRED, _on_modifier_expired)
    EventBus.subscribe(Events.BOSS_WARNING, _on_boss_warning)
    EventBus.subscribe(Events.BOSS_STARTED, _on_boss_started)
    EventBus.subscribe(Events.BOSS_PROGRESS, _on_boss_progress)
    EventBus.subscribe(Events.BOSS_DEFEATED, _on_boss_defeated)
    EventBus.subscribe(Events.BOSS_FAILED, _on_boss_failed)
    _load_saved_progress()
    _best_label.text = "BEST %d" % _best_score
    _score_label.text = "0"
    _distance_label.text = "0 m"
    _coins_label.text = "COINS 0"
    _player_level_label.text = "LV %d" % _player_level
    _update_run_level(0)
    _make_flash()


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.unsubscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.unsubscribe(Events.PLAYER_GRAVITY_FLIPPED, _on_gravity_flipped)
    EventBus.unsubscribe(Events.OBSTACLE_AVOIDED, _on_obstacle_avoided)
    EventBus.unsubscribe(Events.COIN_COLLECTED, _on_coin_collected)
    EventBus.unsubscribe(Events.POWERUP_COLLECTED, _on_powerup_collected)
    EventBus.unsubscribe(Events.POWERUP_ACTIVATED, _on_powerup_activated)
    EventBus.unsubscribe(Events.POWERUP_EXPIRED, _on_powerup_expired)
    EventBus.unsubscribe(Events.SHIELD_USED, _on_shield_used)
    EventBus.unsubscribe(Events.MODIFIER_ACTIVATED, _on_modifier_activated)
    EventBus.unsubscribe(Events.MODIFIER_EXPIRED, _on_modifier_expired)
    EventBus.unsubscribe(Events.BOSS_WARNING, _on_boss_warning)
    EventBus.unsubscribe(Events.BOSS_STARTED, _on_boss_started)
    EventBus.unsubscribe(Events.BOSS_PROGRESS, _on_boss_progress)
    EventBus.unsubscribe(Events.BOSS_DEFEATED, _on_boss_defeated)
    EventBus.unsubscribe(Events.BOSS_FAILED, _on_boss_failed)


func _process(delta: float) -> void:
    if _director == null or _go_modal.visible or _pause_modal.visible:
        return
    _target_score = _director.current_score()
    _display_score = lerpf(_display_score, float(_target_score), 1.0 - exp(-10.0 * delta))
    if abs(_display_score - float(_target_score)) < 0.05:
        _display_score = float(_target_score)
    _score_label.text = str(int(round(_display_score)))
    var distance_m := int(_director.current_distance() / 100.0)
    _distance_label.text = "%d m" % distance_m
    _update_run_level(distance_m)
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
    var distance_m := int(distance / 100.0)
    var new_best: bool = current > _best_score
    _persist_run_coins()
    var xp_earned := ProgressionRules.run_xp(distance_m, _run_coins, _run_powerups, current) * _xp_reward_mult
    var leveled := _persist_run_xp(xp_earned)
    _persist_run_stats(distance_m, current)
    if new_best:
        _best_score = current
        _persist_best_score(_best_score, distance)
    _best_label.text = "BEST %d" % _best_score
    _go_score.text = "SCORE %d" % current
    _go_best.text = "BEST %d%s" % [_best_score, "  NEW!" if new_best else ""]
    _go_distance.text = "DISTANCE %d m" % distance_m
    _go_coins.text = "COINS +%d  TOTAL %d" % [_run_coins * _coin_reward_mult, _total_coins]
    _go_xp.text = "XP +%d" % xp_earned
    _go_level.text = "LEVEL %d%s" % [_player_level, "  LEVEL UP!" if leveled else ""]
    _update_level_bar()
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


func _on_boss_warning(payload: Dictionary) -> void:
    _boss_warning.text = "WARNING\n%s  %d" % [str(payload.get("name", "BOSS")).to_upper(), int(payload.get("countdown", 0))]
    _boss_warning.visible = true
    _boss_warning.modulate.a = 1.0
    _boss_warning.scale = Vector2(0.96, 0.96)
    _boss_panel.visible = false


func _on_boss_started(payload: Dictionary) -> void:
    _boss_warning.visible = false
    _boss_defeated.visible = false
    _boss_panel.visible = true
    _boss_name.text = str(payload.get("name", "BOSS")).to_upper()
    _boss_timer.max_value = float(payload.get("duration_s", 1.0))
    _boss_timer.value = _boss_timer.max_value
    _animate_modal(_boss_panel)


func _on_boss_progress(payload: Dictionary) -> void:
    _boss_panel.visible = true
    _boss_timer.max_value = float(payload.get("duration_s", 1.0))
    _boss_timer.value = float(payload.get("remaining_s", 0.0))


func _on_boss_defeated(payload: Dictionary) -> void:
    _boss_panel.visible = false
    _boss_warning.visible = false
    _boss_defeated.text = "BOSS DEFEATED\n+%d COINS  +%d XP" % [int(payload.get("coins", 0)), int(payload.get("xp", 0))]
    _boss_defeated.visible = true
    _boss_defeated.modulate.a = 1.0
    _boss_defeated.scale = Vector2(0.88, 0.88)
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(_boss_defeated, "scale", Vector2.ONE, 0.18)
    tween.tween_interval(1.35)
    tween.tween_property(_boss_defeated, "modulate:a", 0.0, 0.25)
    tween.tween_callback(func() -> void: _boss_defeated.visible = false)
    _load_saved_progress()
    _coins_label.text = "COINS %d" % _run_coins
    _player_level_label.text = "LV %d" % _player_level


func _on_boss_failed(_payload: Dictionary) -> void:
    _boss_panel.visible = false
    _boss_warning.visible = false
    _boss_defeated.visible = false


func _on_coin_collected(payload: Dictionary) -> void:
    _run_coins += int(payload.get("value", 1))
    _coins_label.text = "COINS %d" % _run_coins


func _on_powerup_collected(_payload: Dictionary) -> void:
    _run_powerups += 1


func _on_run_started(_payload: Dictionary) -> void:
    _run_coins = 0
    _run_powerups = 0
    _run_flips = 0
    _run_obstacles_avoided = 0
    _run_birds_avoided = 0
    _run_started_ms = Time.get_ticks_msec()
    _load_run_boosters()


func _on_gravity_flipped(_payload: Dictionary) -> void:
    _run_flips += 1


func _on_obstacle_avoided(payload: Dictionary) -> void:
    _run_obstacles_avoided += 1
    if str(payload.get("category", "")) == "bird":
        _run_birds_avoided += 1


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
    _player_xp = int(progression.get("player_xp", 0))
    _player_level = int(progression.get("player_level", ProgressionRules.level_for_total_xp(_player_xp)))


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
    var coins_to_add := _run_coins * _coin_reward_mult
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        _total_coins += coins_to_add
        return
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = state.get("progression", {})
        progression["total_coins"] = int(progression.get("total_coins", 0)) + coins_to_add
        state["progression"] = progression
        return state)
    if result.ok:
        _total_coins += coins_to_add


func _persist_run_stats(distance_m: int, score: int) -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var run_time_s := int(maxi(0, Time.get_ticks_msec() - _run_started_ms) / 1000)
    save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = ProgressionContent.ensure_progression(state.get("progression", {}))
        var stats: Dictionary = progression.get("player_stats", ProgressionContent.default_stats())
        stats["total_runs"] = int(stats.get("total_runs", 0)) + 1
        stats["total_deaths"] = int(stats.get("total_deaths", 0)) + 1
        stats["best_distance"] = maxi(int(stats.get("best_distance", 0)), distance_m)
        stats["best_score"] = maxi(int(stats.get("best_score", 0)), score)
        stats["total_play_time_s"] = int(stats.get("total_play_time_s", 0)) + run_time_s
        stats["gravity_flips"] = int(stats.get("gravity_flips", 0)) + _run_flips
        stats["obstacles_avoided"] = int(stats.get("obstacles_avoided", 0)) + _run_obstacles_avoided
        stats["birds_avoided"] = int(stats.get("birds_avoided", 0)) + _run_birds_avoided
        stats["coins_collected"] = int(stats.get("coins_collected", 0)) + _run_coins
        stats["powerups_collected"] = int(stats.get("powerups_collected", 0)) + _run_powerups
        stats["highest_run_level"] = maxi(int(stats.get("highest_run_level", 1)), _last_run_level)
        progression["player_stats"] = stats
        var run := {
            "coins": _run_coins,
            "distance_m": distance_m,
            "highest_run_level": _last_run_level,
            "powerups": _run_powerups,
            "flips": _run_flips,
            "birds_avoided": _run_birds_avoided,
        }
        progression = ProgressionContent.update_daily_progress(progression, ProgressionContent.daily_counters(stats, run, progression))
        progression = ProgressionContent.update_achievements(progression)
        progression = ThemeCatalog.unlock_available(progression)
        state["progression"] = progression
        return state)


func _persist_run_xp(xp_earned: int) -> bool:
    if xp_earned <= 0:
        return false
    var old_level := _player_level
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        _player_xp += xp_earned
        _player_level = ProgressionRules.level_for_total_xp(_player_xp)
        return _player_level > old_level
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = state.get("progression", {})
        var next_xp := int(progression.get("player_xp", 0)) + xp_earned
        progression["player_xp"] = next_xp
        progression["player_level"] = ProgressionRules.level_for_total_xp(next_xp)
        state["progression"] = progression
        return state)
    if not result.ok:
        return false
    _player_xp += xp_earned
    _player_level = ProgressionRules.level_for_total_xp(_player_xp)
    _player_level_label.text = "LV %d" % _player_level
    var leveled := _player_level > old_level
    if leveled:
        EventBus.emit(Events.PLAYER_LEVEL_UP, {"level": _player_level, "xp": _player_xp})
    return leveled


func _update_level_bar() -> void:
    var need := ProgressionRules.required_xp_for_level(_player_level)
    var into := ProgressionRules.xp_into_level(_player_xp)
    _go_level_bar.max_value = need
    _go_level_bar.value = into


func _update_run_level(distance_m: int) -> void:
    var info := ProgressionRules.run_level_for_distance_m(distance_m)
    var level := int(info.level)
    var name := str(info.name)
    _run_level_label.text = "RUN LV %d  %s" % [level, name.to_upper()]
    if level != _last_run_level:
        _last_run_level = level
        _show_run_level_notice(level, name)
        EventBus.emit(Events.RUN_LEVEL_CHANGED, {"level": level, "name": name, "distance_m": distance_m})


func _show_run_level_notice(level: int, name: String) -> void:
    _run_level_notice.text = "RUN LEVEL %d  %s" % [level, name.to_upper()]
    _run_level_notice.visible = true
    _run_level_notice.modulate.a = 1.0
    _run_level_notice.scale = Vector2(0.9, 0.9)
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(_run_level_notice, "scale", Vector2.ONE, 0.18)
    tween.tween_interval(1.0)
    tween.tween_property(_run_level_notice, "modulate:a", 0.0, 0.25)
    tween.tween_callback(func() -> void: _run_level_notice.visible = false)


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


func _load_run_boosters() -> void:
    _coin_reward_mult = 1
    _xp_reward_mult = 1
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var loaded: Result = save.load_state()
    if not loaded.ok:
        return
    var state: Dictionary = loaded.value
    var progression: Dictionary = RewardEconomy.ensure_progression(state.get("progression", {}))
    var active: Array = progression.get("active_run_boosters", [])
    _coin_reward_mult = 2 if active.has("coin_booster") else 1
    _xp_reward_mult = 2 if active.has("xp_booster") else 1
