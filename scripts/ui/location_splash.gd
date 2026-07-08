extends CanvasLayer
## DS-style location name banner on area enter.

var _panel: Panel
var _label: Label
var _tw: Tween


func _ready() -> void:
	layer = 15
	_panel = Panel.new()
	_panel.position = Vector2(0, 80)
	_panel.size = Vector2(400, 48)
	add_child(_panel)
	var chrome = load("res://scripts/ui/ui_chrome.gd")
	if chrome:
		chrome.style_panel(_panel)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color("f0d080"))
	_panel.add_child(_label)
	visible = false


func show_location(area_name: String) -> void:
	_label.text = area_name
	var vw := get_viewport().get_visible_rect().size.x
	_panel.size = Vector2(minf(520, vw - 40), 52)
	_panel.position = Vector2((vw - _panel.size.x) * 0.5, 72)
	visible = true
	_panel.modulate.a = 0.0
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(_panel, "modulate:a", 1.0, 0.2)
	_tw.tween_interval(1.4)
	_tw.tween_property(_panel, "modulate:a", 0.0, 0.35)
	_tw.tween_callback(func(): visible = false)
