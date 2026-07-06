## InMemorySaveService
##
## Test / boot-fallback implementation. Never persists to disk.
class_name InMemorySaveService
extends "res://src/services/save/i_save_service.gd"

var _state: Dictionary = {
    "schema_version": 1,
    "player_id": "",
    "stats": {},
    "progression": {
        "total_coins": 0,
        "player_xp": 0,
        "player_level": 1,
        "purchased_skins": ["classic_runner"],
        "equipped_skin": "classic_runner",
        "unlocked_themes": ["neon_city"],
        "daily": {"last_refresh_date": "", "missions": []},
        "achievements_unlocked": [],
        "achievement_rewards_claimed": [],
        "bosses_seen": [],
        "bosses_defeated": [],
        "rare_chests": 0,
        "player_stats": {
            "total_runs": 0,
            "total_deaths": 0,
            "best_distance": 0,
            "best_score": 0,
            "total_play_time_s": 0,
            "gravity_flips": 0,
            "obstacles_avoided": 0,
            "birds_avoided": 0,
            "coins_collected": 0,
            "powerups_collected": 0,
            "highest_run_level": 1,
            "bosses_seen": 0,
            "bosses_defeated": 0,
            "longest_boss_survival_s": 0,
            "boss_no_damage_defeats": 0,
        },
        "unlocked_cosmetics": [],
        "equipped_cosmetics": {},
    },
    "entitlements": {"remove_ads": false, "owned_bundles": []},
    "consent": {"analytics": false, "personalized_ads": false, "crashlytics": false},
    "flags": {},
    "metadata": {},
}


func load_state() -> Result:
    return Result.ok_(_state.duplicate(true))


func save_state(state: Dictionary) -> Result:
    _state = state.duplicate(true)
    return Result.ok_()


func mutate(mutator: Callable) -> Result:
    var next: Variant = mutator.call(_state.duplicate(true))
    if next is Dictionary:
        _state = next
        return Result.ok_()
    return Result.err("bad_mutator", "mutator must return Dictionary")


func reset_all(confirm_token: String) -> Result:
    if confirm_token != "CONFIRM_WIPE":
        return Result.err("missing_confirmation", "reset_all requires confirm token")
    _state = {"schema_version": 1}
    return Result.ok_()


func export_to_string() -> String:
    return JSON.stringify(_state)


func import_from_string(data: String) -> Result:
    var parsed: Variant = JSON.parse_string(data)
    if parsed is Dictionary:
        _state = parsed
        return Result.ok_()
    return Result.err("bad_json", "invalid save payload")
