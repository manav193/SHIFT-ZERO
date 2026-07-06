## Shop
##
## Skin purchase/equip screen backed by ISaveService progression fields.
extends Control

const SkinCatalog := preload("res://src/core/skin_catalog.gd")
const RewardEconomy := preload("res://src/core/reward_economy.gd")
const PremiumUI := preload("res://src/presentation/ui/premium_ui.gd")
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
@onready var _preview_effects: Label = $Root/Body/Preview/Effects
@onready var _action_btn: Button = $Root/Body/Preview/ActionBtn

var _total_coins: int = 0
var _purchased: Array = []
var _equipped: String = SkinCatalog.CLASSIC
var _selected: String = SkinCatalog.CLASSIC
var _row_buttons: Dictionary = {}
var _preview_tween: Tween
var _fragments: Dictionary = {}
var _category: String = "shapes"


func _ready() -> void:
    PremiumUI.apply_screen(self)
    _back_btn.pressed.connect(_on_back_pressed)
    _action_btn.pressed.connect(_on_action_pressed)
    _wire_button(_back_btn)
    _wire_button(_action_btn)
    _load_progression()
    _build_skin_list()
    _select_skin(_equipped)
    PremiumUI.style_tree(self)
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
    var fragment_need := RewardEconomy.fragment_requirement(_selected)
    if fragment_need > 0:
        if int(_fragments.get(_selected, 0)) < fragment_need:
            return
        _purchase_skin_with_fragments(_selected, fragment_need)
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
    _fragments = progression.get("skin_fragments", {})
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
    _skin_list.add_child(_category_tabs())
    if _category == "effects":
        _add_effects_grid()
        return
    if _category == "trails":
        _add_trails_grid()
        return
    if _category == "shapes":
        _add_shapes_grid()
    for skin in SkinCatalog.all():
        var button := Button.new()
        button.custom_minimum_size = Vector2(0, 148)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.add_theme_font_size_override("font_size", 26)
        button.text = _row_text(skin)
        var id := str(skin.id)
        button.pressed.connect(func() -> void: _select_skin(id))
        _skin_list.add_child(button)
        _row_buttons[id] = button
        _wire_button(button)
        PremiumUI.style_button(button, _skin_accent(skin))


func _category_tabs() -> GridContainer:
    var grid := GridContainer.new()
    grid.columns = 4
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    for item in ["shapes", "skins", "trails", "effects"]:
        var b := Button.new()
        b.custom_minimum_size = Vector2(0, 72)
        b.text = item.to_upper()
        b.add_theme_font_size_override("font_size", 20)
        b.pressed.connect(func() -> void: _select_category(item))
        PremiumUI.style_button(b, PremiumUI.GOLD if item == _category else PremiumUI.CYAN)
        grid.add_child(b)
        _wire_button(b)
    return grid


func _select_category(category: String) -> void:
    _category = category
    _build_skin_list()


func _add_shapes_grid() -> void:
    var title := PremiumUI.card_text("PLAYABLE SHAPES", "Original procedural silhouettes from the approved UI direction.", PremiumUI.CYAN, 110)
    _skin_list.add_child(title)
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    _skin_list.add_child(grid)
    var names := PremiumUI.shape_names()
    var palette: Array[Color] = [PremiumUI.CYAN, PremiumUI.PINK, PremiumUI.GOLD, PremiumUI.VIOLET, PremiumUI.GREEN]
    for i in names.size():
        var accent: Color = palette[i % palette.size()]
        grid.add_child(PremiumUI.shape_tile(names[i], "preview", accent))


func _add_trails_grid() -> void:
    var title := PremiumUI.card_text("TRAILS", "Speed streaks, shards, flame, circuit, mist, and plasma previews.", PremiumUI.PINK, 110)
    _skin_list.add_child(title)
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    _skin_list.add_child(grid)
    for item in [
        ["Cyber Dash", PremiumUI.CYAN],
        ["Nova Flame", PremiumUI.GOLD],
        ["Void Mist", PremiumUI.VIOLET],
        ["Plasma Slash", PremiumUI.PINK],
        ["Crystal Shards", Color(0.58, 0.92, 1.0, 1.0)],
        ["Emerald Wake", PremiumUI.GREEN],
    ]:
        grid.add_child(PremiumUI.effect_tile(str(item[0]), item[1]))


func _add_effects_grid() -> void:
    var title := PremiumUI.card_text("EFFECTS", "Flip arcs, spawn rings, landing bursts, and death explosions.", PremiumUI.GOLD, 110)
    _skin_list.add_child(title)
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    _skin_list.add_child(grid)
    for item in [
        ["Flip Arc", PremiumUI.CYAN],
        ["Landing Burst", PremiumUI.GREEN],
        ["Spawn Ring", PremiumUI.VIOLET],
        ["Death Nova", PremiumUI.PINK],
        ["Boss Spark", PremiumUI.GOLD],
        ["Void Collapse", Color(0.34, 0.1, 0.7, 1.0)],
    ]:
        grid.add_child(PremiumUI.effect_tile(str(item[0]), item[1]))


func _select_skin(id: String) -> void:
    _selected = id
    var skin := SkinCatalog.by_id(id)
    _preview_name.text = str(skin.name).to_upper()
    _preview_player.apply_skin(skin)
    _preview_trail.default_color = _preview_player.trail_color()
    _preview_trail.width = _preview_player.trail_width()
    _preview_flash.color = skin.flash
    _preview_flash.modulate.a = 0.0
    _preview_state.text = _state_text(skin)
    _preview_effects.text = _effects_text(skin)
    _action_btn.text = _action_text(skin)
    _action_btn.disabled = _action_disabled(skin)
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


func _purchase_skin_with_fragments(id: String, cost: int) -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        return
    var result: Result = save.mutate(func(state: Dictionary) -> Dictionary:
        var progression: Dictionary = RewardEconomy.ensure_progression(state.get("progression", {}))
        var owned: Array = progression.get("purchased_skins", SkinCatalog.default_unlocked())
        var fragments: Dictionary = progression.get("skin_fragments", {})
        if int(fragments.get(id, 0)) >= cost and not owned.has(id):
            fragments[id] = int(fragments.get(id, 0)) - cost
            owned.append(id)
        progression["skin_fragments"] = fragments
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
    var fragment_need := RewardEconomy.fragment_requirement(id)
    var price := "%d FRAGS" % fragment_need if fragment_need > 0 else "%d COINS" % int(skin.cost)
    var status := "EQUIPPED" if id == _equipped else ("OWNED" if _is_owned(id) else price)
    return "%s\n%s  /  %s\n%s" % [str(skin.name).to_upper(), _rarity_text(skin), status, _effects_text(skin)]


func _state_text(skin: Dictionary) -> String:
    var id := str(skin.id)
    if id == _equipped:
        return "EQUIPPED"
    if _is_owned(id):
        return "OWNED"
    var fragment_need := RewardEconomy.fragment_requirement(id)
    if fragment_need > 0:
        return "LOCKED  %d/%d FRAGMENTS" % [int(_fragments.get(id, 0)), fragment_need]
    return "LOCKED  %d COINS" % int(skin.cost)


func _action_text(skin: Dictionary) -> String:
    var id := str(skin.id)
    if id == _equipped:
        return "EQUIPPED"
    if _is_owned(id):
        return "EQUIP"
    var fragment_need := RewardEconomy.fragment_requirement(id)
    if fragment_need > 0:
        var have := int(_fragments.get(id, 0))
        return "UNLOCK" if have >= fragment_need else "NEED %d FRAGS" % (fragment_need - have)
    if _total_coins < int(skin.cost):
        return "NEED %d" % (int(skin.cost) - _total_coins)
    return "PURCHASE"


func _action_disabled(skin: Dictionary) -> bool:
    var id := str(skin.id)
    if _is_owned(id):
        return false
    var fragment_need := RewardEconomy.fragment_requirement(id)
    if fragment_need > 0:
        return int(_fragments.get(id, 0)) < fragment_need
    return _total_coins < int(skin.cost)


func _effects_text(skin: Dictionary) -> String:
    return "TRAIL %s  /  FLIP %d  /  LAND %d  /  DEATH %d" % [
        str(skin.get("trail_style", "dash")).to_upper(),
        int(skin.get("flip_amount", 0)),
        int(skin.get("land_amount", 0)),
        int(skin.get("death_amount", 0)),
    ]


func _skin_accent(skin: Dictionary) -> Color:
    return skin.get("accent", skin.get("trail", Color(0.0, 0.941, 1.0, 1.0)))


func _rarity_text(skin: Dictionary) -> String:
    var cost := int(skin.get("cost", 0))
    if RewardEconomy.fragment_requirement(str(skin.id)) > 0:
        return "LEGENDARY"
    if cost >= 2500:
        return "MYTHIC"
    if cost >= 1200:
        return "EPIC"
    if cost >= 500:
        return "RARE"
    return "CLASSIC"


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
    _preview_trail.points = _preview_player.trail_points(Vector2(250, 205))


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
    var portrait := size.y > size.x
    _body.columns = 1 if portrait or size.x < 980.0 else 2
    _preview_player.scale = Vector2(1.8, 1.8) if portrait else Vector2(1.5, 1.5)
    _skin_list.add_theme_constant_override("separation", 16 if portrait else 12)
