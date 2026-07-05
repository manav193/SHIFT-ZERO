## Save progression contract tests.
extends "res://addons/gut/test.gd"

const InMemorySaveService := preload("res://src/services/save/in_memory_save_service.gd")


func test_default_progression_includes_total_coins():
    var save := InMemorySaveService.new()
    var result: Result = save.load_state()
    assert_true(result.ok)
    var state: Dictionary = result.value
    var progression: Dictionary = state.get("progression", {})
    assert_true(progression.has("total_coins"))
    assert_eq(progression.total_coins, 0)


func test_total_coins_can_be_incremented():
    var save := InMemorySaveService.new()
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = state.get("progression", {})
        progression["total_coins"] = int(progression.get("total_coins", 0)) + 7
        state["progression"] = progression
        return state)
    assert_true(result.ok)

    var loaded: Result = save.load_state()
    assert_true(loaded.ok)
    var state: Dictionary = loaded.value
    assert_eq(int(state.progression.total_coins), 7)
