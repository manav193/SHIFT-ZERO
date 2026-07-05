## RNG
##
## Seeded random number generator with NAMED STREAMS.
## Cosmetic randomness must never affect gameplay randomness. Ghost Runs
## (v1.1) rely on this contract.
##
## Usage:
##   var world := RNG.stream("world", run_seed)
##   var n := world.randi_range(0, 3)
class_name RNG
extends RefCounted

const STREAM_WORLD    := "world"
const STREAM_SPAWN    := "spawn"
const STREAM_MODIFIER := "modifier"
const STREAM_COSMETIC := "cosmetic"
const STREAM_VFX      := "vfx"

static var _streams: Dictionary = {}   # name -> RandomNumberGenerator


static func stream(name: String, seed: int) -> RandomNumberGenerator:
    var key := "%s#%d" % [name, seed]
    var rng: RandomNumberGenerator = _streams.get(key)
    if rng == null:
        rng = RandomNumberGenerator.new()
        rng.seed = _derive_seed(name, seed)
        _streams[key] = rng
    return rng


## Fresh streams — used at the start of each run.
static func reset(seed: int) -> void:
    _streams.clear()
    for name in [STREAM_WORLD, STREAM_SPAWN, STREAM_MODIFIER, STREAM_COSMETIC, STREAM_VFX]:
        stream(name, seed)


static func _derive_seed(name: String, seed: int) -> int:
    # Cheap deterministic hash — good enough for stream separation.
    var h: int = seed
    for i in name.length():
        h = ((h * 1103515245) + name.unicode_at(i)) & 0x7fffffff
    return h
