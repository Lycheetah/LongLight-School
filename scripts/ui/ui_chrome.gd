extends RefCounted
## Apply Pokémon/GBA-style chrome to Control nodes.
## const UIChromeUtil = preload("res://scripts/ui/ui_chrome.gd")


static func style_panel(panel: Control, gold: bool = true) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1a1430ee")
	sb.border_color = Color("f0d080") if gold else Color("00d4ff")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	if panel is Panel:
		panel.add_theme_stylebox_override("panel", sb)
	elif panel is PanelContainer:
		panel.add_theme_stylebox_override("panel", sb)


static func style_label_title(l: Label) -> void:
	l.add_theme_color_override("font_color", Color("f0d080"))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)


static func style_label_body(l: Label) -> void:
	l.add_theme_color_override("font_color", Color("e8e0f5"))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
