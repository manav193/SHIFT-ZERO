## MainMenu
##
## Premium procedural home screen. All visuals are Godot UI/shapes; no assets.
extends Control

const ProgressionRules := preload("res://src/core/progression_rules.gd")
const SkinCatalog := preload("res://src/core/skin_catalog.gd")
const ThemeCatalog := preload("res://src/core/theme_catalog.gd")
const RewardEconomy := preload("res://src/core/reward_economy.gd")

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

var _progression: Dictionary = {}
var _skin: Dictionary = {}
var _theme: Dictionary = {}
var _root: Control
var _city_root: Node2D
var _showcase: SkinModel
var _showcase_trail: Line2D
var _portrait_scroll: ScrollContainer
var _landscape_nodes: Array[Control] = []
var _float_phase: float = 0.0
var _buttons: Array[Button] = []


func _ready() -> void:
    var old := get_node_or_null("Center")
    if old != null:
        old.visible = false
    _load_progression()
    _build_screen()
    _update_layout()


func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and is_node_ready():
        _update_layout()


func _process(delta: float) -> void:
    _float_phase += delta
    if _city_root != null:
        _city_root.position.x = sin(_float_phase * 0.18) * 18.0
    if _showcase != null:
        _showcase.position.y = sin(_float_phase * 1.6) * 18.0
        _showcase.rotation = sin(_float_phase * 0.9) * 0.035
        _showcase_trail.points = _showcase.trail_points(_showcase.global_position)


func _load_progression() -> void:
    var save: Object = ServiceLocator.get_service("ISaveService")
    if save == null:
        _progression = RewardEconomy.ensure_progression({})
    else:
        save.mutate(func(state: Dictionary) -> Dictionary:
            state["progression"] = RewardEconomy.ensure_progression(state.get("progression", {}))
            return state)
        var result: Result = save.load_state()
        _progression = result.value.get("progression", {}) if result.ok else {}
        _progression = RewardEconomy.ensure_progression(_progression)
    _skin = SkinCatalog.by_id(str(_progression.get("equipped_skin", SkinCatalog.CLASSIC)))
    _theme = ThemeCatalog.by_id(str(ThemeCatalog.unlocked_theme_ids(_progression).front()))


func _build_screen() -> void:
    _root = Control.new()
    _root.name = "PremiumHome"
    _root.anchor_right = 1.0
    _root.anchor_bottom = 1.0
    add_child(_root)
    _build_background()
    _build_top_bar()
    _build_left_nav()
    _build_showcase()
    _build_reward_panels()
    _build_booster_strip()
    _build_brand()
    _build_portrait_layout()


func _build_background() -> void:
    var sky := ColorRect.new()
    sky.anchor_right = 1.0
    sky.anchor_bottom = 1.0
    sky.color = _theme.get("sky_top", Color(0.03, 0.04, 0.09, 1.0))
    _root.add_child(sky)

    var horizon := ColorRect.new()
    horizon.anchor_top = 0.42
    horizon.anchor_right = 1.0
    horizon.anchor_bottom = 1.0
    horizon.color = _theme.get("sky_bottom", Color(0.06, 0.02, 0.12, 1.0))
    _root.add_child(horizon)

    _city_root = Node2D.new()
    _root.add_child(_city_root)
    var palette: Array = _theme.get("bands", [])
    for i in 22:
        var building := Polygon2D.new()
        var w := 70.0 + float((i * 37) % 90)
        var h := 180.0 + float((i * 53) % 360)
        var x := -120.0 + float(i) * 116.0
        var y := 850.0 - h
        building.polygon = PackedVector2Array([Vector2(x, 900), Vector2(x + w, 900), Vector2(x + w, y), Vector2(x, y)])
        building.color = palette[i % palette.size()] if not palette.is_empty() else Color(0.02, 0.08, 0.12, 0.8)
        _city_root.add_child(building)
        if i % 3 == 0:
            var sign := ColorRect.new()
            sign.position = Vector2(x + 18.0, y + 42.0)
            sign.size = Vector2(18.0, h * 0.45)
            sign.color = _theme.get("ground", Color(0.0, 0.941, 1.0, 1.0))
            _city_root.add_child(sign)

    var road := Polygon2D.new()
    road.polygon = PackedVector2Array([Vector2(250, 1080), Vector2(1320, 1080), Vector2(920, 720), Vector2(680, 720)])
    road.color = Color(0.015, 0.02, 0.045, 0.88)
    _root.add_child(road)
    for i in 10:
        var stripe := Polygon2D.new()
        var y := 735.0 + float(i) * 36.0
        stripe.polygon = PackedVector2Array([Vector2(765, y), Vector2(805, y), Vector2(816, y + 22), Vector2(752, y + 22)])
        stripe.color = Color(1.0, 0.933, 0.0, 0.45)
        _root.add_child(stripe)

    var particles := CPUParticles2D.new()
    particles.position = Vector2(760, 520)
    particles.amount = 42
    particles.lifetime = 3.0
    particles.emitting = true
    particles.speed_scale = 0.38
    particles.spread = 180.0
    particles.gravity = Vector2(0, -18)
    particles.initial_velocity_min = 16.0
    particles.initial_velocity_max = 52.0
    particles.scale_amount_min = 2.0
    particles.scale_amount_max = 5.0
    particles.color = _theme.get("particle", Color(0.0, 0.941, 1.0, 0.8))
    _root.add_child(particles)


func _build_top_bar() -> void:
    var top := HBoxContainer.new()
    top.name = "TopBar"
    top.anchor_right = 1.0
    top.offset_left = 28.0
    top.offset_top = 24.0
    top.offset_right = -28.0
    top.offset_bottom = 128.0
    top.add_theme_constant_override("separation", 18)
    _root.add_child(top)
    _landscape_nodes.append(top)

    var profile := _panel(Color(0.02, 0.025, 0.05, 0.62), _skin.get("accent", Color.WHITE))
    profile.custom_minimum_size = Vector2(420, 96)
    top.add_child(profile)
    var profile_row := HBoxContainer.new()
    profile_row.add_theme_constant_override("separation", 16)
    profile.add_child(profile_row)
    var portrait_box := Control.new()
    portrait_box.custom_minimum_size = Vector2(96, 96)
    profile_row.add_child(portrait_box)
    var portrait := SkinModel.new()
    portrait.scale = Vector2(0.72, 0.72)
    portrait.position = Vector2(48, 48)
    portrait.apply_skin(_skin)
    portrait_box.add_child(portrait)
    var profile_text := VBoxContainer.new()
    profile_row.add_child(profile_text)
    profile_text.add_child(_label("PLAYER", 30, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
    var xp := int(_progression.get("player_xp", 0))
    var level := int(_progression.get("player_level", ProgressionRules.level_for_total_xp(xp)))
    profile_text.add_child(_label("LEVEL %d   %d/%d XP" % [level, ProgressionRules.xp_into_level(xp), ProgressionRules.required_xp_for_level(level)], 22, Color(1.0, 0.933, 0.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
    var bar := ProgressBar.new()
    bar.custom_minimum_size = Vector2(260, 18)
    bar.max_value = ProgressionRules.required_xp_for_level(level)
    bar.value = ProgressionRules.xp_into_level(xp)
    bar.show_percentage = false
    profile_text.add_child(bar)

    top.add_child(_resource_pill("$", int(_progression.get("total_coins", 0)), Color(1.0, 0.78, 0.12, 1.0)))
    top.add_child(_resource_pill("C", _chest_total(), Color(0.2, 0.85, 1.0, 1.0)))
    top.add_child(_resource_pill("E", _equipped_booster_count(), Color(1.0, 0.169, 0.839, 1.0)))

    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(spacer)
    top.add_child(_icon_button("G", _on_daily_login_pressed))
    top.add_child(_icon_button("M", _on_daily_pressed))
    top.add_child(_icon_button("*", _on_settings_pressed))


func _build_left_nav() -> void:
    var nav := VBoxContainer.new()
    nav.name = "Nav"
    nav.offset_left = 28.0
    nav.offset_top = 150.0
    nav.offset_right = 348.0
    nav.offset_bottom = 820.0
    nav.add_theme_constant_override("separation", 14)
    _root.add_child(nav)
    _landscape_nodes.append(nav)
    nav.add_child(_menu_button("[>]  PLAY", "NEW RUN", Color(1.0, 0.76, 0.05, 1.0), _on_play_pressed, true))
    nav.add_child(_menu_button("[S]  SKINS", "%d / %d OWNED" % [(_progression.get("purchased_skins", []) as Array).size(), SkinCatalog.all().size()], Color(0.58, 0.24, 1.0, 1.0), _on_shop_pressed))
    nav.add_child(_menu_button("[$]  SHOP", "FRAGMENTS & SKINS", Color(0.0, 0.72, 1.0, 1.0), _on_shop_pressed, _has_shop_notice()))
    nav.add_child(_menu_button("[M]  MISSIONS", "DAILY TASKS", Color(0.8, 0.24, 1.0, 1.0), _on_daily_pressed, _can_claim_login()))
    nav.add_child(_menu_button("[A]  ACHIEVEMENTS", "CLAIM REWARDS", Color(1.0, 0.58, 0.05, 1.0), _on_achievements_pressed))
    nav.add_child(_menu_button("[B]  STATISTICS", "YOUR PROGRESS", Color(0.0, 0.82, 0.9, 1.0), _on_statistics_pressed))
    nav.add_child(_menu_button("[T]  THEME GALLERY", "%d / %d UNLOCKED" % [ThemeCatalog.unlocked_theme_ids(_progression).size(), ThemeCatalog.all().size()], Color(0.2, 1.0, 0.38, 1.0), _on_theme_gallery_pressed))


func _build_showcase() -> void:
    _showcase_trail = Line2D.new()
    _showcase_trail.width = 22.0
    _showcase_trail.default_color = _skin.get("trail", Color(0.0, 0.941, 1.0, 0.65))
    _root.add_child(_showcase_trail)

    _showcase = SkinModel.new()
    _showcase.name = "CharacterShowcase"
    _showcase.position = Vector2(760, 610)
    _showcase.scale = Vector2(3.0, 3.0)
    _showcase.apply_skin(_skin)
    _root.add_child(_showcase)


func _build_reward_panels() -> void:
    var right := VBoxContainer.new()
    right.name = "RewardPanels"
    right.anchor_left = 1.0
    right.anchor_right = 1.0
    right.offset_left = -520.0
    right.offset_top = 150.0
    right.offset_right = -28.0
    right.offset_bottom = 850.0
    right.add_theme_constant_override("separation", 18)
    _root.add_child(right)
    _landscape_nodes.append(right)
    right.add_child(_daily_panel())
    right.add_child(_spin_panel())
    right.add_child(_chest_panel())

    var start := _menu_button("START RUN", str(_theme.get("name", "NEON CITY")).to_upper(), Color(1.0, 0.74, 0.05, 1.0), _on_play_pressed, true)
    start.custom_minimum_size = Vector2(0, 110)
    right.add_child(start)


func _build_booster_strip() -> void:
    var strip := HBoxContainer.new()
    strip.name = "Boosters"
    strip.anchor_left = 0.5
    strip.anchor_right = 0.5
    strip.anchor_top = 1.0
    strip.anchor_bottom = 1.0
    strip.offset_left = -260.0
    strip.offset_top = -146.0
    strip.offset_right = 260.0
    strip.offset_bottom = -34.0
    strip.add_theme_constant_override("separation", 12)
    _root.add_child(strip)
    _landscape_nodes.append(strip)
    for booster in RewardEconomy.BOOSTERS:
        var inv: Dictionary = _progression.get("booster_inventory", {})
        var count := int(inv.get(booster, 0))
        var pill := _panel(Color(0.02, 0.025, 0.05, 0.7), Color(0.0, 0.941, 1.0, 0.8))
        pill.custom_minimum_size = Vector2(92, 100)
        var v := VBoxContainer.new()
        v.alignment = BoxContainer.ALIGNMENT_CENTER
        pill.add_child(v)
        v.add_child(_label(_booster_icon(booster), 30, Color(1.0, 0.933, 0.0, 1.0)))
        v.add_child(_label(str(count), 24, Color.WHITE))
        strip.add_child(pill)


func _build_brand() -> void:
    var brand := Label.new()
    brand.text = "SHIFT\nZERO"
    brand.offset_left = 34.0
    brand.anchor_top = 1.0
    brand.anchor_bottom = 1.0
    brand.offset_top = -112.0
    brand.offset_right = 260.0
    brand.offset_bottom = -20.0
    brand.add_theme_font_size_override("font_size", 42)
    brand.add_theme_color_override("font_color", Color.WHITE)
    _root.add_child(brand)
    _landscape_nodes.append(brand)


func _build_portrait_layout() -> void:
    _portrait_scroll = ScrollContainer.new()
    _portrait_scroll.name = "PortraitScroll"
    _portrait_scroll.anchor_right = 1.0
    _portrait_scroll.anchor_bottom = 1.0
    _portrait_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    _portrait_scroll.visible = false
    _root.add_child(_portrait_scroll)

    var margin := MarginContainer.new()
    margin.name = "SafeMargins"
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_top", 28)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_bottom", 34)
    margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _portrait_scroll.add_child(margin)

    var v := VBoxContainer.new()
    v.name = "PortraitStack"
    v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    v.add_theme_constant_override("separation", 18)
    margin.add_child(v)

    v.add_child(_portrait_profile_panel())
    v.add_child(_portrait_currency_grid())

    var play := _menu_button("[>]  PLAY", "NEW RUN", Color(1.0, 0.76, 0.05, 1.0), _on_play_pressed, true)
    _make_portrait_card(play, 112, 34)
    v.add_child(play)

    var nav_grid := GridContainer.new()
    nav_grid.columns = 1
    nav_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    nav_grid.add_theme_constant_override("h_separation", 12)
    nav_grid.add_theme_constant_override("v_separation", 12)
    v.add_child(nav_grid)
    for button in [
        _menu_button("[S]  SKINS", "%d / %d OWNED" % [(_progression.get("purchased_skins", []) as Array).size(), SkinCatalog.all().size()], Color(0.58, 0.24, 1.0, 1.0), _on_shop_pressed),
        _menu_button("[$]  SHOP", "FRAGMENTS & SKINS", Color(0.0, 0.72, 1.0, 1.0), _on_shop_pressed, _has_shop_notice()),
        _menu_button("[M]  MISSIONS", "DAILY TASKS", Color(0.8, 0.24, 1.0, 1.0), _on_daily_pressed, _can_claim_login()),
        _menu_button("[A]  ACHIEVEMENTS", "CLAIM REWARDS", Color(1.0, 0.58, 0.05, 1.0), _on_achievements_pressed),
        _menu_button("[B]  STATISTICS", "YOUR PROGRESS", Color(0.0, 0.82, 0.9, 1.0), _on_statistics_pressed),
        _menu_button("[T]  THEME GALLERY", "%d / %d UNLOCKED" % [ThemeCatalog.unlocked_theme_ids(_progression).size(), ThemeCatalog.all().size()], Color(0.2, 1.0, 0.38, 1.0), _on_theme_gallery_pressed),
        _menu_button("[*]  SETTINGS", "AUDIO & ACCESSIBILITY", Color(0.75, 0.85, 1.0, 1.0), _on_settings_pressed),
    ]:
        _make_portrait_card(button, 92, 27)
        nav_grid.add_child(button)

    v.add_child(_portrait_section(_daily_panel()))
    v.add_child(_portrait_section(_spin_panel()))
    v.add_child(_portrait_section(_chest_panel()))

    var start := _menu_button("START RUN", str(_theme.get("name", "NEON CITY")).to_upper(), Color(1.0, 0.74, 0.05, 1.0), _on_play_pressed, true)
    _make_portrait_card(start, 116, 34)
    v.add_child(start)

    var boosters := _portrait_booster_grid()
    v.add_child(boosters)

    var quit := _menu_button("QUIT", "EXIT GAME", Color(0.55, 0.62, 0.72, 1.0), _on_quit_pressed)
    _make_portrait_card(quit, 88, 26)
    v.add_child(quit)


func _portrait_profile_panel() -> PanelContainer:
    var profile := _panel(Color(0.02, 0.025, 0.05, 0.78), _skin.get("accent", Color.WHITE))
    profile.custom_minimum_size = Vector2(0, 138)
    profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var row := HBoxContainer.new()
    row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 16)
    profile.add_child(row)
    var portrait_box := Control.new()
    portrait_box.custom_minimum_size = Vector2(104, 112)
    row.add_child(portrait_box)
    var portrait := SkinModel.new()
    portrait.scale = Vector2(0.72, 0.72)
    portrait.position = Vector2(52, 58)
    portrait.apply_skin(_skin)
    portrait_box.add_child(portrait)
    var profile_text := VBoxContainer.new()
    profile_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(profile_text)
    profile_text.add_child(_label("PLAYER", 28, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
    var xp := int(_progression.get("player_xp", 0))
    var level := int(_progression.get("player_level", ProgressionRules.level_for_total_xp(xp)))
    profile_text.add_child(_label("LEVEL %d" % level, 24, Color(1.0, 0.933, 0.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
    var bar := ProgressBar.new()
    bar.custom_minimum_size = Vector2(0, 24)
    bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bar.max_value = ProgressionRules.required_xp_for_level(level)
    bar.value = ProgressionRules.xp_into_level(xp)
    bar.show_percentage = false
    profile_text.add_child(bar)
    profile_text.add_child(_label("%d / %d XP" % [ProgressionRules.xp_into_level(xp), ProgressionRules.required_xp_for_level(level)], 20, Color(0.78, 0.9, 1.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
    return profile


func _portrait_currency_grid() -> GridContainer:
    var grid := GridContainer.new()
    grid.columns = 2
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    for pill in [
        _resource_pill("$", int(_progression.get("total_coins", 0)), Color(1.0, 0.78, 0.12, 1.0)),
        _resource_pill("C", _chest_total(), Color(0.2, 0.85, 1.0, 1.0)),
        _resource_pill("E", _equipped_booster_count(), Color(1.0, 0.169, 0.839, 1.0)),
        _resource_pill("D", 1 if _can_claim_login() else 0, Color(0.2, 1.0, 0.38, 1.0)),
    ]:
        pill.custom_minimum_size = Vector2(0, 78)
        pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        grid.add_child(pill)
    return grid


func _portrait_booster_grid() -> GridContainer:
    var grid := GridContainer.new()
    grid.columns = 5
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    for booster in RewardEconomy.BOOSTERS:
        var inv: Dictionary = _progression.get("booster_inventory", {})
        var count := int(inv.get(booster, 0))
        var pill := _panel(Color(0.02, 0.025, 0.05, 0.76), Color(0.0, 0.941, 1.0, 0.8))
        pill.custom_minimum_size = Vector2(0, 82)
        pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var v := VBoxContainer.new()
        v.alignment = BoxContainer.ALIGNMENT_CENTER
        pill.add_child(v)
        v.add_child(_label(_booster_icon(booster), 21, Color(1.0, 0.933, 0.0, 1.0)))
        v.add_child(_label(str(count), 20, Color.WHITE))
        grid.add_child(pill)
    return grid


func _portrait_section(panel: Control) -> Control:
    panel.custom_minimum_size = Vector2(0, 164)
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return panel


func _make_portrait_card(button: Button, height: float, font_size: int) -> void:
    button.custom_minimum_size = Vector2(0, height)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", font_size)


func _daily_panel() -> Control:
    var day := RewardEconomy.current_login_day(_progression)
    var p := _reward_panel("DAILY LOGIN", "DAY %d  %s" % [day, "READY" if _can_claim_login() else "CLAIMED"], _on_daily_login_pressed)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)
    p.add_child(row)
    for entry in RewardEconomy.login_calendar():
        var cell := _panel(Color(0.03, 0.04, 0.08, 0.72), Color(1.0, 0.933, 0.0, 0.4))
        cell.custom_minimum_size = Vector2(54, 58)
        var label := _label(str(entry.day), 20, Color.WHITE)
        cell.add_child(label)
        if int(entry.day) == day:
            cell.modulate = Color(1.0, 1.0, 1.0, 1.0)
        else:
            cell.modulate = Color(0.65, 0.7, 0.8, 0.85)
        row.add_child(cell)
    return p


func _spin_panel() -> Control:
    var text := "FREE SPIN READY" if RewardEconomy.can_spin(_progression) else "NEXT FREE TOMORROW"
    var p := _reward_panel("LUCKY SPIN", text, _on_lucky_spin_pressed)
    var wheel := Label.new()
    wheel.text = "XP | COINS | CHESTS | BOOSTERS"
    wheel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    wheel.add_theme_font_size_override("font_size", 23)
    wheel.add_theme_color_override("font_color", Color(1.0, 0.933, 0.0, 1.0))
    p.add_child(wheel)
    return p


func _chest_panel() -> Control:
    var p := _reward_panel("CHESTS", "%d READY" % _chest_total(), _on_chests_pressed)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    p.add_child(row)
    var inv: Dictionary = _progression.get("chest_inventory", {})
    for chest in ["common", "rare", "epic"]:
        var cell := _panel(Color(0.03, 0.04, 0.08, 0.72), Color(1.0, 0.58, 0.05, 0.55))
        cell.custom_minimum_size = Vector2(130, 70)
        var v := VBoxContainer.new()
        v.alignment = BoxContainer.ALIGNMENT_CENTER
        cell.add_child(v)
        v.add_child(_label(chest.to_upper(), 18, Color.WHITE))
        v.add_child(_label("x%d" % int(inv.get(chest, 0)), 24, Color(1.0, 0.933, 0.0, 1.0)))
        row.add_child(cell)
    return p


func _reward_panel(title: String, sub: String, callback: Callable) -> PanelContainer:
    var p := _panel(Color(0.015, 0.02, 0.045, 0.78), Color(0.8, 0.86, 1.0, 0.45))
    p.custom_minimum_size = Vector2(0, 150)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 6)
    p.add_child(v)
    var b := Button.new()
    b.flat = true
    b.text = title
    b.alignment = HORIZONTAL_ALIGNMENT_LEFT
    b.add_theme_font_size_override("font_size", 28)
    b.pressed.connect(callback)
    v.add_child(b)
    _wire_button(b)
    v.add_child(_label(sub, 20, Color(1.0, 0.62, 1.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
    return p


func _menu_button(title: String, sub: String, color: Color, callback: Callable, notice: bool = false) -> Button:
    var b := Button.new()
    b.custom_minimum_size = Vector2(0, 78)
    b.text = "%s\n%s%s" % [title, sub, "  !" if notice else ""]
    b.alignment = HORIZONTAL_ALIGNMENT_LEFT
    b.add_theme_font_size_override("font_size", 28)
    var style := StyleBoxFlat.new()
    style.bg_color = Color(color.r * 0.16, color.g * 0.16, color.b * 0.16, 0.82)
    style.border_color = color
    style.set_border_width_all(2)
    style.set_corner_radius_all(8)
    b.add_theme_stylebox_override("normal", style)
    b.add_theme_stylebox_override("hover", _button_style(color, 0.95))
    b.add_theme_stylebox_override("pressed", _button_style(color, 0.65))
    b.pressed.connect(callback)
    _wire_button(b)
    _buttons.append(b)
    return b


func _button_style(color: Color, alpha: float) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(color.r * 0.25, color.g * 0.25, color.b * 0.25, alpha)
    style.border_color = color
    style.set_border_width_all(3)
    style.set_corner_radius_all(8)
    return style


func _resource_pill(icon: String, value: int, color: Color) -> Control:
    var p := _panel(Color(0.02, 0.025, 0.05, 0.72), color)
    p.custom_minimum_size = Vector2(180, 64)
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 12)
    p.add_child(row)
    row.add_child(_label(icon, 30, color))
    row.add_child(_label(str(value), 28, Color.WHITE))
    row.add_child(_label("+", 30, Color(1.0, 0.933, 0.0, 1.0)))
    return p


func _icon_button(text: String, callback: Callable) -> Button:
    var b := Button.new()
    b.custom_minimum_size = Vector2(64, 64)
    b.text = text
    b.add_theme_font_size_override("font_size", 30)
    b.pressed.connect(callback)
    _wire_button(b)
    return b


func _panel(bg: Color, border: Color) -> PanelContainer:
    var p := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(2)
    style.set_corner_radius_all(8)
    p.add_theme_stylebox_override("panel", style)
    return p


func _label(text: String, size_px: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
    var l := Label.new()
    l.text = text
    l.horizontal_alignment = align
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", size_px)
    l.add_theme_color_override("font_color", color)
    return l


func _wire_button(button: Button) -> void:
    button.pivot_offset = button.size * 0.5
    button.mouse_entered.connect(func() -> void: _button_to(button, Vector2(1.035, 1.035), 0.08))
    button.mouse_exited.connect(func() -> void: _button_to(button, Vector2.ONE, 0.10))
    button.button_down.connect(func() -> void: _button_to(button, Vector2(0.96, 0.96), 0.05))
    button.button_up.connect(func() -> void: _button_to(button, Vector2(1.02, 1.02), 0.08))


func _button_to(button: Button, target_scale: Vector2, duration: float) -> void:
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", target_scale, duration)


func _update_layout() -> void:
    if _root == null:
        return
    var view_size := get_viewport_rect().size
    var portrait := view_size.y > view_size.x
    for node in _landscape_nodes:
        if is_instance_valid(node):
            node.visible = not portrait
    if _portrait_scroll != null:
        _portrait_scroll.visible = portrait
    var nav := _root.get_node_or_null("Nav") as Control
    var right := _root.get_node_or_null("RewardPanels") as Control
    var boosters := _root.get_node_or_null("Boosters") as Control
    var top := _root.get_node_or_null("TopBar") as HBoxContainer
    if portrait:
        if _portrait_scroll != null:
            _portrait_scroll.offset_left = 0.0
            _portrait_scroll.offset_top = 0.0
            _portrait_scroll.offset_right = 0.0
            _portrait_scroll.offset_bottom = 0.0
            var margin := _portrait_scroll.get_node_or_null("SafeMargins") as Control
            if margin != null:
                margin.custom_minimum_size = Vector2(view_size.x, 0.0)
        if nav != null:
            nav.offset_left = 24
            nav.offset_top = 360
            nav.offset_right = minf(view_size.x - 24, 420)
            nav.offset_bottom = view_size.y - 210
        if right != null:
            right.offset_left = -minf(view_size.x - 48, 460)
            right.offset_top = 360
            right.offset_right = -24
            right.offset_bottom = view_size.y - 210
        if _showcase != null:
            _showcase.position = Vector2(view_size.x * 0.5, 255)
            _showcase.scale = Vector2(1.85, 1.85)
            _showcase.modulate = Color(1.0, 1.0, 1.0, 0.32)
        if _showcase_trail != null:
            _showcase_trail.modulate = Color(1.0, 1.0, 1.0, 0.24)
        if boosters != null:
            boosters.offset_top = -138
    else:
        var compact := view_size.x < 1500.0
        if top != null:
            top.offset_left = 22.0
            top.offset_top = 18.0
            top.offset_right = -22.0
            top.offset_bottom = 112.0
            top.add_theme_constant_override("separation", 10 if compact else 18)
            for child in top.get_children():
                if child is Control:
                    (child as Control).scale = Vector2.ONE
            if top.get_child_count() >= 4:
                (top.get_child(0) as Control).custom_minimum_size = Vector2(315, 82) if compact else Vector2(420, 96)
                (top.get_child(1) as Control).custom_minimum_size = Vector2(130, 58) if compact else Vector2(180, 64)
                (top.get_child(2) as Control).custom_minimum_size = Vector2(130, 58) if compact else Vector2(180, 64)
                (top.get_child(3) as Control).custom_minimum_size = Vector2(130, 58) if compact else Vector2(180, 64)
        if nav != null:
            nav.offset_left = 28
            nav.offset_top = 126 if compact else 150
            nav.offset_right = 322 if compact else 348
            nav.offset_bottom = view_size.y - 22 if compact else 820
            nav.add_theme_constant_override("separation", 8 if compact else 14)
            for child in nav.get_children():
                if child is Button:
                    (child as Button).custom_minimum_size = Vector2(0, 44) if compact else Vector2(0, 78)
                    (child as Button).add_theme_font_size_override("font_size", 18 if compact else 28)
        if right != null:
            right.offset_left = -430 if compact else -520
            right.offset_top = 126 if compact else 150
            right.offset_right = -28
            right.offset_bottom = view_size.y - 24 if compact else 850
            right.add_theme_constant_override("separation", 10 if compact else 18)
            for child in right.get_children():
                if child is Control:
                    if compact:
                        (child as Control).custom_minimum_size = Vector2(0, 78) if child is Button else Vector2(0, 92)
                    else:
                        (child as Control).custom_minimum_size = Vector2(0, 110) if child is Button else Vector2(0, 150)
                if child is Button:
                    (child as Button).add_theme_font_size_override("font_size", 22 if compact else 28)
        if boosters != null:
            boosters.visible = not compact
        if _showcase != null:
            _showcase.position = Vector2(view_size.x * 0.5, view_size.y * 0.56)
            _showcase.scale = Vector2(2.35, 2.35) if compact else Vector2(3.0, 3.0)
            _showcase.modulate = Color.WHITE
        if _showcase_trail != null:
            _showcase_trail.modulate = Color.WHITE


func _can_claim_login() -> bool:
    return RewardEconomy.can_claim_login(_progression)


func _has_shop_notice() -> bool:
    var fragments: Dictionary = _progression.get("skin_fragments", {})
    return int(fragments.get("dragon", 0)) > 0 or int(fragments.get("phoenix", 0)) > 0


func _chest_total() -> int:
    var inv: Dictionary = _progression.get("chest_inventory", {})
    var total := 0
    for chest in RewardEconomy.CHESTS:
        total += int(inv.get(chest, 0))
    return total


func _equipped_booster_count() -> int:
    return (_progression.get("equipped_boosters", []) as Array).size()


func _booster_icon(booster: String) -> String:
    match booster:
        "shield":
            return "SH"
        "magnet":
            return "MG"
        "double_score":
            return "2X"
        "coin_booster":
            return "$2"
        "xp_booster":
            return "XP"
    return "B"


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


func _on_theme_gallery_pressed() -> void:
    _push(_THEME_GALLERY_PATH, "theme gallery")


func _on_quit_pressed() -> void:
    get_tree().quit()
