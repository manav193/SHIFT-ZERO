## CollectionBook
extends Control

const ProgressionContent := preload("res://src/core/progression_content.gd")
const PremiumUI := preload("res://src/presentation/ui/premium_ui.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _list: Container = $Root/Scroll/List
@onready var _overall: Label = $Root/Overall


func _ready() -> void:
    var shell := PremiumUI.screen(self, "COLLECTION", _on_back_pressed)
    _back_btn = shell.back
    _overall = PremiumUI.label("COMPLETION 0%", 44, Color(1.0, 0.933, 0.0, 1.0))
    shell.list.add_child(_overall)
    var grid := GridContainer.new()
    grid.columns = 2
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 16)
    grid.add_theme_constant_override("v_separation", 16)
    shell.list.add_child(grid)
    _list = grid
    _back_btn.pressed.connect(_on_back_pressed)
    _reload()


func _reload() -> void:
    for child in _list.get_children():
        child.queue_free()
    var progression := {}
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save != null:
        save.mutate(func(state: Dictionary) -> Dictionary:
            state["progression"] = ProgressionContent.ensure_progression(state.get("progression", {}))
            return state)
        var loaded: Result = save.load_state()
        if loaded.ok:
            progression = loaded.value.get("progression", {})
    progression = ProgressionContent.ensure_progression(progression)
    var rows := ProgressionContent.collection_progress(progression)
    var overall: Dictionary = rows.get("Overall", {"owned": 0, "total": 1})
    _overall.text = "COMPLETION %d%%" % _percent(overall)
    for key in ["Skins", "Themes", "Bosses", "Achievements", "Trails", "Effects", "Badges"]:
        _add_row(str(key), rows.get(key, {"owned": 0, "total": 1}))
    PremiumUI.style_tree(_list)


func _add_row(title: String, data: Dictionary) -> void:
    var panel := PremiumUI.card(Color(0.0, 0.941, 1.0, 1.0), 158)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    panel.add_child(v)
    v.add_child(PremiumUI.label(title.to_upper(), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
    v.add_child(PremiumUI.label("%d / %d" % [int(data.get("owned", 0)), int(data.get("total", 1))], 34, Color(1.0, 0.933, 0.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
    v.add_child(PremiumUI.progress(int(data.get("owned", 0)), int(data.get("total", 1))))
    _list.add_child(panel)


func _percent(data: Dictionary) -> int:
    return int(round(float(data.get("owned", 0)) / maxf(1.0, float(data.get("total", 1))) * 100.0))


func _on_back_pressed() -> void:
    var result: Result = SceneRouter.push(_MAIN_MENU_PATH)
    if not result.ok:
        push_error("CollectionBook", "back failed: %s" % result.error)
