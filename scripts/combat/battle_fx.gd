extends Node2D
## Arena cast / hit juice — glyphs, flashes, particles. Parent under battle panel.

var _fx: Array = []  # {kind, t, life, pos, color, text, r}


func cast(skill: int, origin: Vector2) -> void:
	var col := _skill_color(skill)
	var glyph := _skill_glyph(skill)
	_fx.append({"kind": "flash", "t": 0.0, "life": 0.22, "pos": origin, "color": col, "r": 40.0})
	_fx.append({"kind": "glyph", "t": 0.0, "life": 0.55, "pos": origin + Vector2(0, -20), "color": col, "text": glyph, "r": 0.0})
	for i in 8:
		var ang := TAU * float(i) / 8.0 + randf() * 0.2
		_fx.append({
			"kind": "spark",
			"t": 0.0,
			"life": 0.35 + randf() * 0.2,
			"pos": origin,
			"color": col,
			"vel": Vector2(cos(ang), sin(ang)) * randf_range(80, 160),
			"r": 3.0,
		})
	queue_redraw()


func hit_flash(origin: Vector2, heavy: bool = false) -> void:
	var col := Color("ff6644") if heavy else Color("ffe08a")
	_fx.append({"kind": "flash", "t": 0.0, "life": 0.18 if not heavy else 0.28, "pos": origin, "color": col, "r": 55.0 if heavy else 30.0})
	for i in (12 if heavy else 6):
		var ang := randf() * TAU
		_fx.append({
			"kind": "spark",
			"t": 0.0,
			"life": 0.25 + randf() * 0.15,
			"pos": origin,
			"color": col,
			"vel": Vector2(cos(ang), sin(ang)) * randf_range(60, 200),
			"r": 2.5,
		})
	queue_redraw()


func heal_burst(origin: Vector2) -> void:
	var col := Color("5dff9a")
	_fx.append({"kind": "flash", "t": 0.0, "life": 0.3, "pos": origin, "color": col, "r": 45.0})
	_fx.append({"kind": "glyph", "t": 0.0, "life": 0.5, "pos": origin + Vector2(0, -16), "color": col, "text": "☿", "r": 0.0})
	queue_redraw()


func guard_ring(origin: Vector2) -> void:
	_fx.append({"kind": "ring", "t": 0.0, "life": 0.4, "pos": origin, "color": Color("6aa8ff"), "r": 10.0})
	queue_redraw()


func _skill_color(skill: int) -> Color:
	match skill:
		1: return Color("7ec8ff")
		2: return Color("c070ff")
		3: return Color("5dff9a")
		4: return Color("ff8844")
		5: return Color("ffe08a")
		6: return Color("6aa8ff")
		7: return Color("f0d080")
		8: return Color("e8c070")
		9: return Color("9ad0ff")
		0: return Color("ff6030")
		_: return Color.WHITE


func _skill_glyph(skill: int) -> String:
	match skill:
		1: return "Π"
		2: return "⟁"
		3: return "☿"
		4: return "∴"
		5: return "⟡"
		6: return "▣"
		7: return "⊚"
		8: return "✦"
		9: return "ΠΠ"
		0: return "☀"
		_: return "·"


func _process(delta: float) -> void:
	if _fx.is_empty():
		return
	var next: Array = []
	for f in _fx:
		f.t = float(f.t) + delta
		if str(f.kind) == "spark" and f.has("vel"):
			f.pos = Vector2(f.pos) + Vector2(f.vel) * delta
			f.vel = Vector2(f.vel) * 0.92
		if float(f.t) < float(f.life):
			next.append(f)
	_fx = next
	queue_redraw()


func _draw() -> void:
	for f in _fx:
		var life: float = float(f.life)
		var t: float = float(f.t)
		var a: float = clampf(1.0 - t / life, 0.0, 1.0)
		var col: Color = f.color
		col.a = a
		var pos: Vector2 = f.pos
		match str(f.kind):
			"flash":
				var r: float = float(f.r) * (0.6 + 0.4 * (1.0 - a))
				draw_circle(pos, r, Color(col.r, col.g, col.b, a * 0.35))
				draw_circle(pos, r * 0.45, Color(col.r, col.g, col.b, a * 0.55))
			"spark":
				draw_circle(pos, float(f.get("r", 2.0)), col)
			"glyph":
				var font := ThemeDB.fallback_font
				var fs := 28
				draw_string(font, pos + Vector2(-12, -10 - t * 30.0), str(f.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
			"ring":
				var rr: float = 12.0 + t * 80.0
				draw_arc(pos, rr, 0, TAU, 32, col, 2.5)
