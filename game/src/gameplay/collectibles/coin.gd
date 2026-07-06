## Coin
##
## Lightweight collectible. Magnet pull is driven by the player's powerup state.
class_name Coin
extends Area2D

const Events := preload("res://src/core/events.gd")

@export var value: int = 1
@export var magnet_range: float = 520.0
@export var magnet_speed: float = 1200.0

var _collected: bool = false
var _origin_y: float = 0.0
var _phase: float = 0.0
var _face_color: Color = Color(1.0, 0.84, 0.0, 1.0)


func _ready() -> void:
    collision_layer = 0
    collision_mask = 1
    body_entered.connect(_on_body_entered)
    _origin_y = position.y
    _phase = randf() * TAU


func _process(delta: float) -> void:
    if _collected:
        return
    _phase += delta * 5.0
    position.y = _origin_y + sin(_phase) * 18.0
    scale.x = 0.75 + abs(sin(_phase * 1.8)) * 0.5
    _magnet_pull(delta)


func apply_theme_color(color: Color) -> void:
    _face_color = color
    var face := get_node_or_null("Face")
    if face is Polygon2D:
        (face as Polygon2D).color = _face_color
    var glow := get_node_or_null("Glow")
    if glow is Polygon2D:
        var glow_color := _face_color
        glow_color.a = 0.28
        (glow as Polygon2D).color = glow_color


func _magnet_pull(delta: float) -> void:
    var players := get_tree().get_nodes_in_group("player")
    if players.is_empty():
        return
    var player: Node = players[0]
    if not player.has_method("magnet_active") or not player.magnet_active():
        return
    if not (player is Node2D):
        return
    var target := (player as Node2D).global_position
    var dist := global_position.distance_to(target)
    if dist > magnet_range:
        return
    global_position = global_position.move_toward(target, magnet_speed * delta)


func _on_body_entered(body: Node) -> void:
    if _collected or not body.is_in_group("player"):
        return
    _collected = true
    monitoring = false
    EventBus.emit(Events.COIN_COLLECTED, {
        "value": value,
        "position": global_position,
        "t_ms": Time.get_ticks_msec(),
    })
    queue_free()
