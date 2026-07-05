## FlyingBird
##
## Simple moving obstacle for M2. The spawner owns placement and scaling;
## this script adds a small vertical bob so it reads as airborne.
extends "res://src/gameplay/obstacles/obstacle.gd"

@export var bob_amplitude: float = 90.0
@export var bob_speed: float = 2.2

var _origin_y: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
    super._ready()
    _origin_y = position.y
    _phase = randf() * TAU


func _process(delta: float) -> void:
    _phase += delta * bob_speed
    position.y = _origin_y + sin(_phase) * bob_amplitude
