## ISaveService
##
## Public contract for persistent player state.
## See docs/10_SAVE_SYSTEM.md for the full spec.
class_name ISaveService
extends RefCounted


func load_state() -> Result:
    return Result.err("not_implemented", "ISaveService.load_state")


func save_state(state: Dictionary) -> Result:
    return Result.err("not_implemented", "ISaveService.save_state")


func mutate(mutator: Callable) -> Result:
    return Result.err("not_implemented", "ISaveService.mutate")


func reset_all(confirm_token: String) -> Result:
    return Result.err("not_implemented", "ISaveService.reset_all")


func export_to_string() -> String:
    return ""


func import_from_string(_data: String) -> Result:
    return Result.err("not_implemented", "ISaveService.import_from_string")
