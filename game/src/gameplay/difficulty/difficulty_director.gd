## DifficultyDirector
##
## Provides smooth, configurable difficulty curves. Starts counting when
## RUN_STARTED fires and freezes on RUN_FINISHED.
##
##   speed_multiplier(t)  = clamp(start + growth*t, start, max)
##   spacing_multiplier(t) = clamp(1 - shrink*t, min, 1.0)
##
## Player and ObstacleSpawner query these getters each frame. All curve
## parameters come from GameplayConfig.
class_name DifficultyDirector
extends Node

const GameplayConfig := preload("res://src/gameplay/gameplay_config.gd")
const Events := preload("res://src/core/events.gd")

var _running: bool = false
var _run_started_t: int = 0

var _speed_mult_start: float = 1.0
var _speed_mult_max: float = 2.0
var _speed_growth_per_s: float = 0.02
var _spacing_shrink_per_s: float = 0.008
var _spacing_min_mult: float = 0.55


func _ready() -> void:
    _reload_tunables()
    EventBus.subscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.subscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.unsubscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.unsubscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)


func speed_multiplier() -> float:
    return clampf(_speed_mult_start + _speed_growth_per_s * _elapsed_s(),
        _speed_mult_start, _speed_mult_max)


func spacing_multiplier() -> float:
    return clampf(1.0 - _spacing_shrink_per_s * _elapsed_s(),
        _spacing_min_mult, 1.0)


func elapsed_s() -> float:
    return _elapsed_s()


func _elapsed_s() -> float:
    if not _running:
        return 0.0
    return float(Time.get_ticks_msec() - _run_started_t) / 1000.0


func _on_run_started(_p: Dictionary) -> void:
    _running = true
    _run_started_t = Time.get_ticks_msec()


func _on_run_finished(_p: Dictionary) -> void:
    _running = false


func _reload_tunables() -> void:
    _speed_mult_start = GameplayConfig.get_float("difficulty_speed_mult_start")
    _speed_mult_max = GameplayConfig.get_float("difficulty_speed_mult_max")
    _speed_growth_per_s = GameplayConfig.get_float("difficulty_speed_growth_per_s")
    _spacing_shrink_per_s = GameplayConfig.get_float("difficulty_spacing_shrink_per_s")
    _spacing_min_mult = GameplayConfig.get_float("difficulty_spacing_min_mult")


func _on_remote_config_activated(_p: Dictionary) -> void:
    _reload_tunables()
