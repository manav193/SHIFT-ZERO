## FlyingBird
##
## Simple moving obstacle for M2. The spawner owns placement and scaling;
## this script adds a small vertical bob so it reads as airborne.
extends "res://src/gameplay/obstacles/obstacle.gd"

@export var bob_amplitude: float = 90.0
@export var bob_speed: float = 2.2

var _bird_origin_y: float = 0.0
var _phase: float = 0.0
var _wing_phase: float = 0.0


func _ready() -> void:
    super._ready()
    _bird_origin_y = position.y
    _phase = randf() * TAU
    _wing_phase = randf() * TAU


func _process(delta: float) -> void:
    super._process(delta)
    _phase += delta * bob_speed
    position.y = _bird_origin_y + sin(_phase) * bob_amplitude
    _wing_phase += delta * 12.0
    var flap := sin(_wing_phase)
    $WingTop.scale.y = 1.0 + flap * 0.22
    $WingBottom.scale.y = 1.0 - flap * 0.22
    rotation = flap * 0.035
