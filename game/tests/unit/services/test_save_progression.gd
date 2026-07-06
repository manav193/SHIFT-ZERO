## Save progression contract tests.
extends "res://addons/gut/test.gd"

const InMemorySaveService := preload("res://src/services/save/in_memory_save_service.gd")
const SkinCatalog := preload("res://src/core/skin_catalog.gd")
const ProgressionRules := preload("res://src/core/progression_rules.gd")


func test_default_progression_includes_total_coins():
    var save := InMemorySaveService.new()
    var result: Result = save.load_state()
    assert_true(result.ok)
    var state: Dictionary = result.value
    var progression: Dictionary = state.get("progression", {})
    assert_true(progression.has("total_coins"))
    assert_eq(progression.total_coins, 0)
    assert_eq(progression.player_xp, 0)
    assert_eq(progression.player_level, 1)
    assert_true(progression.has("daily"))
    assert_true(progression.has("achievements_unlocked"))
    assert_true(progression.has("achievement_rewards_claimed"))
    assert_true(progression.has("player_stats"))
    assert_true(progression.has("purchased_skins"))
    assert_true(progression.purchased_skins.has(SkinCatalog.CLASSIC))
    assert_eq(progression.equipped_skin, SkinCatalog.CLASSIC)
    assert_true(progression.has("unlocked_themes"))
    assert_true(progression.unlocked_themes.has("neon_city"))
    assert_true(progression.has("bosses_seen"))
    assert_true(progression.has("bosses_defeated"))
    assert_true(progression.has("rare_chests"))
    assert_true(progression.player_stats.has("bosses_seen"))
    assert_true(progression.player_stats.has("bosses_defeated"))
    assert_true(progression.player_stats.has("longest_boss_survival_s"))
    assert_true(progression.has("daily_login"))
    assert_true(progression.has("lucky_spin"))
    assert_true(progression.has("chest_inventory"))
    assert_true(progression.has("booster_inventory"))
    assert_true(progression.has("equipped_boosters"))
    assert_true(progression.has("skin_fragments"))
    assert_true(progression.has("pending_rewards"))


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
        progression["total_coins"] = 2000
        state["progression"] = progression
        return state)

    var selected := "alien"
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
    assert_eq(int(state.progression.total_coins), 800)


func test_player_xp_and_level_persist():
    var save := InMemorySaveService.new()
    var earned := 200
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = state.get("progression", {})
        var next_xp := int(progression.get("player_xp", 0)) + earned
        progression["player_xp"] = next_xp
        progression["player_level"] = ProgressionRules.level_for_total_xp(next_xp)
        state["progression"] = progression
        return state)
    assert_true(result.ok)

    var loaded: Result = save.load_state()
    assert_true(loaded.ok)
    var state: Dictionary = loaded.value
    assert_eq(int(state.progression.player_xp), 200)
    assert_eq(int(state.progression.player_level), 2)
