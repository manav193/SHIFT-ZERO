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
const _MEDIUM_START_X := 5000.0
const _HARD_START_X := 15000.0
const _VERY_HARD_START_X := 30000.0

## Node whose X-position drives spawn / despawn cycles. Usually the Player.
@export var target: NodePath
## DifficultyDirector reference (optional -- degrades gracefully if unset).
@export var difficulty: NodePath

var _target: Node2D
var _difficulty: Node
var _types: Array = []          # Array<{id, scene, weight, safe_side, category, min_spawn_x, scale_min, scale_max, y_min, y_max}>
var _total_weight: float = 0.0
var _spawned: Array[Node2D] = []
var _next_spawn_x: float = 0.0
var _last_safe_side: String = "either"
var _last_type_id: String = ""
var _last_spawn_extra_gap: float = 0.0

var _spacing_min: float = 800.0
var _spacing_max: float = 1400.0
var _first_spawn_x: float = 1500.0
var _spawn_horizon_ahead: float = 2500.0
var _despawn_behind: float = 1500.0
var _base_speed: float = 420.0
var _fair_min_flip_time_s: float = 0.55
var _fair_min_flip_gap: float = 1000.0
var _difficulty_scale_distance: float = 10000.0
var _rng: RandomNumberGenerator
var _spawning_enabled: bool = true
var _obstacle_palette: Array = []


func _ready() -> void:
	_reload_tunables()
	_rng = RNG.stream(RNG.STREAM_SPAWN, 42)
	_load_registry()
	_spawning_enabled = not _types.is_empty()
	_resolve_target()
	_resolve_difficulty()
	_next_spawn_x = _first_spawn_x
	EventBus.subscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
	EventBus.subscribe(Events.WORLD_THEME_CHANGED, _on_world_theme_changed)
	print("Obstacles", "spawner ready. types=%d spacing=[%.0f,%.0f] first_x=%.0f" % [
		_types.size(), _spacing_min, _spacing_max, _first_spawn_x,
	])


func _exit_tree() -> void:
	EventBus.unsubscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
	EventBus.unsubscribe(Events.WORLD_THEME_CHANGED, _on_world_theme_changed)


func _process(_delta: float) -> void:
	if _target == null or not _spawning_enabled:
		return
	var px: float = _target.position.x
	_spawn_while_needed(px)
	_despawn_behind_player(px)


func _spawn_while_needed(px: float) -> void:
	if _types.is_empty():
		_spawning_enabled = false
		return
	while _next_spawn_x < px + _spawn_horizon_ahead:
		var picked: Dictionary = _pick_type_fair(_next_spawn_x)
		if picked.is_empty():
			_spawning_enabled = false
			return
		picked = picked.duplicate()
		picked["_spawn_x"] = _next_spawn_x
		_spawn_at(_next_spawn_x, picked)
		var raw_gap: float = _gap_for(picked, _next_spawn_x)
		_next_spawn_x += _apply_fair_min_gap(picked, raw_gap) + _last_spawn_extra_gap
		_last_safe_side = str(picked.get("safe_side", "either"))
		_last_type_id = str(picked.get("id", ""))


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
	var spawn_x := float(picked.get("_spawn_x", 0.0))
	var floor_dist: float = maxf(reaction_dist, _fair_min_flip_gap * float(_profile_for_spawn(spawn_x).get("fair_gap_mult", 1.0)))
	return maxf(raw_gap, floor_dist)


func _despawn_behind_player(px: float) -> void:
	var cutoff: float = px - _despawn_behind
	while not _spawned.is_empty() and _spawned[0].position.x < cutoff:
		var obs: Node2D = _spawned.pop_front()
		EventBus.emit(Events.OBSTACLE_AVOIDED, {
			"id": str(obs.get_meta("obstacle_id", "")),
			"category": str(obs.get_meta("category", "ground")),
		})
		obs.queue_free()


func _spawn_at(x: float, type: Dictionary) -> void:
	if not type.has("scene"):
		_spawning_enabled = false
		return
	_last_spawn_extra_gap = 0.0
	var scene: PackedScene = type["scene"]
	var y := _y_for(type)
	var scale := _scale_for(type, x)
	_spawn_one(scene, Vector2(x, y), scale, str(type.get("id", "")), str(type.get("category", "ground")))
	if str(type.get("category", "")) == "bird" and _rng.randf() < float(_profile_for_spawn(x).get("bird_pair_chance", 0.0)):
		var pair_x := x + _rng.randf_range(220.0, 340.0)
		var pair_y := clampf(y + _rng.randf_range(-180.0, 180.0), float(type.get("y_min", y)), float(type.get("y_max", y)))
		var pair_scale := _scale_for(type, x)
		_spawn_one(scene, Vector2(pair_x, pair_y), pair_scale, str(type.get("id", "")), str(type.get("category", "ground")))
		_last_spawn_extra_gap = 260.0


func _spawn_one(scene: PackedScene, spawn_position: Vector2, spawn_scale: Vector2, obstacle_id: String, category: String) -> void:
	var obs := scene.instantiate() as Node2D
	obs.position = spawn_position
	obs.scale = spawn_scale
	obs.set_meta("obstacle_id", obstacle_id)
	obs.set_meta("category", category)
	add_child(obs)
	if obs.has_method("apply_theme_palette") and not _obstacle_palette.is_empty():
		obs.apply_theme_palette(_obstacle_palette)
	_spawned.append(obs)


func _pick_type_fair(spawn_x: float = 0.0) -> Dictionary:
	if _types.is_empty():
		return {}
	# Try up to 4 draws; if we keep landing on obstacles that would require
	# an impossible tight-flip, fall back to an "either" or same-side type.
	for _i in 8:
		var candidate: Dictionary = _pick_weighted(spawn_x)
		if _is_fair(candidate, spawn_x):
			return candidate
	# Fallback: search deterministically for a compatible type.
	for t in _types:
		if _is_fair(t, spawn_x):
			return t
	return {}


func _is_fair(t: Dictionary, spawn_x: float = 0.0) -> bool:
	if not _basic_allowed(t, spawn_x):
		return false
	var side: String = str(t.get("safe_side", "either"))
	if _last_safe_side == "either" or side == "either":
		return true
	return side == _last_safe_side


func _pick_weighted(spawn_x: float) -> Dictionary:
	var candidates := _candidate_types(spawn_x)
	if candidates.is_empty():
		return {}
	var total_weight := 0.0
	for t in candidates:
		total_weight += float(t["weight"])
	if total_weight <= 0.0:
		return candidates[0]
	var r: float = _rng.randf() * total_weight
	var cum: float = 0.0
	for t in candidates:
		cum += float(t["weight"])
		if r <= cum:
			return t
	return candidates.back()


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
		push_warning("Obstacles", "no registry at %s" % _REGISTRY_PATH)
		return
	var f := FileAccess.open(_REGISTRY_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		push_warning("Obstacles", "invalid registry format")
		return
	var entries: Variant = parsed.get("obstacle_types", [])
	if not (entries is Array):
		return
	for item in entries:
		if not (item is Dictionary):
			continue
		var scene_path: String = str(item.get("scene", ""))
		if not ResourceLoader.exists(scene_path):
			push_warning("Obstacles", "registry scene missing: %s" % scene_path)
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
			"category": str(item.get("category", "ground")),
			"min_spawn_x": float(item.get("min_spawn_x", 0.0)),
			"scale_min": _vector2_from_json(item.get("scale_min", [1.0, 1.0]), Vector2.ONE),
			"scale_max": _vector2_from_json(item.get("scale_max", [1.0, 1.0]), Vector2.ONE),
			"y_min": float(item.get("y_min", 1200.0)),
			"y_max": float(item.get("y_max", 1200.0)),
		})
		_total_weight += weight


func _resolve_target() -> void:
	if target.is_empty():
		push_warning("Obstacles", "no target assigned")
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
	_difficulty_scale_distance = GameplayConfig.get_float("obstacle_difficulty_scale_distance")


func _on_remote_config_activated(_payload: Dictionary) -> void:
	_reload_tunables()


func _on_world_theme_changed(payload: Dictionary) -> void:
	var theme: Dictionary = payload.get("theme", {})
	_obstacle_palette = theme.get("obstacles", [])
	for obs in _spawned:
		if is_instance_valid(obs) and obs.has_method("apply_theme_palette"):
			obs.apply_theme_palette(_obstacle_palette)


func _scale_for(type: Dictionary, spawn_x: float) -> Vector2:
	var min_scale: Vector2 = type.get("scale_min", Vector2.ONE)
	var max_scale: Vector2 = type.get("scale_max", Vector2.ONE)
	var ramp: float = maxf(_progress01(spawn_x), clampf(spawn_x / maxf(1.0, _difficulty_scale_distance), 0.0, 1.0))
	var target := min_scale.lerp(max_scale, ramp)
	return Vector2(
		_rng.randf_range(min_scale.x, target.x),
		_rng.randf_range(min_scale.y, target.y)
	)


func _vector2_from_json(value: Variant, fallback: Vector2) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


func _gap_for(type: Dictionary, spawn_x: float) -> float:
	var profile := _profile_for_spawn(spawn_x)
	var spacing_mult := float(profile.get("spacing_mult", 1.0))
	var jitter := _rng.randf_range(0.85, 1.15)
	var category := str(type.get("category", "ground"))
	if category == "bird":
		spacing_mult *= float(profile.get("bird_spacing_mult", 1.0))
	return _rng.randf_range(_spacing_min, _spacing_max) * _spacing_scale() * spacing_mult * jitter


func _y_for(type: Dictionary) -> float:
	var y_min := float(type.get("y_min", 1200.0))
	var y_max := float(type.get("y_max", y_min))
	return _rng.randf_range(minf(y_min, y_max), maxf(y_min, y_max))


func _candidate_types(spawn_x: float) -> Array:
	var out: Array = []
	for t in _types:
		if _basic_allowed(t, spawn_x):
			out.append(t)
	return out


func _basic_allowed(t: Dictionary, spawn_x: float) -> bool:
	if spawn_x < float(t.get("min_spawn_x", 0.0)):
		return false
	var profile := _profile_for_spawn(spawn_x)
	var allowed: Array = profile.get("categories", [])
	if not (str(t.get("category", "ground")) in allowed):
		return false
	if _last_type_id != "" and str(t.get("id", "")) == _last_type_id:
		return false
	return true


func _profile_for_spawn(spawn_x: float) -> Dictionary:
	if spawn_x < _MEDIUM_START_X:
		return {
			"tier": "easy",
			"spacing_mult": 1.3,
			"fair_gap_mult": 1.15,
			"categories": ["ground"],
			"bird_pair_chance": 0.0,
			"bird_spacing_mult": 1.0,
		}
	if spawn_x < _HARD_START_X:
		return {
			"tier": "medium",
			"spacing_mult": 0.82,
			"fair_gap_mult": 1.0,
			"categories": ["ground"],
			"bird_pair_chance": 0.0,
			"bird_spacing_mult": 1.0,
		}
	if spawn_x < _VERY_HARD_START_X:
		return {
			"tier": "hard",
			"spacing_mult": 0.66,
			"fair_gap_mult": 0.9,
			"categories": ["ground", "bird"],
			"bird_pair_chance": 0.2,
			"bird_spacing_mult": 0.9,
		}
	return {
		"tier": "very_hard",
		"spacing_mult": 0.52,
		"fair_gap_mult": 0.82,
		"categories": ["ground", "bird"],
		"bird_pair_chance": 0.38,
		"bird_spacing_mult": 0.78,
	}


func _progress01(spawn_x: float) -> float:
	return clampf(spawn_x / _VERY_HARD_START_X, 0.0, 1.0)
