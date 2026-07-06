## CollectibleSpawner
##
## Spawns reachable coin arcs and rare powerups ahead of the player.
class_name CollectibleSpawner
extends Node2D

const RNG := preload("res://src/core/rng.gd")
const Events := preload("res://src/core/events.gd")
const COIN_SCENE := preload("res://src/gameplay/collectibles/coin.tscn")
const POWERUP_SCENE := preload("res://src/gameplay/collectibles/powerup.tscn")

@export var target: NodePath

var _target: Node2D
var _rng: RandomNumberGenerator
var _next_coin_x: float = 1250.0
var _next_powerup_x: float = 5200.0
var _spawned: Array[Node2D] = []
var _coin_color: Color = Color(1.0, 0.933, 0.0, 1.0)
var _powerup_color: Color = Color(0.0, 0.941, 1.0, 1.0)


func _ready() -> void:
    _rng = RNG.stream("collectibles", 73)
    var n := get_node_or_null(target)
    if n is Node2D:
        _target = n
    EventBus.subscribe(Events.WORLD_THEME_CHANGED, _on_world_theme_changed)


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.WORLD_THEME_CHANGED, _on_world_theme_changed)


func _process(_delta: float) -> void:
    if _target == null:
        return
    var px := _target.position.x
    while _next_coin_x < px + 2600.0:
        _spawn_coin_arc(_next_coin_x)
        _next_coin_x += _rng.randf_range(620.0, 980.0)
    while _next_powerup_x < px + 3000.0:
        _spawn_powerup(_next_powerup_x)
        _next_powerup_x += _rng.randf_range(5200.0, 8200.0)
    _despawn_behind(px)


func _spawn_coin_arc(x: float) -> void:
    var count := _rng.randi_range(3, 6)
    var y := _rng.randf_range(520.0, 1850.0)
    var amp := _rng.randf_range(40.0, 120.0)
    for i in count:
        var coin := COIN_SCENE.instantiate() as Node2D
        coin.position = Vector2(x + float(i) * 95.0, y + sin(float(i) / maxf(1.0, float(count - 1)) * PI) * amp)
        add_child(coin)
        if coin.has_method("apply_theme_color"):
            coin.apply_theme_color(_coin_color)
        _spawned.append(coin)


func _spawn_powerup(x: float) -> void:
    if x < 5000.0:
        return
    var p := POWERUP_SCENE.instantiate() as PowerupCollectible
    if p == null:
        return
    p.position = Vector2(x, _rng.randf_range(720.0, 1680.0))
    var ids := ["shield", "magnet", "double_score"]
    p.powerup_id = ids[_rng.randi_range(0, ids.size() - 1)]
    p.duration_s = 8.0 if p.powerup_id != "shield" else 0.0
    add_child(p)
    p.apply_theme_color(_powerup_color)
    _spawned.append(p)


func _despawn_behind(px: float) -> void:
    var cutoff := px - 1400.0
    var kept: Array[Node2D] = []
    for item in _spawned:
        if not is_instance_valid(item):
            continue
        if item.position.x < cutoff:
            item.queue_free()
        else:
            kept.append(item)
    _spawned = kept


func _on_world_theme_changed(payload: Dictionary) -> void:
    var theme: Dictionary = payload.get("theme", {})
    _coin_color = theme.get("coin", _coin_color)
    _powerup_color = theme.get("powerup", _powerup_color)
    for item in _spawned:
        if not is_instance_valid(item):
            continue
        if item is Coin:
            item.apply_theme_color(_coin_color)
        elif item is PowerupCollectible:
            item.apply_theme_color(_powerup_color)
