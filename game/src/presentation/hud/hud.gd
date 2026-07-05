## HUD
##
## In-game overlay:
##   - Current score (top-center)
##   - Best score (top-right)
##   - Pause button (top-left)
##   - Pause modal (initially hidden)
##   - Game Over modal (initially hidden, shown on RUN_FINISHED)
##
## Reads current score by polling RunDirector.current_score() each frame.
## Reads best score from ISaveService at boot and on RUN_FINISHED. Persists
## a new best via SaveService.mutate.
##
## Layer: presentation.
extends Control

const Events := preload("res://src/core/events.gd")

@export var run_director: NodePath

@onready var _score_label: Label = $Top/Score
@onready var _best_label: Label = $Top/Best
@onready var _pause_btn: Button = $Top/PauseBtn
@onready var _pause_modal: Control = $PauseModal
@onready var _pause_resume_btn: Button = $PauseModal/Panel/V/ResumeBtn
@onready var _pause_restart_btn: Button = $PauseModal/Panel/V/RestartBtn
@onready var _go_modal: Control = $GameOverModal
@onready var _go_score: Label = $GameOverModal/Panel/V/Score
@onready var _go_best: Label = $GameOverModal/Panel/V/Best
@onready var _go_distance: Label = $GameOverModal/Panel/V/Distance
@onready var _go_restart_btn: Button = $GameOverModal/Panel/V/RestartBtn

var _director: Node
var _best_score: int = 0


func _ready() -> void:
    _director = get_node_or_null(run_director)
    _pause_modal.visible = false
    _go_modal.visible = false
    _pause_btn.pressed.connect(_on_pause_pressed)
    _pause_resume_btn.pressed.connect(_on_resume_pressed)
    _pause_restart_btn.pressed.connect(_on_restart_pressed)
    _go_restart_btn.pressed.connect(_on_restart_pressed)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    _load_best_score()
    _best_label.text = "BEST %d" % _best_score
    _score_label.text = "0"


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.RUN_FINISHED, _on_run_finished)


func _process(_delta: float) -> void:
    if _director == null or _go_modal.visible or _pause_modal.visible:
        return
    _score_label.text = str(_director.current_score())


func _on_pause_pressed() -> void:
    if _go_modal.visible:
        return
    get_tree().paused = true
    _pause_modal.visible = true
    EventBus.emit(Events.RUN_PAUSED, {})


func _on_resume_pressed() -> void:
    _pause_modal.visible = false
    get_tree().paused = false
    EventBus.emit(Events.RUN_RESUMED, {})


func _on_restart_pressed() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()


func _on_run_finished(_payload: Dictionary) -> void:
    var current: int = 0 if _director == null else _director.current_score()
    var distance: int = 0 if _director == null else int(_director.current_distance())
    var new_best: bool = current > _best_score
    if new_best:
        _best_score = current
        _persist_best_score(_best_score, distance)
    _go_score.text = "SCORE %d" % current
    _go_best.text = "BEST %d%s" % [_best_score, "  NEW!" if new_best else ""]
    _go_distance.text = "DISTANCE %d" % distance
    _go_modal.visible = true


func _load_best_score() -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var r: Result = save.load_state()
    if not r.ok:
        return
    var state: Dictionary = r.value
    var stats: Dictionary = state.get("stats", {})
    _best_score = int(stats.get("best_score", 0))


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
