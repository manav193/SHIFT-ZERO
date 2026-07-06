## MainMenu
##
## Cinematic mobile home screen built from procedural Godot UI/shapes.
extends Control

const ProgressionRules := preload("res://src/core/progression_rules.gd")
const ProgressionContent := preload("res://src/core/progression_content.gd")
const SkinCatalog := preload("res://src/core/skin_catalog.gd")
const ThemeCatalog := preload("res://src/core/theme_catalog.gd")
const RewardEconomy := preload("res://src/core/reward_economy.gd")
const PremiumUI := preload("res://src/presentation/ui/premium_ui.gd")

const _GAME_WORLD_PATH := "res://src/gameplay/game_world/game_world.tscn"
const _SETTINGS_PATH := "res://src/presentation/scenes/settings.tscn"
const _SHOP_PATH := "res://src/presentation/scenes/shop.tscn"
const _DAILY_PATH := "res://src/presentation/scenes/daily_missions.tscn"
const _ACHIEVEMENTS_PATH := "res://src/presentation/scenes/achievements.tscn"
const _STATISTICS_PATH := "res://src/presentation/scenes/statistics.tscn"
const _THEME_GALLERY_PATH := "res://src/presentation/scenes/theme_gallery.tscn"
const _DAILY_LOGIN_PATH := "res://src/presentation/scenes/daily_login.tscn"
const _LUCKY_SPIN_PATH := "res://src/presentation/scenes/lucky_spin.tscn"
const _CHESTS_PATH := "res://src/presentation/scenes/chests.tscn"
const _COLLECTION_PATH := "res://src/presentation/scenes/collection_book.tscn"

var _progression: Dictionary = {}
var _skin: Dictionary = {}
var _theme: Dictionary = {}
var _root: Control
var _world: Node2D
var _showcase: SkinModel
var _trail: Line2D
var _content: MarginContainer
var _more_panel: PanelContainer
var _phase: float = 0.0


func _ready() -> void:
    var legacy := get_node_or_null("Center")
    if legacy != null:
        legacy.visible = false
    _load_progression()
    _build()
    _layout()


func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and is_node_ready():
        _layout()


func _process(delta: float) -> void:
    _phase += delta
    if _world != null:
        _world.position.x = sin(_phase * 0.22) * 18.0
    if _showcase != null:
        _showcase.rotation = sin(_phase * 0.9) * 0.045
        _showcase.position.y += sin(_phase * 1.8) * 0.18
        _trail.points = _showcase.trail_points(_showcase.global_position)


func _load_progression() -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        _progression = ProgressionContent.ensure_progression({})
    else:
        save.mutate(func(state: Dictionary) -> Dictionary:
            state["progression"] = ProgressionContent.ensure_progression(state.get("progression", {}))
            return state)
        var result: Result = save.load_state()
        _progression = result.value.get("progression", {}) if result.ok else {}
        _progression = ProgressionContent.ensure_progression(_progression)
    _skin = SkinCatalog.by_id(str(_progression.get("equipped_skin", SkinCatalog.CLASSIC)))
    var themes := ThemeCatalog.unlocked_theme_ids(_progression)
    _theme = ThemeCatalog.by_id(str(themes.front() if not themes.is_empty() else ThemeCatalog.NEON_CITY))


func _build() -> void:
    _root = Control.new()
    _root.name = "HomeRoot"
    _root.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(_root)
    _build_cinematic_background()
    _content = MarginContainer.new()
    _content.set_anchors_preset(Control.PRESET_FULL_RECT)
    _root.add_child(_content)
    _build_content()
    PremiumUI.style_tree(self)


func _build_cinematic_background() -> void:
    var sky := ColorRect.new()
    sky.set_anchors_preset(Control.PRESET_FULL_RECT)
    sky.color = _theme.get("sky_top", Color(0.01, 0.016, 0.04, 1.0))
    _root.add_child(sky)

    var glow := ColorRect.new()
    glow.anchor_top = 0.45
    glow.anchor_right = 1.0
    glow.anchor_bottom = 1.0
    glow.color = _theme.get("sky_bottom", Color(0.07, 0.025, 0.12, 1.0))
    glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(glow)

    _world = Node2D.new()
    _root.add_child(_world)
    var bands: Array = _theme.get("bands", [])
    for i in 18:
        var building := Polygon2D.new()
        var w := 74.0 + float((i * 31) % 86)
        var h := 160.0 + float((i * 59) % 380)
        var x := -150.0 + float(i) * 128.0
        building.polygon = PackedVector2Array([Vector2(x, 1080), Vector2(x + w, 1080), Vector2(x + w, 880 - h), Vector2(x, 880 - h)])
        building.color = bands[i % bands.size()] if not bands.is_empty() else Color(0.02, 0.08, 0.12, 0.76)
        _world.add_child(building)
        if i % 2 == 0:
            var sign := ColorRect.new()
            sign.position = Vector2(x + w * 0.55, 900 - h)
            sign.size = Vector2(10, h * 0.52)
            sign.color = _theme.get("particle", Color(0.0, 0.941, 1.0, 0.65))
            _world.add_child(sign)

    var road := Polygon2D.new()
    road.polygon = PackedVector2Array([Vector2(130, 1120), Vector2(1520, 1120), Vector2(930, 695), Vector2(680, 695)])
    road.color = Color(0.01, 0.012, 0.03, 0.9)
    _root.add_child(road)

    _trail = Line2D.new()
    _trail.width = 28.0
    _trail.default_color = _skin.get("trail", Color(0.0, 0.941, 1.0, 0.7))
    _trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
    _trail.end_cap_mode = Line2D.LINE_CAP_ROUND
    _root.add_child(_trail)

    _showcase = SkinModel.new()
    _showcase.name = "ShowcaseCharacter"
    var hero_skin := SkinCatalog.by_id("phoenix")
    if str(hero_skin.get("id", "")) == "":
        hero_skin = _skin
    _showcase.apply_skin(hero_skin)
    _root.add_child(_showcase)

    var particles := CPUParticles2D.new()
    particles.position = Vector2(820, 520)
    particles.amount = 46
    particles.lifetime = 3.0
    particles.emitting = true
    particles.speed_scale = 0.42
    particles.spread = 180.0
    particles.gravity = Vector2(0, -10)
    particles.initial_velocity_min = 18.0
    particles.initial_velocity_max = 54.0
    particles.scale_amount_min = 2.0
    particles.scale_amount_max = 5.0
    particles.color = _theme.get("particle", Color(0.0, 0.941, 1.0, 0.75))
    _root.add_child(particles)

    var dim := ColorRect.new()
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    dim.color = Color(0, 0, 0, 0.18)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(dim)


func _build_content() -> void:
    var stack := VBoxContainer.new()
    stack.name = "HomeStack"
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_theme_constant_override("separation", 18)
    _content.add_child(stack)

    stack.add_child(_top_bar())
    stack.add_child(_logo_lockup())
    var hero_spacer := Control.new()
    hero_spacer.name = "HeroSpacer"
    hero_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(hero_spacer)
    stack.add_child(_start_cluster())
    stack.add_child(_reward_strip())
    stack.add_child(_bottom_nav())
    _more_panel = _more_menu()
    _more_panel.visible = false
    stack.add_child(_more_panel)


func _top_bar() -> Control:
    var row := HBoxContainer.new()
    row.name = "TopBar"
    row.custom_minimum_size = Vector2(0, 92)
    row.add_theme_constant_override("separation", 14)
    var xp := int(_progression.get("player_xp", 0))
    var level := int(_progression.get("player_level", ProgressionRules.level_for_total_xp(xp)))
    row.add_child(_profile_chip(level, xp))
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(spacer)
    row.add_child(_currency_chip("$", int(_progression.get("total_coins", 0)), Color(1.0, 0.76, 0.05, 1.0)))
    row.add_child(_currency_chip("C", _chest_total(), Color(0.0, 0.82, 1.0, 1.0)))
    return row


func _logo_lockup() -> VBoxContainer:
    var logo := VBoxContainer.new()
    logo.name = "LogoLockup"
    logo.alignment = BoxContainer.ALIGNMENT_CENTER
    logo.add_theme_constant_override("separation", 0)
    var title := _label("SHIFT ZERO", 58, Color.WHITE)
    title.add_theme_color_override("font_shadow_color", Color(0.0, 0.82, 1.0, 0.75))
    title.add_theme_constant_override("shadow_offset_x", 0)
    title.add_theme_constant_override("shadow_offset_y", 4)
    logo.add_child(title)
    logo.add_child(_label("ENDLESS RUNNER", 18, Color(0.62, 0.82, 1.0, 1.0)))
    return logo


func _profile_chip(level: int, xp: int) -> PanelContainer:
    var panel := _panel(Color(0.01, 0.015, 0.04, 0.78), _skin.get("accent", Color.WHITE), 14)
    panel.custom_minimum_size = Vector2(360, 86)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 14)
    panel.add_child(row)
    var portrait_box := Control.new()
    portrait_box.custom_minimum_size = Vector2(72, 72)
    row.add_child(portrait_box)
    var portrait := SkinModel.new()
    portrait.scale = Vector2(0.5, 0.5)
    portrait.position = Vector2(36, 38)
    portrait.apply_skin(_skin)
    portrait_box.add_child(portrait)
    var text := VBoxContainer.new()
    text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(text)
    text.add_child(_label("LEVEL %d" % level, 24, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
    text.add_child(_label(ProgressionRules.prestige_rank_for_level(level).to_upper(), 18, Color(0.0, 0.941, 1.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
    var bar := ProgressBar.new()
    bar.custom_minimum_size = Vector2(0, 16)
    bar.max_value = ProgressionRules.required_xp_for_level(level)
    bar.value = ProgressionRules.xp_into_level(xp)
    bar.show_percentage = false
    text.add_child(bar)
    return panel


func _currency_chip(icon: String, value: int, color: Color) -> PanelContainer:
    var panel := _panel(Color(0.01, 0.015, 0.04, 0.78), color, 14)
    panel.custom_minimum_size = Vector2(154, 72)
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 10)
    panel.add_child(row)
    row.add_child(_label(icon, 28, color))
    row.add_child(_label(str(value), 26, Color.WHITE))
    return panel


func _start_cluster() -> VBoxContainer:
    var box := VBoxContainer.new()
    box.name = "StartCluster"
    box.add_theme_constant_override("separation", 12)
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    var start := PremiumUI.start_button(_on_play_pressed)
    box.add_child(start)
    box.add_child(_control_hint())
    return box


func _control_hint() -> PanelContainer:
    var p := _panel(Color(0.005, 0.012, 0.03, 0.66), Color(0.0, 0.941, 1.0, 0.72), 12)
    p.custom_minimum_size = Vector2(0, 66)
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 16)
    p.add_child(row)
    row.add_child(_label("CONTINUE", 22, Color.WHITE))
    row.add_child(_label("BEST %d" % int(_progression.get("best_score", 0)), 24, Color(1.0, 0.933, 0.0, 1.0)))
    row.add_child(_label(str(_theme.get("name", "NEON CITY")).to_upper(), 22, Color(0.0, 0.941, 1.0, 1.0)))
    return p


func _reward_strip() -> GridContainer:
    var grid := GridContainer.new()
    grid.name = "RewardStrip"
    grid.columns = 3
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_child(_mini_card("LOGIN", "DAY %d" % RewardEconomy.current_login_day(_progression), Color(0.2, 1.0, 0.38, 1.0), _on_daily_login_pressed))
    grid.add_child(_mini_card("SPIN", "FREE" if RewardEconomy.can_spin(_progression) else "SOON", Color(1.0, 0.76, 0.05, 1.0), _on_lucky_spin_pressed))
    grid.add_child(_mini_card("CHESTS", str(_chest_total()), Color(0.2, 0.85, 1.0, 1.0), _on_chests_pressed))
    return grid


func _bottom_nav() -> GridContainer:
    var grid := GridContainer.new()
    grid.name = "BottomNav"
    grid.columns = 5
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for button in [
        _nav_button("SHOP", _on_shop_pressed, Color(0.0, 0.72, 1.0, 1.0)),
        _nav_button("SKINS", _on_shop_pressed, Color(0.58, 0.24, 1.0, 1.0)),
        _nav_button("MISSIONS", _on_daily_pressed, Color(0.8, 0.24, 1.0, 1.0)),
        _nav_button("COLLECT", _on_collection_pressed, Color(1.0, 0.933, 0.0, 1.0)),
        _nav_button("MORE", _toggle_more, Color(0.75, 0.85, 1.0, 1.0)),
    ]:
        grid.add_child(button)
    return grid


func _more_menu() -> PanelContainer:
    var panel := _panel(Color(0.008, 0.012, 0.032, 0.88), Color(0.75, 0.85, 1.0, 0.62), 14)
    panel.name = "MorePanel"
    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    panel.add_child(grid)
    for button in [
        _mini_card("ACHIEVEMENTS", "CLAIM", Color(1.0, 0.58, 0.05, 1.0), _on_achievements_pressed),
        _mini_card("STATISTICS", "PROGRESS", Color(0.0, 0.82, 0.9, 1.0), _on_statistics_pressed),
        _mini_card("THEMES", "%d/%d" % [ThemeCatalog.unlocked_theme_ids(_progression).size(), ThemeCatalog.all().size()], Color(0.2, 1.0, 0.38, 1.0), _on_theme_gallery_pressed),
        _mini_card("SETTINGS", "A11Y", Color(0.75, 0.85, 1.0, 1.0), _on_settings_pressed),
    ]:
        grid.add_child(button)
    return panel


func _button(title: String, sub: String, color: Color, callback: Callable) -> Button:
    var b := Button.new()
    b.text = "%s\n%s" % [title, sub]
    b.alignment = HORIZONTAL_ALIGNMENT_CENTER
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 34)
    b.pressed.connect(callback)
    PremiumUI.style_button(b, color)
    _wire_button(b)
    return b


func _mini_card(title: String, sub: String, color: Color, callback: Callable) -> Button:
    var b := _button(title, sub, color, callback)
    b.custom_minimum_size = Vector2(0, 86)
    b.add_theme_font_size_override("font_size", 22)
    return b


func _nav_button(title: String, callback: Callable, color: Color) -> Button:
    var b := _button(title, "", color, callback)
    b.custom_minimum_size = Vector2(0, 88)
    b.add_theme_font_size_override("font_size", 22)
    return b


func _panel(bg: Color, border: Color, radius: int) -> PanelContainer:
    var p := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(2)
    style.set_corner_radius_all(radius)
    style.shadow_color = Color(border.r, border.g, border.b, 0.22)
    style.shadow_size = 12
    p.add_theme_stylebox_override("panel", style)
    return p


func _label(text: String, size_px: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
    var label := Label.new()
    label.text = text
    label.horizontal_alignment = align
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", size_px)
    label.add_theme_color_override("font_color", color)
    return label


func _layout() -> void:
    var view := get_viewport_rect().size
    var portrait := view.y >= view.x
    var margin := int(clampf(minf(view.x, view.y) * 0.045, 22.0, 48.0))
    _content.add_theme_constant_override("margin_left", margin)
    _content.add_theme_constant_override("margin_right", margin)
    _content.add_theme_constant_override("margin_top", margin)
    _content.add_theme_constant_override("margin_bottom", margin)
    var stack := _content.get_node_or_null("HomeStack") as VBoxContainer
    var bottom := stack.get_node_or_null("BottomNav") as GridContainer
    var rewards := stack.get_node_or_null("RewardStrip") as GridContainer
    var start := stack.get_node_or_null("StartCluster") as Control
    var logo := stack.get_node_or_null("LogoLockup") as Control
    if bottom != null:
        bottom.columns = 5 if not portrait else 3
    if rewards != null:
        rewards.columns = 3
    if start != null:
        start.custom_minimum_size = Vector2(0, 210 if portrait else 184)
    if logo != null:
        logo.visible = portrait
    if _showcase != null:
        _showcase.position = Vector2(view.x * (0.5 if portrait else 0.58), view.y * (0.36 if portrait else 0.52))
        var scale := 2.7 if portrait else 3.45
        _showcase.scale = Vector2(scale, scale)
    if _trail != null:
        _trail.width = 22.0 if portrait else 30.0


func _wire_button(button: Button) -> void:
    button.mouse_entered.connect(func() -> void: _button_to(button, Vector2(1.025, 1.025), 0.08))
    button.mouse_exited.connect(func() -> void: _button_to(button, Vector2.ONE, 0.10))
    button.button_down.connect(func() -> void: _button_to(button, Vector2(0.96, 0.96), 0.05))
    button.button_up.connect(func() -> void: _button_to(button, Vector2(1.015, 1.015), 0.08))


func _button_to(button: Button, target_scale: Vector2, duration: float) -> void:
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", target_scale, duration)


func _toggle_more() -> void:
    _more_panel.visible = not _more_panel.visible
    _layout()


func _chest_total() -> int:
    var inv: Dictionary = _progression.get("chest_inventory", {})
    var total := 0
    for chest in RewardEconomy.CHESTS:
        total += int(inv.get(chest, 0))
    return total


func _push(path: String, label: String) -> void:
    var result: Result = SceneRouter.push(path)
    if not result.ok:
        push_error("MainMenu", "%s failed: %s" % [label, result.error])


func _on_play_pressed() -> void:
    _push(_GAME_WORLD_PATH, "play")


func _on_settings_pressed() -> void:
    _push(_SETTINGS_PATH, "settings")


func _on_shop_pressed() -> void:
    _push(_SHOP_PATH, "shop")


func _on_daily_login_pressed() -> void:
    _push(_DAILY_LOGIN_PATH, "daily login")


func _on_lucky_spin_pressed() -> void:
    _push(_LUCKY_SPIN_PATH, "lucky spin")


func _on_chests_pressed() -> void:
    _push(_CHESTS_PATH, "chests")


func _on_daily_pressed() -> void:
    _push(_DAILY_PATH, "daily")


func _on_achievements_pressed() -> void:
    _push(_ACHIEVEMENTS_PATH, "achievements")


func _on_statistics_pressed() -> void:
    _push(_STATISTICS_PATH, "statistics")


func _on_collection_pressed() -> void:
    _push(_COLLECTION_PATH, "collection")


func _on_theme_gallery_pressed() -> void:
    _push(_THEME_GALLERY_PATH, "theme gallery")
