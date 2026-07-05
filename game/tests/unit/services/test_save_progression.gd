## Save progression contract tests.
extends "res://addons/gut/test.gd"

const InMemorySaveService := preload("res://src/services/save/in_memory_save_service.gd")
const SkinCatalog := preload("res://src/core/skin_catalog.gd")


func test_default_progression_includes_total_coins():
    var save := InMemorySaveService.new()
    var result: Result = save.load_state()
    assert_true(result.ok)
    var state: Dictionary = result.value
    var progression: Dictionary = state.get("progression", {})
    assert_true(progression.has("total_coins"))
    assert_eq(progression.total_coins, 0)
    assert_true(progression.has("purchased_skins"))
    assert_true(progression.purchased_skins.has(SkinCatalog.CLASSIC))
    assert_eq(progression.equipped_skin, SkinCatalog.CLASSIC)


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


func test_skin_purchase_and_equip_persists():
    var save := InMemorySaveService.new()
    save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = state.get("progression", {})
        progression["total_coins"] = 1000
        state["progression"] = progression
        return state)

    var selected := "emerald"
    var cost := int(SkinCatalog.by_id(selected).cost)
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = state.get("progression", {})
        var owned: Array = progression.get("purchased_skins", SkinCatalog.default_unlocked())
        progression["total_coins"] = int(progression.get("total_coins", 0)) - cost
        owned.append(selected)
        progression["purchased_skins"] = owned
        progression["equipped_skin"] = selected
        state["progression"] = progression
        return state)
    assert_true(result.ok)

    var loaded: Result = save.load_state()
    assert_true(loaded.ok)
    var state: Dictionary = loaded.value
    assert_true(state.progression.purchased_skins.has(selected))
    assert_eq(state.progression.equipped_skin, selected)
    assert_eq(int(state.progression.total_coins), 200)
