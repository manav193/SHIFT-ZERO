## ObstacleSpawner
##
## Populates the infinite scrolling world with hazards. Independent of the
## WorldStreamer (different granularity: obstacles are more numerous and
## have variable spacing).
##
## Algorithm:
##   Maintains `_next_spawn_x`. On each frame, while
##   `_next_spawn_x < player.x + spawn_horizon`, it instantiates one
##   obstacle at `_next_spawn_x` and advances `_next_spawn_x` by a random
##   gap in `[spacing_min, spacing_max]` drawn from the seeded SPAWN RNG.
##   Obstacles with X < player.x - despawn_behind are freed.
##
## Modularity:
##   Obstacle types are loaded from `data/obstacles/registry.json`.
##   Adding a new type is data-only — no changes to this script.
##
## Layer: gameplay.
class_name ObstacleSpawner
extends Node2D

const GameplayConfig := preload("res://src/gameplay/gameplay_config.gd")
const Events := preload("res://src/core/events.gd")
const RNG := preload("res://src/core/rng.gd")

const _REGISTRY_PATH := "res://data/obstacles/registry.json"

## Node whose X-position drives spawn / despawn cycles. Usually the Player.
@export var target: NodePath

var _target: Node2D
var _types: Array = []          # Array<{id: String, scene: PackedScene, weight: float}>
var _total_weight: float = 0.0
var _spawned: Array[Node2D] = []
var _next_spawn_x: float = 0.0

var _spacing_min: float = 800.0
var _spacing_max: float = 1400.0
var _first_spawn_x: float = 1500.0
var _spawn_horizon_ahead: float = 2500.0
var _despawn_behind: float = 1500.0
var _rng: RandomNumberGenerator


func _ready() -> void:
    _reload_tunables()
    # For M1.3 the spawn RNG uses a fixed seed. Run-time seed will be
    # supplied by RunDirector in a later milestone.
    _rng = RNG.stream(RNG.STREAM_SPAWN, 42)
    _load_registry()
    _resolve_target()
    _next_spawn_x = _first_spawn_x
    EventBus.subscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    Logger.debug("Obstacles", "spawner ready. types=%d spacing=[%.0f,%.0f] first_x=%.0f" % [
        _types.size(), _spacing_min, _spacing_max, _first_spawn_x,
    ])


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)


func _process(_delta: float) -> void:
    if _target == null:
        return
    var px: float = _target.position.x
    _spawn_while_needed(px)
    _despawn_behind_player(px)


func _spawn_while_needed(px: float) -> void:
    while _next_spawn_x < px + _spawn_horizon_ahead:
        _spawn_at(_next_spawn_x)
        var gap: float = _rng.randf_range(_spacing_min, _spacing_max)
        _next_spawn_x += gap


func _despawn_behind_player(px: float) -> void:
    var cutoff: float = px - _despawn_behind
    while not _spawned.is_empty() and _spawned[0].position.x < cutoff:
        var obs: Node2D = _spawned.pop_front()
        obs.queue_free()


func _spawn_at(x: float) -> void:
    if _types.is_empty():
        return
    var type: Dictionary = _pick_type()
    var scene: PackedScene = type["scene"]
    var obs := scene.instantiate() as Node2D
    obs.position.x = x
    add_child(obs)
    _spawned.append(obs)


func _pick_type() -> Dictionary:
    if _total_weight <= 0.0:
        return _types[0]
    var r: float = _rng.randf() * _total_weight
    var cum: float = 0.0
    for t in _types:
        cum += float(t["weight"])
        if r <= cum:
            return t
    return _types.back()


func _load_registry() -> void:
    if not FileAccess.file_exists(_REGISTRY_PATH):
        Logger.warn("Obstacles", "no registry at %s" % _REGISTRY_PATH)
        return
    var f := FileAccess.open(_REGISTRY_PATH, FileAccess.READ)
    if f == null:
        return
    var parsed: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    if not (parsed is Dictionary):
        Logger.warn("Obstacles", "invalid registry format")
        return
    var entries: Variant = parsed.get("obstacle_types", [])
    if not (entries is Array):
        return
    for item in entries:
        if not (item is Dictionary):
            continue
        var scene_path: String = str(item.get("scene", ""))
        if not ResourceLoader.exists(scene_path):
            Logger.warn("Obstacles", "registry scene missing: %s" % scene_path)
            continue
        var scene := load(scene_path) as PackedScene
        if scene == null:
            continue
        var weight: float = float(item.get("weight", 1.0))
        _types.append({
            "id": str(item.get("id", "")),
            "scene": scene,
            "weight": weight,
        })
        _total_weight += weight


func _resolve_target() -> void:
    if target.is_empty():
        Logger.warn("Obstacles", "no target assigned")
        return
    var n := get_node_or_null(target)
    if n is Node2D:
        _target = n


func _reload_tunables() -> void:
    _spacing_min = GameplayConfig.get_float("obstacle_spacing_min")
    _spacing_max = GameplayConfig.get_float("obstacle_spacing_max")
    _first_spawn_x = GameplayConfig.get_float("obstacle_first_spawn_x")
    _spawn_horizon_ahead = GameplayConfig.get_float("obstacle_spawn_horizon_x")
    _despawn_behind = GameplayConfig.get_float("obstacle_despawn_distance_behind")


func _on_remote_config_activated(_payload: Dictionary) -> void:
    _reload_tunables()
