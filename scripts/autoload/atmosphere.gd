extends CanvasLayer
## Day/night + mood tint — Zelda/Pokémon outdoor feel.

signal phase_changed(phase: String)

var time_of_day: float = 0.35  # 0..1, start morning
var speed: float = 0.008  # slow cycle
var paused: bool = false
var _overlay: ColorRect


func _ready() -> void:
	layer = 5
	_overlay = ColorRect.new()
	_overlay.name = "Tint"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0)
	add_child(_overlay)


func _process(delta: float) -> void:
	if paused or GameState.in_battle:
		return
	var prev := phase_name()
	time_of_day = fmod(time_of_day + delta * speed, 1.0)
	_overlay.color = _tint_for(time_of_day)
	if phase_name() != prev:
		phase_changed.emit(phase_name())


func phase_name() -> String:
	if time_of_day < 0.2:
		return "dawn"
	if time_of_day < 0.45:
		return "day"
	if time_of_day < 0.55:
		return "golden"
	if time_of_day < 0.7:
		return "dusk"
	if time_of_day < 0.9:
		return "night"
	return "late_night"


func _tint_for(t: float) -> Color:
	# soft multiply-ish overlay (additive darkening via alpha)
	if t < 0.2:  # dawn rose
		return Color(0.9, 0.55, 0.4, 0.12 + (0.2 - t) * 0.2)
	if t < 0.45:  # clear day
		return Color(1, 1, 1, 0.0)
	if t < 0.55:  # golden hour
		return Color(1.0, 0.75, 0.35, 0.1)
	if t < 0.7:  # dusk
		return Color(0.55, 0.35, 0.7, 0.16)
	if t < 0.9:  # night
		return Color(0.1, 0.12, 0.35, 0.28)
	return Color(0.05, 0.08, 0.25, 0.34)


func set_battle_mode(on: bool) -> void:
	paused = on
	if on:
		_overlay.color = Color(0.15, 0.05, 0.2, 0.35)
