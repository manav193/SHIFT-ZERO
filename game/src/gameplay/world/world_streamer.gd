## WorldStreamer
##
## Maintains an infinite scrolling world by spawning `world_chunk.tscn`
## instances around the target's current chunk index and freeing chunks
## that fall outside `[current - behind, current + ahead]`.
##
## Chunks are indexed by `floor(target.position.x / chunk_width)`. A chunk
## at index `i` is placed at world-X `i * chunk_width` and covers the range
## `[i * chunk_width, (i + 1) * chunk_width]` in world space.
##
## Layer: gameplay. Values come from GameplayConfig.
class_name WorldStreamer
extends Node2D

const WORLD_CHUNK: PackedScene = preload("res://src/gameplay/world/world_chunk.tscn")
const GameplayConfig := preload("res://src/gameplay/gameplay_config.gd")
const Events := preload("res://src/core/events.gd")

## The node whose X-position dictates which chunks are alive. Usually the Player.
@export var target: NodePath

var _target: Node2D
var _chunks: Dictionary = {}    # int index -> Node2D chunk instance
var _last_index: int = -999999

var _chunk_width: float = 2000.0
var _ahead: int = 3
var _behind: int = 1


func _ready() -> void:
    _reload_tunables()
    EventBus.subscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)
    _resolve_target()
    if _target != null:
        _refresh_around(_index_of(_target))
    print("World", "streamer ready. chunk_w=%.0f ahead=%d behind=%d" % [
        _chunk_width, _ahead, _behind,
    ])


func _exit_tree() -> void:
    EventBus.unsubscribe(Events.REMOTE_CONFIG_ACTIVATED, _on_remote_config_activated)


func _process(_delta: float) -> void:
    if _target == null:
        return
    var idx: int = _index_of(_target)
    if idx == _last_index:
        return
    _refresh_around(idx)


func _refresh_around(center: int) -> void:
    _last_index = center
    var needed: Dictionary = {}
    for i in range(center - _behind, center + _ahead + 1):
        needed[i] = true
        if not _chunks.has(i):
            _spawn(i)
    for idx in _chunks.keys():
        if not needed.has(idx):
            _despawn(idx)


func _spawn(idx: int) -> void:
    var chunk := WORLD_CHUNK.instantiate() as Node2D
    chunk.position = Vector2(float(idx) * _chunk_width, 0.0)
    add_child(chunk)
    _chunks[idx] = chunk


func _despawn(idx: int) -> void:
    var chunk: Node2D = _chunks[idx]
    _chunks.erase(idx)
    chunk.queue_free()


func _index_of(node: Node2D) -> int:
    return int(floor(node.position.x / _chunk_width))


func _resolve_target() -> void:
    if target.is_empty():
        push_warning("World", "streamer has no target assigned")
        return
    var n := get_node_or_null(target)
    if n is Node2D:
        _target = n
    else:
        push_warning("World", "streamer target does not resolve to a Node2D")


func _reload_tunables() -> void:
    _chunk_width = GameplayConfig.get_float("world_chunk_width")
    _ahead = GameplayConfig.get_int("world_stream_ahead_chunks")
    _behind = GameplayConfig.get_int("world_stream_behind_chunks")


func _on_remote_config_activated(_payload: Dictionary) -> void:
    _reload_tunables()
