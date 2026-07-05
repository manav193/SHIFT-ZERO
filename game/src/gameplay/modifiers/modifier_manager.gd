## ModifierManager
##
## Schedules and runs gameplay modifiers during a run.
##
## Contract:
##   - First activation occurs `modifier_first_activation_s` seconds after
##     RUN_STARTED.
##   - Subsequent activations occur `modifier_min_gap_s .. modifier_max_gap_s`
##     seconds after the previous modifier expired.
##   - Only ONE modifier is active at a time (M1.5 scope). This is a hard
##     invariant enforced by `_active` reference.
##   - Selection uses the seeded MODIFIER RNG stream (determinism).
##   - On RUN_FINISHED it clears the active modifier and cancels the timer.
##
## Emits on EventBus:
##   MODIFIER_ACTIVATED  { id, display_name, duration_s, params }
##   MODIFIER_EXPIRED    { id }
##
## Layer: gameplay.
class_name ModifierManager
extends Node

const GameplayConfig := preload("res://src/gameplay/gameplay_config.gd")
const Events := preload("res://src/core/events.gd")
const RNG := preload("res://src/core/rng.gd")
const IModifier := preload("res://src/gameplay/modifiers/i_modifier.gd")
const LowGravityModifier := preload("res://src/gameplay/modifiers/low_gravity_modifier.gd")
const SlowMotionModifier := preload("res://src/gameplay/modifiers/slow_motion_modifier.gd")
const SpeedBurstModifier := preload("res://src/gameplay/modifiers/speed_burst_modifier.gd")

var _pool: Array[IModifier] = []
var _active: IModifier = null
var _active_expires_at_ms: int = 0
var _next_activation_at_ms: int = 0
var _armed: bool = false
var _paused: bool = false
var _pause_started_ms: int = 0

var _duration_s: float = 6.0
var _min_gap_s: float = 8.0
var _max_gap_s: float = 15.0
var _first_delay_s: float = 12.0
var _low_g_scale: float = 0.5
var _slow_mo_scale: float = 0.55
var _burst_scale: float = 1.55
var _rng: RandomNumberGenerator


func _ready() -> void:
    _reload_tunables()
    _rng = RNG.stream(RNG.STREAM_MODIFIER, 17)
    _build_pool()
    EventBus.subscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.subscribe(Events.RUN_PAUSED, _on_run_paused)
    EventBus.subscribe(Events.RUN_RESUMED, _on_run_resumed)
    EventBus.subscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    Log.info("Modifier", "manager ready. pool=%d dur=%.1fs gap=[%.1f,%.1f]s first=%.1fs" % [
        _pool.size(), _duration_s, _min_gap_s, _max_gap_s, _first_delay_s,
    ])


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.unsubscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.unsubscribe(Events.RUN_PAUSED, _on_run_paused)
    EventBus.unsubscribe(Events.RUN_RESUMED, _on_run_resumed)
    EventBus.unsubscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    _force_deactivate()


func _process(_delta: float) -> void:
    if not _armed or _paused:
        return
    var now: int = Time.get_ticks_msec()
    if _active != null:
        if now >= _active_expires_at_ms:
            _expire()
    else:
        if now >= _next_activation_at_ms:
            _activate_random()


## Exposed for HUD / tests -- returns the currently active modifier ID or "".
func active_id() -> String:
    return "" if _active == null else _active.id()


func active_remaining_s() -> float:
    if _active == null:
        return 0.0
    return maxf(0.0, float(_active_expires_at_ms - Time.get_ticks_msec()) / 1000.0)


func _activate_random() -> void:
    if _pool.is_empty():
        return
    var mod: IModifier = _pool[_rng.randi_range(0, _pool.size() - 1)]
    _active = mod
    _active_expires_at_ms = Time.get_ticks_msec() + int(_duration_s * 1000.0)
    var params: Dictionary = _params_for(mod)
    mod.activate(params)
    EventBus.emit(Events.MODIFIER_ACTIVATED, {
        "id": mod.id(),
        "display_name": mod.display_name(),
        "duration_s": _duration_s,
        "params": params,
    })
    Log.info("Modifier", "activated id=%s duration=%.1fs" % [mod.id(), _duration_s])


func _expire() -> void:
    if _active == null:
        return
    var id: String = _active.id()
    var params: Dictionary = _params_for(_active)
    _active.deactivate(params)
    _active = null
    EventBus.emit(Events.MODIFIER_EXPIRED, {"id": id})
    Log.info("Modifier", "expired id=%s" % id)
    _schedule_next()


func _schedule_next() -> void:
    var gap_s: float = _rng.randf_range(_min_gap_s, _max_gap_s)
    _next_activation_at_ms = Time.get_ticks_msec() + int(gap_s * 1000.0)


func _params_for(mod: IModifier) -> Dictionary:
    match mod.id():
        "low_gravity":
            return {"gravity_scale": (mod as LowGravityModifier).scale()}
        "slow_motion":
            return {"time_scale": (mod as SlowMotionModifier).scale()}
        "speed_burst":
            return {"speed_scale": (mod as SpeedBurstModifier).scale()}
        _:
            return {}


func _force_deactivate() -> void:
    if _active == null:
        return
    _active.deactivate(_params_for(_active))
    _active = null


func _on_run_started(_p: Dictionary) -> void:
    _armed = true
    _paused = false
    _force_deactivate()
    _next_activation_at_ms = Time.get_ticks_msec() + int(_first_delay_s * 1000.0)


func _on_run_finished(_p: Dictionary) -> void:
    _armed = false
    _paused = false
    _force_deactivate()


func _on_run_paused(_p: Dictionary) -> void:
    if _paused:
        return
    _paused = true
    _pause_started_ms = Time.get_ticks_msec()


func _on_run_resumed(_p: Dictionary) -> void:
    if not _paused:
        return
    _paused = false
    var offset: int = Time.get_ticks_msec() - _pause_started_ms
    _active_expires_at_ms += offset
    _next_activation_at_ms += offset


func _build_pool() -> void:
    _pool.clear()
    _pool.append(LowGravityModifier.new(_low_g_scale))
    _pool.append(SlowMotionModifier.new(_slow_mo_scale))
    _pool.append(SpeedBurstModifier.new(_burst_scale))


func _reload_tunables() -> void:
    _duration_s = GameplayConfig.get_float("modifier_default_duration_s")
    _min_gap_s = GameplayConfig.get_float("modifier_min_gap_s")
    _max_gap_s = GameplayConfig.get_float("modifier_max_gap_s")
    _first_delay_s = GameplayConfig.get_float("modifier_first_activation_s")
    _low_g_scale = GameplayConfig.get_float("modifier_low_gravity_scale")
    _slow_mo_scale = GameplayConfig.get_float("modifier_slow_motion_scale")
    _burst_scale = GameplayConfig.get_float("modifier_speed_burst_scale")


func _on_remote_config_activated(_p: Dictionary) -> void:
    _reload_tunables()
    _build_pool()
