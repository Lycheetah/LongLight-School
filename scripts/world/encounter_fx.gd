extends CanvasLayer
## Pokémon-style encounter flash before battle.

signal finished

var _flash: ColorRect
var _bang: Label
var _running: bool = false


func _ready() -> void:
	layer = 30
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0, 0, 0, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_bang = Label.new()
	_bang.text = "!"
	_bang.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bang.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bang.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bang.add_theme_font_size_override("font_size", 96)
	_bang.add_theme_color_override("font_color", Color("f0d080"))
	_bang.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_bang.add_theme_constant_override("shadow_offset_x", 3)
	_bang.add_theme_constant_override("shadow_offset_y", 3)
	_bang.visible = false
	_bang.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bang)
	visible = false


func play_and_wait() -> void:
	if _running:
		return
	_running = true
	visible = true
	_bang.visible = true
	_bang.modulate.a = 1.0
	_flash.color = Color(1, 1, 1, 0)
	SFX.hit()
	var tw := create_tween()
	# ! pop
	_bang.scale = Vector2(0.5, 0.5)
	_bang.pivot_offset = _bang.size / 2.0
	tw.tween_property(_bang, "scale", Vector2(1.2, 1.2), 0.12)
	tw.tween_property(_bang, "scale", Vector2(1.0, 1.0), 0.08)
	# classic black/white flash strips
	for i in 4:
		tw.tween_callback(func():
			_flash.color = Color.BLACK if i % 2 == 0 else Color.WHITE
			_flash.color.a = 0.85
		)
		tw.tween_interval(0.05)
	tw.tween_callback(func():
		_bang.visible = false
		_flash.color = Color(0.1, 0.05, 0.15, 0.9)
	)
	tw.tween_property(_flash, "color:a", 0.0, 0.15)
	tw.tween_callback(func():
		visible = false
		_running = false
		finished.emit()
	)
