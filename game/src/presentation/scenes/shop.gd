## Shop
##
## Skin purchase/equip screen backed by ISaveService progression fields.
extends Control

const SkinCatalog := preload("res://src/core/skin_catalog.gd")
const _MAIN_MENU_PATH := "res://src/presentation/scenes/main_menu.tscn"

@onready var _back_btn: Button = $Root/Header/BackBtn
@onready var _coins_label: Label = $Root/Header/Coins
@onready var _body: GridContainer = $Root/Body
@onready var _skin_list: VBoxContainer = $Root/Body/List/Scroll/SkinList
@onready var _preview_player: SkinModel = $Root/Body/Preview/PreviewBox/Player
@onready var _preview_flash: ColorRect = $Root/Body/Preview/PreviewBox/Flash
@onready var _preview_trail: Line2D = $Root/Body/Preview/PreviewBox/Trail
@onready var _preview_name: Label = $Root/Body/Preview/Name
@onready var _preview_state: Label = $Root/Body/Preview/State
@onready var _action_btn: Button = $Root/Body/Preview/ActionBtn

var _total_coins: int = 0
var _purchased: Array = []
var _equipped: String = SkinCatalog.CLASSIC
var _selected: String = SkinCatalog.CLASSIC
var _row_buttons: Dictionary = {}
var _preview_tween: Tween


func _ready() -> void:
    _back_btn.pressed.connect(_on_back_pressed)
    _action_btn.pressed.connect(_on_action_pressed)
    _wire_button(_back_btn)
    _wire_button(_action_btn)
    _load_progression()
    _build_skin_list()
    _select_skin(_equipped)
    _update_layout()


func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and is_node_ready():
        _update_layout()


func _on_back_pressed() -> void:
    var result: Result = SceneRouter.push(_MAIN_MENU_PATH)
    if not result.ok:
        push_error("Shop", "back failed: %s" % result.error)


func _on_action_pressed() -> void:
    var skin := SkinCatalog.by_id(_selected)
    if _is_owned(_selected):
        _equip_skin(_selected)
        return
    var cost := int(skin.cost)
    if _total_coins < cost:
        return
    _purchase_skin(_selected, cost)


func _load_progression() -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        _purchased = SkinCatalog.default_unlocked()
        return
    var result: Result = save.load_state()
    if not result.ok:
        _purchased = SkinCatalog.default_unlocked()
        return
    var state: Dictionary = result.value
    var progression: Dictionary = state.get("progression", {})
    _total_coins = int(progression.get("total_coins", 0))
    _purchased = progression.get("purchased_skins", SkinCatalog.default_unlocked())
    if not _purchased.has(SkinCatalog.CLASSIC):
        _purchased.append(SkinCatalog.CLASSIC)
    _equipped = str(progression.get("equipped_skin", SkinCatalog.CLASSIC))
    if str(SkinCatalog.by_id(_equipped).id) != _equipped:
        _equipped = SkinCatalog.CLASSIC
    if not _purchased.has(_equipped):
        _equipped = SkinCatalog.CLASSIC
    _coins_label.text = "COINS %d" % _total_coins


func _build_skin_list() -> void:
    for child in _skin_list.get_children():
        child.queue_free()
    _row_buttons.clear()
    for skin in SkinCatalog.all():
        var button := Button.new()
        button.custom_minimum_size = Vector2(0, 82)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.add_theme_font_size_override("font_size", 28)
        button.text = _row_text(skin)
        var id := str(skin.id)
        button.pressed.connect(func() -> void: _select_skin(id))
        _skin_list.add_child(button)
        _row_buttons[id] = button
        _wire_button(button)


func _select_skin(id: String) -> void:
    _selected = id
    var skin := SkinCatalog.by_id(id)
    _preview_name.text = str(skin.name)
    _preview_player.apply_skin(skin)
    _preview_trail.default_color = _preview_player.trail_color()
    _preview_trail.width = _preview_player.trail_width()
    _preview_flash.color = skin.flash
    _preview_flash.modulate.a = 0.0
    _preview_state.text = _state_text(skin)
    _action_btn.text = _action_text(skin)
    _action_btn.disabled = not _is_owned(id) and _total_coins < int(skin.cost)
    _animate_preview(skin)


func _purchase_skin(id: String, cost: int) -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = state.get("progression", {})
        var coins := int(progression.get("total_coins", 0))
        var owned: Array = progression.get("purchased_skins", SkinCatalog.default_unlocked())
        if coins >= cost and not owned.has(id):
            coins -= cost
            owned.append(id)
        progression["total_coins"] = coins
        progression["purchased_skins"] = owned
        progression["equipped_skin"] = id
        state["progression"] = progression
        return state)
    if not result.ok:
        return
    _load_progression()
    _selected = id
    _equipped = id
    _build_skin_list()
    _select_skin(id)


func _equip_skin(id: String) -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = state.get("progression", {})
        var owned: Array = progression.get("purchased_skins", SkinCatalog.default_unlocked())
        if owned.has(id):
            progression["equipped_skin"] = id
        state["progression"] = progression
        return state)
    if not result.ok:
        return
    _equipped = id
    _build_skin_list()
    _select_skin(id)


func _is_owned(id: String) -> bool:
    return _purchased.has(id)


func _row_text(skin: Dictionary) -> String:
    var id := str(skin.id)
    var status := "EQUIPPED" if id == _equipped else ("OWNED" if _is_owned(id) else "%d COINS" % int(skin.cost))
    return "%s    %s" % [str(skin.name), status]


func _state_text(skin: Dictionary) -> String:
    var id := str(skin.id)
    if id == _equipped:
        return "EQUIPPED"
    if _is_owned(id):
        return "OWNED"
    return "LOCKED  %d COINS" % int(skin.cost)


func _action_text(skin: Dictionary) -> String:
    var id := str(skin.id)
    if id == _equipped:
        return "EQUIPPED"
    if _is_owned(id):
        return "EQUIP"
    if _total_coins < int(skin.cost):
        return "NEED %d" % (int(skin.cost) - _total_coins)
    return "PURCHASE"


func _animate_preview(skin: Dictionary) -> void:
    if _preview_tween != null and _preview_tween.is_valid():
        _preview_tween.kill()
    _preview_player.scale = Vector2(1.75, 1.18)
    _preview_flash.modulate.a = 0.8
    _preview_tween = create_tween()
    _preview_tween.set_trans(Tween.TRANS_BACK)
    _preview_tween.set_ease(Tween.EASE_OUT)
    _preview_tween.tween_property(_preview_player, "scale", Vector2(1.5, 1.5), 0.18)
    _preview_tween.parallel().tween_property(_preview_flash, "modulate:a", 0.0, 0.22)
    _preview_trail.points = PackedVector2Array([
        Vector2(92, 210),
        Vector2(156, 188),
        Vector2(238, 200),
        Vector2(292, 174),
    ])


func _wire_button(button: Button) -> void:
    button.mouse_entered.connect(func() -> void: _button_to(button, Vector2(1.02, 1.02), 0.08))
    button.mouse_exited.connect(func() -> void: _button_to(button, Vector2.ONE, 0.10))
    button.button_down.connect(func() -> void: _button_to(button, Vector2(0.96, 0.96), 0.05))
    button.button_up.connect(func() -> void: _button_to(button, Vector2(1.02, 1.02), 0.08))


func _button_to(button: Button, target_scale: Vector2, duration: float) -> void:
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", target_scale, duration)


func _update_layout() -> void:
    _body.columns = 1 if size.x < 900.0 else 2
