## RewardEconomy tests.
extends "res://addons/gut/test.gd"

const RewardEconomy := preload("res://src/core/reward_economy.gd")


func test_login_claim_advances_streak_once_per_day():
    var progression := RewardEconomy.claim_login({}, "2026-07-06")
    assert_eq(int(progression.daily_login.streak), 1)
    assert_eq(str(progression.daily_login.last_claim_date), "2026-07-06")
    var coins := int(progression.total_coins)
    progression = RewardEconomy.claim_login(progression, "2026-07-06")
    assert_eq(int(progression.total_coins), coins)
    progression = RewardEconomy.claim_login(progression, "2026-07-07")
    assert_eq(int(progression.daily_login.streak), 2)


func test_spin_claim_applies_reward_and_cooldown():
    var progression := RewardEconomy.claim_spin({}, "2026-07-06", 12)
    assert_eq(str(progression.lucky_spin.last_spin_date), "2026-07-06")
    assert_false(RewardEconomy.can_spin(progression, "2026-07-06"))
    assert_false((progression.pending_rewards as Array).is_empty())


func test_chest_open_consumes_inventory_and_adds_reward():
    var progression := RewardEconomy.ensure_progression({})
    progression.chest_inventory["rare"] = 1
    progression = RewardEconomy.open_chest(progression, "rare", 4)
    assert_eq(int(progression.chest_inventory.rare), 0)
    assert_gt(int(progression.total_coins), 0)
    assert_gt(int(progression.player_xp), 0)


func test_booster_equip_and_consume_uses_inventory():
    var progression := RewardEconomy.ensure_progression({})
    progression.booster_inventory["shield"] = 1
    progression = RewardEconomy.set_booster_equipped(progression, "shield", true)
    assert_true((progression.equipped_boosters as Array).has("shield"))
    progression = RewardEconomy.consume_equipped_boosters(progression)
    assert_eq(int(progression.booster_inventory.shield), 0)
    assert_true((progression.active_run_boosters as Array).has("shield"))


func test_fragment_requirement_for_legendary_skins():
    assert_eq(RewardEconomy.fragment_requirement("dragon"), 80)
    assert_eq(RewardEconomy.fragment_requirement("phoenix"), 100)
    assert_eq(RewardEconomy.fragment_requirement("classic_runner"), 0)
