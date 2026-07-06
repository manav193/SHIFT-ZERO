## RunDirector lifecycle tests.
extends "res://addons/gut/test.gd"

const Events := preload("res://src/core/events.gd")
const RunDirector := preload("res://src/gameplay/run/run_director.gd")

var _started_events: Array = []


func before_each():
    _started_events = []
    EventBus.clear_all()


func after_each():
    EventBus.clear_all()


func _on_started(payload: Dictionary) -> void:
    _started_events.append(payload)


func test_auto_start_on_scene_ready_emits_run_started():
    var root := Node2D.new()
    var player := Node2D.new()
    player.name = "Player"
    player.position = Vector2(540, 1200)
    root.add_child(player)

    var run := RunDirector.new()
    run.target = NodePath("../Player")
    root.add_child(run)
    EventBus.subscribe(Events.RUN_STARTED, _on_started)
    add_child_autofree(root)

    await get_tree().process_frame
    await get_tree().process_frame

    assert_true(run.is_running(), "RunDirector should auto-enter RUNNING after scene ready")
    assert_eq(_started_events.size(), 1, "RUN_STARTED should be emitted once")
