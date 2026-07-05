## SceneRouter
##
## Small stack of scenes. Owns all scene transitions.
##   push()    — replaces the current scene with a new one
##   replace() — synonym for push (kept for clarity of intent)
##
## Full push/pop history + transitions land in M1. This M0 version
## is intentionally minimal.
extends Node

var _current: Node = null


func push(scene_path: String) -> Result:
    if not ResourceLoader.exists(scene_path):
        Log.error("SceneRouter", "scene not found: %s" % scene_path)
        return Result.err("scene_missing", scene_path)
    var packed := load(scene_path) as PackedScene
    if packed == null:
        return Result.err("scene_load_failed", scene_path)
    get_tree().change_scene_to_packed(packed)
    Log.info("SceneRouter", "push %s" % scene_path)
    return Result.ok_()


func replace(scene_path: String) -> Result:
    return push(scene_path)
