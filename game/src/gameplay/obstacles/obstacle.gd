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

var _triggered: bool = false


func _ready() -> void:
    collision_layer = 0
    collision_mask = 1  # detect bodies on the default physics layer (player)
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
    if _triggered:
        return
    if not body.is_in_group("player"):
        return
    _triggered = true
    monitoring = false
    EventBus.emit(Events.RUN_FINISHED, {
        "cause": "obstacle",
        "obstacle_id": obstacle_id,
        "t_ms": Time.get_ticks_msec(),
    })
    Logger.info("Obstacle", "hit id=%s" % obstacle_id)
