## FileSystemSaveService
##
## Real persistent implementation of ISaveService. Writes to `user://save.json`
## as UTF-8 JSON. Loads at construction; mutations persist immediately.
##
## Layer: services.
class_name FileSystemSaveService
extends "res://src/services/save/i_save_service.gd"

const _PATH := "user://save.json"

var _state: Dictionary = {}


func _init() -> void:
    _load_from_disk()


func load_state() -> Result:
    return Result.ok_(_state.duplicate(true))


func save_state(state: Dictionary) -> Result:
    _state = state.duplicate(true)
    return _persist()


func mutate(mutator: Callable) -> Result:
    var next: Variant = mutator.call(_state.duplicate(true))
    if next is Dictionary:
        _state = next
        return _persist()
    return Result.err("bad_mutator", "mutator must return Dictionary")


func reset_all(confirm_token: String) -> Result:
    if confirm_token != "CONFIRM_WIPE":
        return Result.err("missing_confirmation", "reset_all requires confirm token")
    _state = _default_state()
    return _persist()


func export_to_string() -> String:
    return JSON.stringify(_state)


func import_from_string(data: String) -> Result:
    var parsed: Variant = JSON.parse_string(data)
    if parsed is Dictionary:
        _state = parsed
        return _persist()
    return Result.err("bad_json", "invalid save payload")


func _load_from_disk() -> void:
    if not FileAccess.file_exists(_PATH):
        _state = _default_state()
        return
    var f := FileAccess.open(_PATH, FileAccess.READ)
    if f == null:
        _state = _default_state()
        return
    var text := f.get_as_text()
    f.close()
    var parsed: Variant = JSON.parse_string(text)
    _state = parsed if parsed is Dictionary else _default_state()


func _persist() -> Result:
    var f := FileAccess.open(_PATH, FileAccess.WRITE)
    if f == null:
        return Result.err("save_failed", "cannot open %s for write" % _PATH)
    f.store_string(JSON.stringify(_state))
    f.close()
    return Result.ok_()


func _default_state() -> Dictionary:
    return {
        "schema_version": 1,
        "stats": {"best_score": 0, "best_distance": 0.0},
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
            },
            "unlocked_cosmetics": [],
            "equipped_cosmetics": {},
        },
        "entitlements": {"remove_ads": false, "owned_bundles": []},
        "consent": {"analytics": false, "personalized_ads": false, "crashlytics": false},
        "flags": {},
        "metadata": {},
    }
