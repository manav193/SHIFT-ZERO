## ObstacleSpawner
##
## Populates the infinite scrolling world with hazards. Independent of the
## WorldStreamer (different granularity).
##
## Fair-pattern algorithm (M1.5):
##   - Each registry entry declares a `safe_side` ("floor", "ceiling",
##     "either"). A "floor" obstacle requires the player be on the floor;
##     "ceiling" requires the ceiling; "either" is safe from any side.
##   - When the next candidate obstacle would force the player to switch
##     sides (safe_side flip vs. previous non-either), the spawner enforces
##     a minimum gap:
##         min_gap_dist = max(spacing_min, speed * fair_min_flip_time_s,
##                            fair_min_flip_gap)
##     so the player always has enough travel time to react + flip.
##   - Difficulty tightens spacing linearly via DifficultyDirector but never
##     below the fair-flip floor.
##   - Weighted-random type pick uses the seeded SPAWN RNG stream.
##
## Modularity: Obstacle types load from `data/obstacles/registry.json`;
## adding a new type is data-only.
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
## DifficultyDirector reference (optional -- degrades gracefully if unset).
@export var difficulty: NodePath

var _target: Node2D
var _difficulty: Node
var _types: Array = []          # Array<{id, scene, weight, safe_side}>
var _total_weight: float = 0.0
var _spawned: Array[Node2D] = []
var _next_spawn_x: float = 0.0
var _last_safe_side: String = "either"

var _spacing_min: float = 800.0
var _spacing_max: float = 1400.0
var _first_spawn_x: float = 1500.0
var _spawn_horizon_ahead: float = 2500.0
var _despawn_behind: float = 1500.0
var _base_speed: float = 420.0
var _fair_min_flip_time_s: float = 0.55
var _fair_min_flip_gap: float = 1000.0
var _rng: RandomNumberGenerator


func _ready() -> void:
    _reload_tunables()
    _rng = RNG.stream(RNG.STREAM_SPAWN, 42)
    _load_registry()
    _resolve_target()
    _resolve_difficulty()
    _next_spawn_x = _first_spawn_x
    EventBus.subscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    Log.debug("Obstacles", "spawner ready. types=%d spacing=[%.0f,%.0f] first_x=%.0f" % [
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
        var picked: Dictionary = _pick_type_fair()
        _spawn_at(_next_spawn_x, picked)
        var raw_gap: float = _rng.randf_range(_spacing_min, _spacing_max) * _spacing_scale()
        _next_spawn_x += _apply_fair_min_gap(picked, raw_gap)
        _last_safe_side = str(picked.get("safe_side", "either"))


func _apply_fair_min_gap(picked: Dictionary, raw_gap: float) -> float:
    var side: String = str(picked.get("safe_side", "either"))
    # A flip is only forced when both sides are non-either AND differ.
    var forces_flip: bool = (
        side != "either"
        and _last_safe_side != "either"
        and side != _last_safe_side
    )
    if not forces_flip:
        return raw_gap
    var current_speed: float = _base_speed * _speed_scale()
    var reaction_dist: float = current_speed * _fair_min_flip_time_s
    var floor_dist: float = maxf(reaction_dist, _fair_min_flip_gap)
    return maxf(raw_gap, floor_dist)


func _despawn_behind_player(px: float) -> void:
    var cutoff: float = px - _despawn_behind
    while not _spawned.is_empty() and _spawned[0].position.x < cutoff:
        var obs: Node2D = _spawned.pop_front()
        obs.queue_free()


func _spawn_at(x: float, type: Dictionary) -> void:
    var scene: PackedScene = type["scene"]
    var obs := scene.instantiate() as Node2D
    obs.position.x = x
    add_child(obs)
    _spawned.append(obs)


func _pick_type_fair() -> Dictionary:
    if _types.is_empty():
        return {}
    # Try up to 4 draws; if we keep landing on obstacles that would require
    # an impossible tight-flip, fall back to an "either" or same-side type.
    for _i in 4:
        var candidate: Dictionary = _pick_weighted()
        if _is_fair(candidate):
            return candidate
    # Fallback: search deterministically for a compatible type.
    for t in _types:
        if _is_fair(t):
            return t
    return _types[0]


func _is_fair(t: Dictionary) -> bool:
    var side: String = str(t.get("safe_side", "either"))
    if _last_safe_side == "either" or side == "either":
        return true
    return side == _last_safe_side or true  # flips are allowed; gap enforcer handles spacing


func _pick_weighted() -> Dictionary:
    if _total_weight <= 0.0:
        return _types[0]
    var r: float = _rng.randf() * _total_weight
    var cum: float = 0.0
    for t in _types:
        cum += float(t["weight"])
        if r <= cum:
            return t
    return _types.back()


func _spacing_scale() -> float:
    if _difficulty == null or not _difficulty.has_method("spacing_multiplier"):
        return 1.0
    return _difficulty.spacing_multiplier()


func _speed_scale() -> float:
    if _difficulty == null or not _difficulty.has_method("speed_multiplier"):
        return 1.0
    return _difficulty.speed_multiplier()


func _load_registry() -> void:
    if not FileAccess.file_exists(_REGISTRY_PATH):
        Log.warn("Obstacles", "no registry at %s" % _REGISTRY_PATH)
        return
    var f := FileAccess.open(_REGISTRY_PATH, FileAccess.READ)
    if f == null:
        return
    var parsed: Variant = JSON.parse_string(f.get_as_text())
    f.close()
    if not (parsed is Dictionary):
        Log.warn("Obstacles", "invalid registry format")
        return
    var entries: Variant = parsed.get("obstacle_types", [])
    if not (entries is Array):
        return
    for item in entries:
        if not (item is Dictionary):
            continue
        var scene_path: String = str(item.get("scene", ""))
        if not ResourceLoader.exists(scene_path):
            Log.warn("Obstacles", "registry scene missing: %s" % scene_path)
            continue
        var scene := load(scene_path) as PackedScene
        if scene == null:
            continue
        var weight: float = float(item.get("weight", 1.0))
        _types.append({
            "id": str(item.get("id", "")),
            "scene": scene,
            "weight": weight,
            "safe_side": str(item.get("safe_side", "either")),
        })
        _total_weight += weight


func _resolve_target() -> void:
    if target.is_empty():
        Log.warn("Obstacles", "no target assigned")
        return
    var n := get_node_or_null(target)
    if n is Node2D:
        _target = n


func _resolve_difficulty() -> void:
    if difficulty.is_empty():
        return
    var n := get_node_or_null(difficulty)
    if n != null:
        _difficulty = n


func _reload_tunables() -> void:
    _spacing_min = GameplayConfig.get_float("obstacle_spacing_min")
    _spacing_max = GameplayConfig.get_float("obstacle_spacing_max")
    _first_spawn_x = GameplayConfig.get_float("obstacle_first_spawn_x")
    _spawn_horizon_ahead = GameplayConfig.get_float("obstacle_spawn_horizon_x")
    _despawn_behind = GameplayConfig.get_float("obstacle_despawn_distance_behind")
    _base_speed = GameplayConfig.get_float("player_base_speed")
    _fair_min_flip_time_s = GameplayConfig.get_float("fair_min_flip_time_s")
    _fair_min_flip_gap = GameplayConfig.get_float("fair_min_flip_gap")


func _on_remote_config_activated(_payload: Dictionary) -> void:
    _reload_tunables()
