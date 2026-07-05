## Unit tests for the RNG named-stream contract.
##
## Ghost Runs (v1.1) depend on determinism guaranteed by these tests.
extends "res://addons/gut/test.gd"

const RNG := preload("res://src/core/rng.gd")


func test_same_seed_and_stream_produces_same_sequence():
    RNG.reset(1234)
    var a := RNG.stream(RNG.STREAM_WORLD, 1234)
    var s1 := [a.randi(), a.randi(), a.randi()]

    RNG.reset(1234)
    var b := RNG.stream(RNG.STREAM_WORLD, 1234)
    var s2 := [b.randi(), b.randi(), b.randi()]

    assert_eq(s1, s2)


func test_different_streams_are_independent():
    RNG.reset(42)
    var world := RNG.stream(RNG.STREAM_WORLD, 42)
    var cosmetic := RNG.stream(RNG.STREAM_COSMETIC, 42)
    # Consume cosmetic stream — must NOT affect world stream.
    cosmetic.randi()
    cosmetic.randi()

    RNG.reset(42)
    var world_alone := RNG.stream(RNG.STREAM_WORLD, 42)
    assert_eq(world.randi(), world_alone.randi())


func test_reset_clears_previous_streams():
    RNG.reset(7)
    var a := RNG.stream(RNG.STREAM_SPAWN, 7)
    var n1 := a.randi()

    RNG.reset(7)
    var b := RNG.stream(RNG.STREAM_SPAWN, 7)
    var n2 := b.randi()
    assert_eq(n1, n2)
