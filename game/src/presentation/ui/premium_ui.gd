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
