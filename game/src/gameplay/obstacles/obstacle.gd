## Obstacle
##
## Shared base script for all hazards. Each obstacle scene (StaticBlock,
## CeilingSpike, FloorSpike, ...) attaches this script and provides its
## own visual, collision shape, and Y position.
##
## Behaviour:
##   - This Area2D detects a body from the "player" group entering.
##   - On entry it emits `RUN_FINISHED` on the EventBus and stops monitoring.
##   - It never physically blocks the player — layer=0 means the player
##     passes through visually until the game freezes.
##
## Layer: gameplay.
class_name Obstacle
extends Area2D

const Events := preload("res://src/core/events.gd")

## Stable identifier for the RUN_FINISHED payload. Used later by
## analytics + design telemetry to attribute deaths to obstacle types.
@export var obstacle_id: String = "unknown"

const _PALETTE := [
    Color(1.0, 0.271, 0.325, 1.0),
    Color(1.0, 0.933, 0.0, 1.0),
    Color(0.0, 0.941, 1.0, 1.0),
    Color(1.0, 0.169, 0.839, 1.0),
]

var _triggered: bool = false
var _origin_y: float = 0.0
var _idle_phase: float = 0.0
var _idle_amp: float = 0.0
var _idle_speed: float = 0.0
var _spawn_scale: Vector2 = Vector2.ONE
var _theme_palette: Array = []


func _ready() -> void:
    collision_layer = 0
    collision_mask = 1  # detect bodies on the default physics layer (player)
    body_entered.connect(_on_body_entered)
    _origin_y = position.y
    _idle_phase = randf() * TAU
    _idle_amp = randf_range(6.0, 18.0)
    _idle_speed = randf_range(0.8, 1.6)
    _spawn_scale = scale
    _apply_random_color()
    _play_spawn_in()


func _process(delta: float) -> void:
    _idle_phase += delta * _idle_speed
    position.y = _origin_y + sin(_idle_phase) * _idle_amp


func _on_body_entered(body: Node) -> void:
    if _triggered:
        return
    if not body.is_in_group("player"):
        return
    _triggered = true
    set_deferred("monitoring", false)
    if body.has_method("consume_shield") and body.consume_shield():
        print("Obstacle", "shield blocked id=%s" % obstacle_id)
        queue_free()
        return
    EventBus.emit(Events.RUN_FINISHED, {
        "cause": "obstacle",
        "obstacle_id": obstacle_id,
        "t_ms": Time.get_ticks_msec(),
    })
    print("Obstacle", "hit id=%s" % obstacle_id)


func _apply_random_color() -> void:
    var palette := _theme_palette if not _theme_palette.is_empty() else _PALETTE
    var color: Color = palette[randi() % palette.size()]
    for child in get_children():
        if child is CanvasItem and not (child is CollisionShape2D):
            (child as CanvasItem).modulate = color


func apply_theme_palette(palette: Array) -> void:
    _theme_palette = palette.duplicate()
    _apply_random_color()


func _play_spawn_in() -> void:
    scale = _spawn_scale * 0.35
    modulate.a = 0.0
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_BACK)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(self, "scale", _spawn_scale, 0.24)
    tween.parallel().tween_property(self, "modulate:a", 1.0, 0.18)
