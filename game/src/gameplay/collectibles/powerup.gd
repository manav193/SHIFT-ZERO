## PowerupCollectible
##
## Applies a temporary player powerup on touch.
class_name PowerupCollectible
extends Area2D

const Events := preload("res://src/core/events.gd")

@export_enum("shield", "magnet", "double_score") var powerup_id: String = "shield"
@export var duration_s: float = 7.0

var _collected: bool = false
var _origin_y: float = 0.0
var _phase: float = 0.0
var _theme_color: Color = Color(0.0, 0.941, 1.0, 1.0)


func _ready() -> void:
    collision_layer = 0
    collision_mask = 1
    body_entered.connect(_on_body_entered)
    _origin_y = position.y
    _phase = randf() * TAU


func _process(delta: float) -> void:
    _phase += delta * 3.0
    position.y = _origin_y + sin(_phase) * 24.0
    rotation = sin(_phase) * 0.18


func apply_theme_color(color: Color) -> void:
    _theme_color = color
    var inner := get_node_or_null("Inner")
    if inner is Polygon2D:
        (inner as Polygon2D).color = _theme_color
    var outer := get_node_or_null("Outer")
    if outer is Polygon2D:
        var outer_color := _theme_color
        outer_color.a = 0.35
        (outer as Polygon2D).color = outer_color


func _on_body_entered(body: Node) -> void:
    if _collected or not body.is_in_group("player"):
        return
    if not body.has_method("apply_powerup"):
        return
    _collected = true
    monitoring = false
    body.apply_powerup(powerup_id, duration_s)
    EventBus.emit(Events.POWERUP_COLLECTED, {
        "id": powerup_id,
        "duration_s": duration_s,
        "position": global_position,
    })
    queue_free()
