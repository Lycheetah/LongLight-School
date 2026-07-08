extends Node2D
## GBA/DS-style map: textured 16px tiles scaled to 32 world px.

const PixelArtUtil = preload("res://scripts/util/pixel_art.gd")
const SCALE := 2  # 16 → 32
const TS := 16

var _time: float = 0.0
var _atlas: ImageTexture
var _npc_cache: Dictionary = {}  # color key -> sheet


func _ready() -> void:
	_atlas = PixelArtUtil.tileset_atlas()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process(delta: float) -> void:
	_time += delta
	# animate water / tall grass / warps
	if int(_time * 6.0) != int((_time - delta) * 6.0):
		queue_redraw()


func _draw() -> void:
	var ow: Node = get_parent()
	if ow.tiles.is_empty() or _atlas == null:
		return
	var pulse: float = 0.5 + 0.5 * sin(_time * 3.0)

	for y in ow.area_h:
		for x in ow.area_w:
			var t: int = clampi(int(ow.tiles[y][x]), 0, 19)
			var dst := Rect2(x * 32, y * 32, 32, 32)
			var src := Rect2(t * TS, 0, TS, TS)
			# water / tall grass subtle UV bob via alternate draw offset
			if t == AreaData.T_WATER:
				var bob := int(sin(_time * 2.0 + x * 0.5) * 1.0)
				draw_texture_rect_region(_atlas, dst, Rect2(t * TS, 0, TS, TS))
				# shimmer overlay
				draw_rect(Rect2(x * 32, y * 32 + 6 + bob, 32, 2), Color(1, 1, 1, 0.06))
			elif t == AreaData.T_TALL:
				draw_texture_rect_region(_atlas, dst, src)
				# sway tips
				draw_rect(Rect2(x * 32 + 4 + sin(_time * 3 + y) * 2, y * 32 + 4, 2, 6), Color(0.4, 0.7, 0.4, 0.35))
			elif t == AreaData.T_WARP:
				draw_texture_rect_region(_atlas, dst, src)
				draw_arc(Vector2(x * 32 + 16, y * 32 + 16), 6.0 + pulse * 3.0, 0, TAU, 16, Color(0, 0.83, 1, 0.35), 1.5)
			elif t == AreaData.T_SHRINE:
				draw_texture_rect_region(_atlas, dst, src)
				draw_circle(Vector2(x * 32 + 16, y * 32 + 10), 3.0 + pulse, Color(1, 0.5, 0.2, 0.4 + pulse * 0.2))
			else:
				draw_texture_rect_region(_atlas, dst, src)

	# depth-sorted NPCs (by y)
	var npc_list: Array = ow.npcs.duplicate()
	npc_list.sort_custom(func(a, b): return float(a.y) < float(b.y))
	for n in npc_list:
		_draw_npc(n, pulse)

	# ambient life (fireflies / motes)
	for a in ow._ambient:
		var ap := Vector2(float(a.x), float(a.y))
		var col := Color(1, 1, 0.6, 0.55 + 0.35 * sin(float(a.phase))) if str(a.kind) == "firefly" else Color(1, 1, 1, 0.2)
		draw_circle(ap, 2.0 if str(a.kind) == "firefly" else 1.2, col)

	# wanderers
	for w in ow.wanderers:
		var wp := Vector2(float(w.x) * 32, float(w.y) * 32)
		var wc: Color = w.get("color", Color.WHITE)
		draw_circle(Vector2(wp.x, wp.y + 6), 6, Color(0, 0, 0, 0.25))
		draw_rect(Rect2(wp.x - 8, wp.y - 14, 16, 18), wc)
		draw_rect(Rect2(wp.x - 6, wp.y - 20, 12, 8), wc.lightened(0.2))
		draw_circle(Vector2(wp.x, wp.y - 24 - pulse * 2), 2, Color("f0d080"))

	# false wall shimmer (hint for observant players)
	for fw in ow.false_walls:
		var fp := Vector2(int(fw.x) * 32 + 16, int(fw.y) * 32 + 16)
		if pulse > 0.85:
			draw_rect(Rect2(fp.x - 14, fp.y - 14, 28, 28), Color(1, 1, 1, 0.04))

	# chests
	for c in ow.chests:
		var ck := "%s:%d:%d" % [GameState.area_id, int(c.x), int(c.y)]
		var open := GameState.chest_taken(ck)
		var p := Vector2(int(c.x) * 32 + 16, int(c.y) * 32 + 16)
		draw_rect(Rect2(p.x - 8, p.y - 6, 16, 12), Color("5a3a18") if open else Color("c8a050"))
		draw_rect(Rect2(p.x - 6, p.y - 4, 12, 8), Color("3a2810") if open else Color("f0d080"))
		if not open:
			draw_circle(p + Vector2(0, -10 - pulse * 2), 2, Color("00d4ff"))
	# signs
	for s in ow.signs:
		var p2 := Vector2(int(s.x) * 32 + 16, int(s.y) * 32 + 16)
		draw_rect(Rect2(p2.x - 6, p2.y - 10, 12, 10), Color("8a6a30"))
		draw_rect(Rect2(p2.x - 2, p2.y, 4, 6), Color("5a4020"))
	# tablets
	for t in ow.tablets:
		var p3 := Vector2(int(t.x) * 32 + 16, int(t.y) * 32 + 16)
		draw_rect(Rect2(p3.x - 8, p3.y - 8, 16, 14), Color("6a6a80"))
		draw_rect(Rect2(p3.x - 6, p3.y - 6, 12, 10), Color("9a9ab0"))
		draw_circle(p3 + Vector2(0, -12), 2, Color("f0d080"))

	# encounter glows
	for s in ow.spawns:
		var key := "%d,%d" % [int(s.x), int(s.y)]
		if ow.spawn_dead.get(key, false):
			continue
		if s.has("flag") and GameState.has_flag(str(s.flag)) and bool(s.get("once", true)):
			continue
		var p2 := Vector2(int(s.x) * 32 + 16, int(s.y) * 32 + 16)
		var boss: bool = bool(s.get("boss", false))
		var rad := 6.0 + pulse * (4.0 if boss else 2.0)
		draw_circle(p2, rad + 6, Color(0.9, 0.2, 0.15, 0.12))
		draw_circle(p2, rad, Color("e74c3c") if not boss else Color("9b59b6"))
		draw_arc(p2, rad + 3, 0, TAU, 20, Color("f0d080"), 1.5)


func _draw_npc(n: Dictionary, pulse: float) -> void:
	var p := Vector2(float(n.x) * 32, float(n.y) * 32)
	var col: Color = n.get("color", Color.WHITE)
	var key := str(col)
	if not _npc_cache.has(key):
		_npc_cache[key] = PixelArtUtil.npc_sheet(col)
	var sheet: Texture2D = _npc_cache[key]
	# idle bob frame
	var frame := int(_time * 3.0) % 3
	var dir := 0  # face down
	var src := Rect2(frame * 16, dir * 24, 16, 24)
	var dst := Rect2(p.x - 16, p.y - 36, 32, 48)
	# shadow
	draw_ellipse(Vector2(p.x, p.y + 4), Vector2(10, 4), Color(0, 0, 0, 0.3))
	draw_texture_rect_region(sheet, dst, src)
	# name gem
	draw_circle(Vector2(p.x, p.y - 40 - pulse * 2), 2.5, Color("f0d080"))


func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := float(i) / 16.0 * TAU
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, color)
