## VfxSystem
##
## Autoloaded gameplay VFX. Spawns short-lived CPUParticles2D bursts in
## response to EventBus events. Particles self-free after emission.
##
## Cheap by design: capped emission counts, no textures (uses primitives),
## and hooked to a dedicated "vfx" node so pausing / freeing is trivial.
##
## Layer: systems (autoloaded).
extends Node

const Events := preload("res://src/core/events.gd")


func _ready() -> void:
    EventBus.subscribe(Events.PLAYER_GRAVITY_FLIPPED, _on_flipped)
    EventBus.subscribe(Events.PLAYER_LANDED, _on_landed)
    EventBus.subscribe(Events.RUN_FINISHED, _on_run_finished)
    print("VFX", "vfx system ready")


func _on_flipped(payload: Dictionary) -> void:
    var pos: Variant = payload.get("position", Vector2.ZERO)
    if not (pos is Vector2):
        return
    _burst(pos, Color(0.0, 0.941, 1.0, 1.0), 26, 320.0, 0.4)


func _on_landed(payload: Dictionary) -> void:
    var pos: Variant = payload.get("position", Vector2.ZERO)
    if not (pos is Vector2):
        return
    var surface: String = str(payload.get("surface", "floor"))
    var dir: Vector2 = Vector2.UP if surface == "floor" else Vector2.DOWN
    _burst_directional(pos, dir, Color(1.0, 0.169, 0.839, 1.0), 18, 240.0, 0.35)


func _on_run_finished(payload: Dictionary) -> void:
    var pos: Variant = payload.get("position", Vector2.ZERO)
    if not (pos is Vector2):
        pos = _find_player_position()
    if not (pos is Vector2):
        return
    _burst(pos, Color(1.0, 0.271, 0.325, 1.0), 60, 560.0, 0.85)


func _burst(pos: Vector2, color: Color, amount: int, speed: float, lifetime: float) -> void:
    var parent := _vfx_parent()
    if parent == null:
        return
    var p := CPUParticles2D.new()
    p.position = pos
    p.emitting = false
    p.one_shot = true
    p.explosiveness = 1.0
    p.amount = amount
    p.lifetime = lifetime
    p.spread = 180.0
    p.direction = Vector2.UP
    p.initial_velocity_min = speed * 0.5
    p.initial_velocity_max = speed
    p.gravity = Vector2(0.0, 200.0)
    p.scale_amount_min = 3.0
    p.scale_amount_max = 6.0
    p.color = color
    parent.add_child(p)
    p.emitting = true
    _autofree(p, lifetime + 0.5)


func _burst_directional(pos: Vector2, direction: Vector2, color: Color, amount: int, speed: float, lifetime: float) -> void:
    var parent := _vfx_parent()
    if parent == null:
        return
    var p := CPUParticles2D.new()
    p.position = pos
    p.emitting = false
    p.one_shot = true
    p.explosiveness = 1.0
    p.amount = amount
    p.lifetime = lifetime
    p.spread = 55.0
    p.direction = direction
    p.initial_velocity_min = speed * 0.4
    p.initial_velocity_max = speed
    p.gravity = Vector2(0.0, 400.0 * (1.0 if direction.y < 0.0 else -1.0))
    p.scale_amount_min = 2.5
    p.scale_amount_max = 5.0
    p.color = color
    parent.add_child(p)
    p.emitting = true
    _autofree(p, lifetime + 0.5)


func _autofree(node: Node, delay_s: float) -> void:
    var t := get_tree().create_timer(delay_s)
    t.timeout.connect(func() -> void:
        if is_instance_valid(node):
            node.queue_free())


## VFX must render in the world so they inherit the game camera transform.
## Preference order: (1) a node in the "vfx_root" group; (2) a node named
## "VfxRoot" under the current scene; (3) the current scene root.
func _vfx_parent() -> Node:
    var tree := get_tree()
    if tree == null:
        return null
    var nodes := tree.get_nodes_in_group("vfx_root")
    if not nodes.is_empty():
        return nodes[0]
    var scene := tree.current_scene
    if scene != null:
        var by_name := scene.get_node_or_null("VfxRoot")
        if by_name != null:
            return by_name
    return scene


func _find_player_position() -> Variant:
    var tree := get_tree()
    if tree == null:
        return null
    var players := tree.get_nodes_in_group("player")
    if players.is_empty():
        return null
    var p: Node = players[0]
    if p is Node2D:
        return (p as Node2D).position
    return null
