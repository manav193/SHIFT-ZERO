## PremiumUI
##
## Shared visual polish helpers for existing Control scenes.
extends RefCounted

const CYAN := Color(0.0, 0.941, 1.0, 1.0)
const PINK := Color(1.0, 0.169, 0.839, 1.0)
const GOLD := Color(1.0, 0.76, 0.05, 1.0)
const VIOLET := Color(0.56, 0.24, 1.0, 1.0)
const GREEN := Color(0.27, 1.0, 0.42, 1.0)
const PANEL_BG := Color(0.025, 0.035, 0.08, 0.82)


static func apply_screen(root: Control, add_backdrop: bool = true) -> void:
    if add_backdrop:
        _ensure_backdrop(root)
    style_tree(root)


static func clear(root: Node) -> void:
    for child in root.get_children():
        child.queue_free()


static func screen(root: Control, title: String, back_callback: Callable) -> Dictionary:
    clear(root)
    _ensure_backdrop(root)
    var layer := Control.new()
    layer.name = "ReimaginedUI"
    layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.add_child(layer)
    _add_atmosphere(layer)

    var margin := MarginContainer.new()
    margin.name = "SafeFrame"
    margin.set_anchors_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 34)
    margin.add_theme_constant_override("margin_top", 32)
    margin.add_theme_constant_override("margin_right", 34)
    margin.add_theme_constant_override("margin_bottom", 34)
    layer.add_child(margin)

    var stack := VBoxContainer.new()
    stack.name = "Stack"
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_theme_constant_override("separation", 22)
    margin.add_child(stack)

    var header := HBoxContainer.new()
    header.custom_minimum_size = Vector2(0, 86)
    header.add_theme_constant_override("separation", 16)
    stack.add_child(header)
    var back := button("BACK", "", CYAN, Callable())
    back.custom_minimum_size = Vector2(138, 74)
    header.add_child(back)
    var title_label := label(title, 48, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
    title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title_label)

    var scroll := ScrollContainer.new()
    scroll.name = "Scroll"
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    stack.add_child(scroll)
    var list := VBoxContainer.new()
    list.name = "List"
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 18)
    scroll.add_child(list)
    return {"layer": layer, "stack": stack, "header": header, "scroll": scroll, "list": list, "back": back}


static func card(accent: Color = CYAN, height: float = 120.0) -> PanelContainer:
    var p := PanelContainer.new()
    p.custom_minimum_size = Vector2(0, height)
    p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    style_panel(p, accent)
    return p


static func label(text: String, size_px: int, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
    var l := Label.new()
    l.text = text
    l.horizontal_alignment = align
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", size_px)
    l.add_theme_color_override("font_color", color)
    style_label(l)
    return l


static func button(title: String, sub: String, accent: Color, callback: Callable) -> Button:
    var b := Button.new()
    b.text = title if sub == "" else "%s\n%s" % [title, sub]
    b.alignment = HORIZONTAL_ALIGNMENT_CENTER
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.custom_minimum_size = Vector2(0, 92)
    style_button(b, accent)
    if callback.is_valid():
        b.pressed.connect(callback)
    return b


static func progress(value: float, max_value: float) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.custom_minimum_size = Vector2(0, 24)
    bar.max_value = maxf(1.0, max_value)
    bar.value = clampf(value, 0.0, bar.max_value)
    bar.show_percentage = false
    style_progress(bar)
    return bar


static func card_text(title: String, sub: String, accent: Color, height: float = 132.0) -> PanelContainer:
    var p := card(accent, height)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 8)
    p.add_child(v)
    v.add_child(label(title, 30, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
    if sub != "":
        v.add_child(label(sub, 22, Color(0.75, 0.88, 1.0, 1.0), HORIZONTAL_ALIGNMENT_LEFT))
    return p


static func shape_names() -> Array[String]:
    return [
        "Cube",
        "Sphere",
        "Triangle",
        "Hexagon",
        "Diamond",
        "Arrow",
        "Rocket",
        "Drone",
        "Orb",
        "Crystal",
        "Star",
        "Shuriken",
        "Pod",
        "Core",
        "Phoenix Core",
        "Void Core",
    ]


static func skin_families() -> Dictionary:
    return {
        "Cube": ["Cyber Cube", "Neon Cube", "Crystal Cube", "Gold Cube", "Lava Cube", "Ice Cube", "Galaxy Cube"],
        "Sphere": ["Neon Sphere", "Void Sphere", "Plasma Sphere", "Solar Sphere", "Quantum Sphere"],
        "Rocket": ["Interceptor", "Nova", "Stealth", "Gold Rocket", "Dragon Rocket"],
        "Star": ["Golden Star", "Dark Star", "Cosmic Star", "Nova Star", "Plasma Star"],
        "Core": ["Cyber Core", "Phoenix Core", "Void Core", "Prism Core", "Mythic Core"],
    }


static func rarity_color(rarity: String) -> Color:
    match rarity.to_lower():
        "common":
            return Color(0.55, 0.75, 0.95, 1.0)
        "rare":
            return CYAN
        "epic":
            return VIOLET
        "legendary":
            return GOLD
        "mythic":
            return PINK
    return CYAN


static func currency_chip(icon: String, value: String, accent: Color) -> PanelContainer:
    var p := card(accent, 62)
    p.custom_minimum_size = Vector2(150, 62)
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 10)
    p.add_child(row)
    row.add_child(label(icon, 24, accent))
    row.add_child(label(value, 24, Color.WHITE))
    return p


static func start_button(callback: Callable) -> Button:
    var b := button("START RUN", "NEW RUN", GOLD, callback)
    b.custom_minimum_size = Vector2(0, 132)
    b.add_theme_font_size_override("font_size", 42)
    return b


static func reward_badge(title: String, sub: String, accent: Color, callback: Callable = Callable()) -> Button:
    var b := button(title, sub, accent, callback)
    b.custom_minimum_size = Vector2(0, 82)
    b.add_theme_font_size_override("font_size", 20)
    return b


static func shape_preview(shape: String, primary: Color = CYAN, secondary: Color = PINK, size_px: float = 176.0) -> Control:
    var box := Control.new()
    box.custom_minimum_size = Vector2(size_px, size_px)
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var glow := Panel.new()
    glow.set_anchors_preset(Control.PRESET_FULL_RECT)
    glow.add_theme_stylebox_override("panel", _box(Color(primary.r, primary.g, primary.b, 0.12), Color(primary.r, primary.g, primary.b, 0.42), 1, int(size_px * 0.22)))
    glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(glow)

    var root := Node2D.new()
    root.position = Vector2(size_px * 0.5, size_px * 0.5)
    box.add_child(root)
    var s := size_px * 0.34
    var key := shape.to_lower().replace(" ", "_")
    _add_trail(root, primary, size_px)
    match key:
        "cube", "cyber_cube", "neon_cube":
            _poly(root, PackedVector2Array([Vector2(-s, -s), Vector2(s, -s * 0.82), Vector2(s, s), Vector2(-s, s * 0.78)]), primary, secondary)
            _poly(root, PackedVector2Array([Vector2(-s * 0.35, -s * 0.35), Vector2(s * 0.35, -s * 0.3), Vector2(s * 0.35, s * 0.35), Vector2(-s * 0.35, s * 0.3)]), Color(0.02, 0.06, 0.12, 0.9), secondary)
        "sphere", "orb", "neon_sphere":
            _poly(root, _regular_polygon(22, s, 0.0), primary, secondary)
            _poly(root, _regular_polygon(22, s * 0.68, 0.0), Color(0.02, 0.08, 0.13, 0.75), Color(primary.r, primary.g, primary.b, 0.45))
        "triangle":
            _poly(root, PackedVector2Array([Vector2(0, -s * 1.2), Vector2(s * 1.08, s * 0.82), Vector2(-s * 1.08, s * 0.82)]), primary, secondary)
        "hexagon":
            _poly(root, _regular_polygon(6, s * 1.08, PI / 6.0), primary, secondary)
        "diamond", "crystal":
            _poly(root, PackedVector2Array([Vector2(0, -s * 1.28), Vector2(s * 0.9, -s * 0.12), Vector2(0, s * 1.25), Vector2(-s * 0.9, -s * 0.12)]), primary, secondary)
            _poly(root, PackedVector2Array([Vector2(0, -s), Vector2(s * 0.38, -s * 0.08), Vector2(0, s * 0.82), Vector2(-s * 0.38, -s * 0.08)]), Color(0.55, 0.95, 1.0, 0.38), Color(1, 1, 1, 0.45))
        "arrow":
            _poly(root, PackedVector2Array([Vector2(-s * 1.05, -s * 0.5), Vector2(s * 0.18, -s * 0.5), Vector2(s * 0.18, -s), Vector2(s * 1.22, 0), Vector2(s * 0.18, s), Vector2(s * 0.18, s * 0.5), Vector2(-s * 1.05, s * 0.5)]), primary, secondary)
        "rocket":
            _poly(root, PackedVector2Array([Vector2(0, -s * 1.42), Vector2(s * 0.72, -s * 0.18), Vector2(s * 0.42, s * 1.02), Vector2(0, s * 0.68), Vector2(-s * 0.42, s * 1.02), Vector2(-s * 0.72, -s * 0.18)]), primary, secondary)
            _poly(root, _regular_polygon(14, s * 0.24, 0.0), Color(0.02, 0.06, 0.12, 0.9), Color(1, 0.9, 0.7, 1))
        "drone":
            _poly(root, _regular_polygon(8, s * 0.62, PI / 8.0), primary, secondary)
            for p in [Vector2(-s, -s), Vector2(s, -s), Vector2(-s, s), Vector2(s, s)]:
                _line(root, PackedVector2Array([Vector2.ZERO, p * 0.7]), secondary, 4.0)
                _poly(root, _translated(_regular_polygon(12, s * 0.28, 0.0), p), primary, secondary)
        "star":
            _poly(root, _star_points(5, s * 1.25, s * 0.52), primary, secondary)
        "shuriken":
            _poly(root, _star_points(4, s * 1.25, s * 0.34), primary, secondary)
        "pod":
            _poly(root, PackedVector2Array([Vector2(-s * 0.55, -s * 1.1), Vector2(s * 0.55, -s * 1.1), Vector2(s, -s * 0.1), Vector2(s * 0.45, s * 1.1), Vector2(-s * 0.45, s * 1.1), Vector2(-s, -s * 0.1)]), primary, secondary)
        "phoenix_core":
            _poly(root, _star_points(6, s * 1.12, s * 0.42), Color(1.0, 0.42, 0.02, 1.0), GOLD)
            _poly(root, _regular_polygon(16, s * 0.48, 0.0), Color(1.0, 0.86, 0.1, 1.0), Color.WHITE)
        "void_core":
            _poly(root, _regular_polygon(18, s, 0.0), Color(0.05, 0.015, 0.1, 1.0), VIOLET)
            _poly(root, _regular_polygon(7, s * 0.52, 0.0), Color(0.0, 0.0, 0.0, 0.9), PINK)
        _:
            _poly(root, _regular_polygon(10, s, 0.0), primary, secondary)
            _poly(root, _regular_polygon(10, s * 0.5, PI / 10.0), Color(0.02, 0.06, 0.12, 0.9), secondary)
    return box


static func shape_tile(shape: String, status: String, accent: Color = CYAN) -> PanelContainer:
    var p := card(accent, 220)
    var v := VBoxContainer.new()
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_theme_constant_override("separation", 8)
    p.add_child(v)
    v.add_child(shape_preview(shape, accent, PINK, 132))
    v.add_child(label(shape.to_upper(), 22, Color.WHITE))
    v.add_child(label(status.to_upper(), 16, Color(0.75, 0.88, 1.0, 1.0)))
    return p


static func rarity_card(title: String, rarity: String, price: String, shape: String, accent: Color, callback: Callable = Callable()) -> Button:
    var b := button(title, "%s  %s" % [rarity.to_upper(), price], accent, callback)
    b.custom_minimum_size = Vector2(0, 190)
    b.add_theme_font_size_override("font_size", 22)
    return b


static func effect_tile(title: String, accent: Color) -> PanelContainer:
    var p := card(accent, 118)
    var v := VBoxContainer.new()
    v.add_theme_constant_override("separation", 6)
    p.add_child(v)
    var holder := Control.new()
    holder.custom_minimum_size = Vector2(0, 42)
    var line := Line2D.new()
    line.points = PackedVector2Array([Vector2(10, 20), Vector2(84, 10), Vector2(156, 22), Vector2(224, 9)])
    line.width = 8.0
    line.default_color = accent
    line.begin_cap_mode = Line2D.LINE_CAP_ROUND
    line.end_cap_mode = Line2D.LINE_CAP_ROUND
    holder.add_child(line)
    v.add_child(holder)
    v.add_child(label(title.to_upper(), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
    return p


static func style_tree(node: Node) -> void:
    if node is Button:
        style_button(node as Button)
    elif node is PanelContainer:
        style_panel(node as PanelContainer)
    elif node is Label:
        style_label(node as Label)
    elif node is ProgressBar:
        style_progress(node as ProgressBar)
    for child in node.get_children():
        style_tree(child)


static func style_button(button: Button, accent: Color = GOLD) -> void:
    button.add_theme_font_size_override("font_size", maxi(24, button.get_theme_font_size("font_size")))
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_color_override("font_pressed_color", Color(0.02, 0.02, 0.04, 1.0))
    button.add_theme_stylebox_override("normal", _box(Color(0.035, 0.045, 0.11, 0.88), accent, 2, 10))
    button.add_theme_stylebox_override("hover", _box(Color(0.08, 0.06, 0.18, 0.94), CYAN, 3, 10))
    button.add_theme_stylebox_override("pressed", _box(accent, Color.WHITE, 2, 10))
    button.add_theme_stylebox_override("disabled", _box(Color(0.02, 0.025, 0.045, 0.62), Color(0.35, 0.4, 0.48, 0.7), 1, 10))


static func style_panel(panel: PanelContainer, accent: Color = CYAN) -> void:
    panel.add_theme_stylebox_override("panel", _box(PANEL_BG, accent, 2, 12))


static func style_label(label: Label) -> void:
    if label.get_theme_font_size("font_size") <= 0:
        label.add_theme_font_size_override("font_size", 26)
    label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
    label.add_theme_constant_override("shadow_offset_x", 0)
    label.add_theme_constant_override("shadow_offset_y", 2)


static func style_progress(bar: ProgressBar) -> void:
    bar.add_theme_stylebox_override("background", _box(Color(0.02, 0.025, 0.055, 0.85), Color(0.18, 0.24, 0.36, 0.9), 1, 8))
    bar.add_theme_stylebox_override("fill", _box(Color(0.0, 0.75, 1.0, 0.95), Color(0.55, 0.95, 1.0, 0.9), 1, 8))


static func _ensure_backdrop(root: Control) -> void:
    if root.get_node_or_null("PremiumBackdrop") != null:
        return
    var bg := ColorRect.new()
    bg.name = "PremiumBackdrop"
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.color = Color(0.005, 0.008, 0.02, 1.0)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(bg)
    root.move_child(bg, 0)


static func _add_atmosphere(root: Control) -> void:
    var top := ColorRect.new()
    top.anchor_right = 1.0
    top.anchor_bottom = 0.42
    top.color = Color(0.0, 0.25, 0.45, 0.16)
    top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(top)
    var bottom := ColorRect.new()
    bottom.anchor_top = 0.45
    bottom.anchor_right = 1.0
    bottom.anchor_bottom = 1.0
    bottom.color = Color(0.5, 0.0, 0.6, 0.13)
    bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(bottom)


static func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(radius)
    style.shadow_color = Color(border.r, border.g, border.b, 0.22)
    style.shadow_size = 10
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    return style


static func _add_trail(parent: Node2D, color: Color, size_px: float) -> void:
    for i in 3:
        var line := Line2D.new()
        var y := (float(i) - 1.0) * size_px * 0.06
        line.points = PackedVector2Array([Vector2(-size_px * 0.48, y), Vector2(-size_px * 0.22, y * 0.45)])
        line.width = 6.0 - float(i)
        line.default_color = Color(color.r, color.g, color.b, 0.58 - float(i) * 0.12)
        line.begin_cap_mode = Line2D.LINE_CAP_ROUND
        line.end_cap_mode = Line2D.LINE_CAP_ROUND
        parent.add_child(line)


static func _poly(parent: Node2D, points: PackedVector2Array, fill: Color, outline: Color) -> void:
    var p := Polygon2D.new()
    p.polygon = points
    p.color = fill
    parent.add_child(p)
    var l := Line2D.new()
    var closed := PackedVector2Array()
    for point in points:
        closed.append(point)
    if points.size() > 0:
        closed.append(points[0])
    l.points = closed
    l.width = 4.0
    l.default_color = outline
    l.joint_mode = Line2D.LINE_JOINT_ROUND
    l.begin_cap_mode = Line2D.LINE_CAP_ROUND
    l.end_cap_mode = Line2D.LINE_CAP_ROUND
    parent.add_child(l)


static func _line(parent: Node2D, points: PackedVector2Array, color: Color, width: float) -> void:
    var l := Line2D.new()
    l.points = points
    l.width = width
    l.default_color = color
    l.begin_cap_mode = Line2D.LINE_CAP_ROUND
    l.end_cap_mode = Line2D.LINE_CAP_ROUND
    parent.add_child(l)


static func _regular_polygon(count: int, radius: float, rotation: float) -> PackedVector2Array:
    var points := PackedVector2Array()
    for i in count:
        var angle := rotation + TAU * float(i) / float(count)
        points.append(Vector2(cos(angle), sin(angle)) * radius)
    return points


static func _star_points(count: int, outer: float, inner: float) -> PackedVector2Array:
    var points := PackedVector2Array()
    for i in count * 2:
        var radius := outer if i % 2 == 0 else inner
        var angle := -PI * 0.5 + PI * float(i) / float(count)
        points.append(Vector2(cos(angle), sin(angle)) * radius)
    return points


static func _translated(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
    var next := PackedVector2Array()
    for point in points:
        next.append(point + offset)
    return next
