## PremiumUI
##
## Shared visual polish helpers for existing Control scenes.
extends RefCounted

const CYAN := Color(0.0, 0.941, 1.0, 1.0)
const PINK := Color(1.0, 0.169, 0.839, 1.0)
const GOLD := Color(1.0, 0.76, 0.05, 1.0)
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
