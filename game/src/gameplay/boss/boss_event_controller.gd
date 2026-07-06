## BossEventController
##
## Schedules and runs special survival encounters during long endless runs.
## It owns procedural boss visuals and attack hazards, then returns to normal
## spawning after the timer expires.
extends Node2D

const Events := preload("res://src/core/events.gd")
const BossCatalog := preload("res://src/core/boss_catalog.gd")
const ProgressionContent := preload("res://src/core/progression_content.gd")
const ThemeCatalog := preload("res://src/core/theme_catalog.gd")

@export var target: NodePath

enum State { IDLE, WARNING, ACTIVE }

var _target: Node2D
var _state: int = State.IDLE
var _start_x: float = 0.0
var _boss: Dictionary = {}
var _warning_left_s: float = 0.0
var _boss_left_s: float = 0.0
var _boss_duration_s: float = 0.0
var _attack_timer_s: float = 0.0
var _last_warning_countdown: int = -1
var _seen_this_run: Array = []
var _next_random_distance_m: int = 25000
var _damage_taken: bool = false
var _visual_root: Node2D


func _ready() -> void:
    var n := get_node_or_null(target)
    if n is Node2D:
        _target = n
        _start_x = _target.position.x
    _visual_root = Node2D.new()
    _visual_root.name = "BossVisuals"
    add_child(_visual_root)
    EventBus.subscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.subscribe(Events.SHIELD_USED, _on_shield_used)


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.RUN_STARTED, _on_run_started)
    EventBus.unsubscribe(Events.RUN_FINISHED, _on_run_finished)
    EventBus.unsubscribe(Events.SHIELD_USED, _on_shield_used)


func _process(delta: float) -> void:
    if _target == null:
        return
    match _state:
        State.IDLE:
            _maybe_schedule()
        State.WARNING:
            _update_warning(delta)
        State.ACTIVE:
            _update_active(delta)


func _on_run_started(_payload: Dictionary) -> void:
    if _target != null:
        _start_x = _target.position.x
    _state = State.IDLE
    _seen_this_run.clear()
    _next_random_distance_m = 25000
    _damage_taken = false
    _clear_visuals()


func _on_run_finished(_payload: Dictionary) -> void:
    if _state == State.ACTIVE or _state == State.WARNING:
        EventBus.emit(Events.BOSS_FAILED, {"id": str(_boss.get("id", "")), "name": str(_boss.get("name", ""))})
    _state = State.IDLE
    _clear_visuals()


func _on_shield_used(_payload: Dictionary) -> void:
    if _state == State.ACTIVE:
        _damage_taken = true


func _maybe_schedule() -> void:
    var distance_m := _distance_m()
    var boss := BossCatalog.next_scheduled_boss(distance_m, _seen_this_run)
    if boss.is_empty():
        return
    if distance_m >= 25000 and distance_m < _next_random_distance_m:
        return
    if distance_m >= 25000:
        _next_random_distance_m = distance_m + 5000
    _begin_warning(boss)


func _begin_warning(boss: Dictionary) -> void:
    _boss = boss
    _warning_left_s = 3.0
    _last_warning_countdown = -1
    _damage_taken = false
    _state = State.WARNING
    _seen_this_run.append(str(_boss.id))
    _persist_seen(str(_boss.id))
    _emit_warning()
    _spawn_warning_visual()


func _update_warning(delta: float) -> void:
    _warning_left_s -= delta
    _emit_warning()
    if _warning_left_s <= 0.0:
        _begin_active()


func _emit_warning() -> void:
    var countdown := maxi(0, int(ceil(_warning_left_s)))
    if countdown == _last_warning_countdown:
        return
    _last_warning_countdown = countdown
    EventBus.emit(Events.BOSS_WARNING, {
        "id": str(_boss.id),
        "name": str(_boss.name),
        "countdown": countdown,
        "color": _boss.get("color", Color.WHITE),
    })


func _begin_active() -> void:
    _state = State.ACTIVE
    _boss_duration_s = float(_boss.get("duration_s", 24.0))
    _boss_left_s = _boss_duration_s
    _attack_timer_s = 0.1
    _clear_visuals()
    _spawn_boss_body()
    EventBus.emit(Events.BOSS_STARTED, {
        "id": str(_boss.id),
        "name": str(_boss.name),
        "duration_s": _boss_duration_s,
        "color": _boss.get("color", Color.WHITE),
    })


func _update_active(delta: float) -> void:
    _boss_left_s -= delta
    _attack_timer_s -= delta
    _animate_boss_body(delta)
    if _attack_timer_s <= 0.0:
        _spawn_attack()
    EventBus.emit(Events.BOSS_PROGRESS, {
        "id": str(_boss.id),
        "name": str(_boss.name),
        "remaining_s": maxf(0.0, _boss_left_s),
        "duration_s": _boss_duration_s,
    })
    if _boss_left_s <= 0.0:
        _defeat_boss()


func _spawn_attack() -> void:
    match str(_boss.id):
        BossCatalog.SKY_HUNTER:
            _attack_timer_s = 2.4
            _spawn_side_sweep()
        BossCatalog.LASER_WALL:
            _attack_timer_s = 2.0
            _spawn_laser_wall()
        BossCatalog.METEOR_STORM:
            _attack_timer_s = 1.4
            _spawn_meteor()
        BossCatalog.GRAVITY_STORM:
            _attack_timer_s = 2.8
            _spawn_gravity_pulse()
        _:
            _attack_timer_s = 2.2


func _defeat_boss() -> void:
    var id := str(_boss.id)
    var name := str(_boss.name)
    var survived := int(round(_boss_duration_s))
    var reward: Dictionary = _boss.get("reward", {})
    _persist_defeat(id, survived, not _damage_taken)
    EventBus.emit(Events.BOSS_DEFEATED, {
        "id": id,
        "name": name,
        "coins": int(reward.get("coins", 0)),
        "xp": int(reward.get("xp", 0)),
        "rare_chest_chance": float(reward.get("rare_chest_chance", 0.0)),
        "no_damage": not _damage_taken,
        "color": _boss.get("color", Color.WHITE),
    })
    _state = State.IDLE
    _clear_visuals()


func _spawn_warning_visual() -> void:
    _clear_visuals()
    var color: Color = _boss.get("color", Color.WHITE)
    for i in 3:
        var ring := Polygon2D.new()
        ring.position = _target.position + Vector2(620.0 + float(i) * 120.0, 0.0)
        ring.polygon = PackedVector2Array([Vector2(-70, -70), Vector2(70, -70), Vector2(70, 70), Vector2(-70, 70)])
        ring.color = Color(color.r, color.g, color.b, 0.22)
        _visual_root.add_child(ring)


func _spawn_boss_body() -> void:
    var color: Color = _boss.get("color", Color.WHITE)
    var body := Polygon2D.new()
    body.name = "BossBody"
    body.position = _target.position + Vector2(920.0, -360.0)
    body.color = color
    match str(_boss.id):
        BossCatalog.SKY_HUNTER:
            body.polygon = PackedVector2Array([Vector2(-180, 0), Vector2(-40, -95), Vector2(185, -20), Vector2(70, 20), Vector2(185, 85), Vector2(-30, 80)])
        BossCatalog.LASER_WALL:
            body.polygon = PackedVector2Array([Vector2(-120, -180), Vector2(120, -180), Vector2(120, 180), Vector2(-120, 180)])
        BossCatalog.METEOR_STORM:
            body.polygon = PackedVector2Array([Vector2(0, -170), Vector2(140, -40), Vector2(85, 130), Vector2(-95, 135), Vector2(-145, -25)])
        BossCatalog.GRAVITY_STORM:
            body.polygon = PackedVector2Array([Vector2(0, -160), Vector2(138, -80), Vector2(138, 80), Vector2(0, 160), Vector2(-138, 80), Vector2(-138, -80)])
    _visual_root.add_child(body)


func _animate_boss_body(delta: float) -> void:
    var body := _visual_root.get_node_or_null("BossBody")
    if body is Node2D:
        var node := body as Node2D
        node.position.x = _target.position.x + 900.0 + sin(Time.get_ticks_msec() * 0.0015) * 90.0
        node.position.y += sin(Time.get_ticks_msec() * 0.003) * delta * 120.0
        node.rotation = sin(Time.get_ticks_msec() * 0.002) * 0.08


func _spawn_side_sweep() -> void:
    var top_attack := randi() % 2 == 0
    var y := 520.0 if top_attack else 1880.0
    var size := Vector2(180.0, 820.0)
    _spawn_warning_hazard(Vector2(_target.position.x + 1280.0, y), size, 0.65, 1.0)


func _spawn_laser_wall() -> void:
    var gap_center: float = 720.0 + abs(sin(Time.get_ticks_msec() * 0.001)) * 930.0
    var x := _target.position.x + 1240.0
    _spawn_warning_hazard(Vector2(x, gap_center - 520.0), Vector2(150.0, 760.0), 0.55, 1.05)
    _spawn_warning_hazard(Vector2(x, gap_center + 520.0), Vector2(150.0, 760.0), 0.55, 1.05)


func _spawn_meteor() -> void:
    var y_positions := [520.0, 920.0, 1480.0, 1880.0]
    var y: float = y_positions[randi() % y_positions.size()]
    var x := _target.position.x + randf_range(900.0, 1500.0)
    _spawn_warning_hazard(Vector2(x, y), Vector2(210.0, 210.0), 0.75, 0.9)


func _spawn_gravity_pulse() -> void:
    var scale := 0.62 if randi() % 2 == 0 else 1.32
    EventBus.emit(Events.BOSS_GRAVITY_PULSE, {"scale": scale, "duration_s": 1.6})
    _spawn_ring(_target.position + Vector2(780.0, 0.0), _boss.get("color", Color.WHITE))


func _spawn_warning_hazard(pos: Vector2, size: Vector2, warn_s: float, active_s: float) -> void:
    var color: Color = _boss.get("color", Color.WHITE)
    var warning := ColorRect.new()
    warning.color = Color(color.r, color.g, color.b, 0.26)
    warning.position = pos - size * 0.5
    warning.size = size
    _visual_root.add_child(warning)
    var timer := get_tree().create_timer(warn_s)
    timer.timeout.connect(func() -> void:
        if not is_instance_valid(warning):
            return
        warning.queue_free()
        _spawn_hazard(pos, size, color, active_s))


func _spawn_hazard(pos: Vector2, size: Vector2, color: Color, active_s: float) -> void:
    var hazard := Area2D.new()
    hazard.name = "BossHazard"
    hazard.position = pos
    hazard.collision_layer = 0
    hazard.collision_mask = 1
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = size
    shape.shape = rect
    hazard.add_child(shape)
    var visual := ColorRect.new()
    visual.position = -size * 0.5
    visual.size = size
    visual.color = Color(color.r, color.g, color.b, 0.72)
    hazard.add_child(visual)
    hazard.body_entered.connect(_on_hazard_body_entered)
    _visual_root.add_child(hazard)
    var tween := create_tween()
    tween.tween_property(hazard, "modulate:a", 0.0, active_s)
    tween.tween_callback(func() -> void:
        if is_instance_valid(hazard):
            hazard.queue_free())


func _on_hazard_body_entered(body: Node) -> void:
    if _state != State.ACTIVE or not body.is_in_group("player"):
        return
    if body.has_method("consume_shield") and body.consume_shield():
        _damage_taken = true
        return
    EventBus.emit(Events.RUN_FINISHED, {
        "cause": "boss",
        "boss_id": str(_boss.get("id", "")),
        "t_ms": Time.get_ticks_msec(),
    })


func _spawn_ring(pos: Vector2, color: Color) -> void:
    var ring := Polygon2D.new()
    ring.position = pos
    ring.polygon = PackedVector2Array([Vector2(0, -130), Vector2(112, -65), Vector2(112, 65), Vector2(0, 130), Vector2(-112, 65), Vector2(-112, -65)])
    ring.color = Color(color.r, color.g, color.b, 0.24)
    _visual_root.add_child(ring)
    var tween := create_tween()
    tween.tween_property(ring, "scale", Vector2(2.2, 2.2), 0.5)
    tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.5)
    tween.tween_callback(func() -> void:
        if is_instance_valid(ring):
            ring.queue_free())


func _persist_seen(boss_id: String) -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = ProgressionContent.ensure_progression(state.get("progression", {}))
        progression = BossCatalog.apply_boss_seen(progression, boss_id)
        progression = ProgressionContent.update_achievements(progression)
        state["progression"] = progression
        return state)


func _persist_defeat(boss_id: String, survived_s: int, no_damage: bool) -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = ProgressionContent.ensure_progression(state.get("progression", {}))
        progression = BossCatalog.apply_boss_defeat(progression, boss_id, survived_s, no_damage)
        progression = ProgressionContent.update_achievements(progression)
        progression = ThemeCatalog.unlock_available(progression)
        state["progression"] = progression
        return state)


func _clear_visuals() -> void:
    for child in _visual_root.get_children():
        child.queue_free()


func _distance_m() -> int:
    if _target == null:
        return 0
    return int(maxf(0.0, _target.position.x - _start_x) / 100.0)
