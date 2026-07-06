## CollectionBook
extends Control

const ProgressionContent := preload("res://src/core/progression_content.gd")
const PremiumUI := preload("res://src/presentation/ui/premium_ui.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _list: VBoxContainer = $Root/Scroll/List
@onready var _overall: Label = $Root/Overall


func _ready() -> void:
    PremiumUI.apply_screen(self)
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
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(0, 108)
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.02, 0.03, 0.06, 0.82)
    style.border_color = Color(0.0, 0.941, 1.0, 0.55)
    style.set_border_width_all(2)
    style.set_corner_radius_all(8)
    panel.add_theme_stylebox_override("panel", style)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    panel.add_child(v)
    var label := Label.new()
    label.text = "%s  %d/%d" % [title.to_upper(), int(data.get("owned", 0)), int(data.get("total", 1))]
    label.add_theme_font_size_override("font_size", 30)
    label.add_theme_color_override("font_color", Color.WHITE)
    v.add_child(label)
    var bar := ProgressBar.new()
    bar.custom_minimum_size = Vector2(0, 24)
    bar.max_value = maxi(1, int(data.get("total", 1)))
    bar.value = int(data.get("owned", 0))
    bar.show_percentage = false
    v.add_child(bar)
    _list.add_child(panel)
    PremiumUI.style_panel(panel)


func _percent(data: Dictionary) -> int:
    return int(round(float(data.get("owned", 0)) / maxf(1.0, float(data.get("total", 1))) * 100.0))


func _on_back_pressed() -> void:
    var result: Result = SceneRouter.push(_MAIN_MENU_PATH)
    if not result.ok:
        push_error("CollectionBook", "back failed: %s" % result.error)
