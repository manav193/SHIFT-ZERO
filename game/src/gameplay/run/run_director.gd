## RunDirector
##
## Owns the lifecycle of a single run:
##   READY     -> INPUT_TAP  -> RUNNING
##   RUNNING   -> RUN_FINISHED (from Obstacle) -> GAME_OVER
##   GAME_OVER -> INPUT_TAP (after cooldown) -> reload scene
##
## Score & distance:
##   distance = max(0, target.x - start_x)
##   score    = floor(distance / score_distance_per_point)
##   Both exposed live via current_score() / current_distance().
##
## Restart uses `get_tree().reload_current_scene()` -- a clean scene reset.
##
## Layer: gameplay.
class_name RunDirector
extends Node

const GameplayConfig := preload("res://src/gameplay/gameplay_config.gd")
const Events := preload("res://src/core/events.gd")

enum State { READY, RUNNING, GAME_OVER }

## Node whose X-position measures distance. Usually the Player.
@export var target: NodePath
@export var auto_start_on_ready: bool = true

var _target: Node2D
var _state: int = State.READY
var _start_x: float = 0.0
var _game_over_t_ms: int = 0

var _distance_per_point: float = 4.0
var _restart_cooldown_ms: int = 500
var _score_bonus: int = 0
var _double_score_active: bool = false
var _double_score_start_distance: float = 0.0


func _ready() -> void:
    _reload_tunables()
    _resolve_target()
    if _target != null:
        _start_x = _target.position.x
    EventBus.subscribe(Events.INPUT_TAP, _on_input_tap)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.subscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    EventBus.subscribe(Events.POWERUP_ACTIVATED, _on_powerup_activated)
    EventBus.subscribe(Events.POWERUP_EXPIRED, _on_powerup_expired)
    print("Run", "director ready. state=READY start_x=%.0f" % _start_x)
    if auto_start_on_ready:
        call_deferred("_auto_start_if_ready")


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.INPUT_TAP, _on_input_tap)
    EventBus.unsubscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.unsubscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    EventBus.unsubscribe(Events.POWERUP_ACTIVATED, _on_powerup_activated)
    EventBus.unsubscribe(Events.POWERUP_EXPIRED, _on_powerup_expired)


## Read-only view of current state -- exposed for tests + HUD.
func state() -> int:
    return _state


func is_running() -> bool:
    return _state == State.RUNNING


func current_distance() -> float:
    return _current_distance()


func current_score() -> int:
    return _base_score() + _score_bonus + _active_double_score_bonus()


func _on_input_tap(_payload: Dictionary) -> void:
    match _state:
        State.READY:
            _begin_running()
        State.GAME_OVER:
            var now: int = Time.get_ticks_msec()
            if now - _game_over_t_ms >= _restart_cooldown_ms:
                _restart()


func _begin_running() -> void:
    if _state == State.RUNNING:
        return
    _state = State.RUNNING
    _score_bonus = 0
    _double_score_active = false
    _double_score_start_distance = _current_distance()
    print("Run", "state=RUNNING")
    # Deferred so RUN_STARTED subscribers activate AFTER the current
    # INPUT_TAP iteration completes.
    EventBus.call_deferred("emit", Events.RUN_STARTED, {"t_ms": Time.get_ticks_msec()})


func _auto_start_if_ready() -> void:
    if _state == State.READY:
        _begin_running()


func _on_run_finished(payload: Dictionary) -> void:
    if _state != State.RUNNING:
        return
    _state = State.GAME_OVER
    _game_over_t_ms = Time.get_ticks_msec()
    var distance: float = _current_distance()
    _bank_double_score_bonus()
    var score: int = current_score()
    print("Run", "state=GAME_OVER distance=%.0f score=%d cause=%s" % [
        distance, score, str(payload.get("cause", "?")),
    ])


func _restart() -> void:
    print("Run", "restart requested -- reloading scene")
    # Reset time_scale in case a modifier left it altered.
    Engine.time_scale = 1.0
    get_tree().reload_current_scene()


func _current_distance() -> float:
    if _target == null:
        return 0.0
    return maxf(0.0, _target.position.x - _start_x)


func _base_score() -> int:
    return int(_current_distance() / maxf(0.001, _distance_per_point))


func _active_double_score_bonus() -> int:
    if not _double_score_active:
        return 0
    var bonus_distance := maxf(0.0, _current_distance() - _double_score_start_distance)
    return int(bonus_distance / maxf(0.001, _distance_per_point))


func _bank_double_score_bonus() -> void:
    if not _double_score_active:
        return
    _score_bonus += _active_double_score_bonus()
    _double_score_active = false
    _double_score_start_distance = _current_distance()


func _resolve_target() -> void:
    if target.is_empty():
        push_warning("Run", "director has no target assigned")
        return
    var n := get_node_or_null(target)
    if n is Node2D:
        _target = n


func _reload_tunables() -> void:
    _distance_per_point = GameplayConfig.get_float("score_distance_per_point")
    _restart_cooldown_ms = GameplayConfig.get_int("run_restart_tap_cooldown_ms")


func _on_remote_config_activated(_payload: Dictionary) -> void:
    _reload_tunables()


func _on_powerup_activated(payload: Dictionary) -> void:
    if _state != State.RUNNING or str(payload.get("id", "")) != "double_score":
        return
    _bank_double_score_bonus()
    _double_score_active = true
    _double_score_start_distance = _current_distance()


func _on_powerup_expired(payload: Dictionary) -> void:
    if str(payload.get("id", "")) == "double_score":
        _bank_double_score_bonus()
