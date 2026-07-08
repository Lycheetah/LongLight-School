extends RefCounted
## GBA / DS-quality runtime pixel factory.
## 16×16 tiles + character sheets + UI chrome. Nearest-neighbor only.

const TS := 16  # native tile size (scaled ×2 → 32 world px)


static func make_texture(w: int, h: int, paint: Callable) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	paint.call(img)
	return ImageTexture.create_from_image(img)


static func px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	img.set_pixel(x, y, c)


static func fill_rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			px(img, xx, yy, c)


static func outline_rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for xx in range(x, x + w):
		px(img, xx, y, c)
		px(img, xx, y + h - 1, c)
	for yy in range(y, y + h):
		px(img, x, yy, c)
		px(img, x + w - 1, yy, c)


# ── Tileset atlas: one 16×16 per tile id (0..15) in a row ─────────────────────
static func tileset_atlas() -> ImageTexture:
	var n := 20
	return make_texture(TS * n, TS, func(img: Image):
		for id in n:
			_paint_tile(img, id * TS, 0, id)
	)


static func _paint_tile(img: Image, ox: int, oy: int, id: int) -> void:
	# Palettes inspired by GBA Mystery Dungeon / RSE outdoor
	var g0 := Color("3d9e4a")
	var g1 := Color("2f7d3a")
	var g2 := Color("56b85f")
	var path0 := Color("c9b48a")
	var path1 := Color("b39b72")
	var path2 := Color("9a845c")
	var wall0 := Color("5a4e78")
	var wall1 := Color("3e3658")
	var wall2 := Color("7a6c9a")
	var floor0 := Color("6b5b8c")
	var floor1 := Color("564874")
	var water0 := Color("3a7ec8")
	var water1 := Color("2a5fa0")
	var water2 := Color("7ec8f0")
	match id:
		0: # void
			fill_rect(img, ox, oy, TS, TS, Color("0c0818"))
		1: # floor stone
			fill_rect(img, ox, oy, TS, TS, floor0)
			for yy in range(0, TS, 4):
				for xx in range(0, TS, 4):
					var c := floor1 if ((xx + yy) / 4) % 2 == 0 else floor0
					fill_rect(img, ox + xx, oy + yy, 4, 4, c)
			outline_rect(img, ox, oy, TS, TS, wall1.darkened(0.2))
		2: # wall brick
			fill_rect(img, ox, oy, TS, TS, wall1)
			for row in 4:
				var yoff := row * 4
				var xoff := 0 if row % 2 == 0 else 4
				for col in 3:
					fill_rect(img, ox + xoff + col * 8, oy + yoff, 7, 3, wall0 if (col + row) % 2 == 0 else wall2)
			fill_rect(img, ox, oy, TS, 2, wall2)  # top lip
			fill_rect(img, ox, oy + TS - 2, TS, 2, Color(0, 0, 0, 0.35))
		3: # grass
			fill_rect(img, ox, oy, TS, TS, g1)
			for i in 12:
				var gx := (i * 5 + id * 3) % 14 + 1
				var gy := (i * 7) % 12 + 2
				px(img, ox + gx, oy + gy, g2 if i % 2 == 0 else g0)
				px(img, ox + gx, oy + gy - 1, g0)
			# soft checker
			for yy in range(0, TS, 2):
				for xx in range(0, TS, 2):
					if (xx + yy) % 4 == 0:
						px(img, ox + xx, oy + yy, g0)
		4: # path dirt
			fill_rect(img, ox, oy, TS, TS, path0)
			for i in 8:
				var sx := (i * 3) % 14 + 1
				var sy := (i * 5) % 14 + 1
				px(img, ox + sx, oy + sy, path2)
				px(img, ox + sx + 1, oy + sy, path1)
			outline_rect(img, ox, oy, TS, TS, path2)
		5: # door
			fill_rect(img, ox, oy, TS, TS, Color("4a3820"))
			fill_rect(img, ox + 2, oy + 1, 12, 14, Color("6b4e2e"))
			fill_rect(img, ox + 3, oy + 2, 10, 12, Color("8a6540"))
			# panels
			fill_rect(img, ox + 4, oy + 3, 3, 5, Color("5a4028"))
			fill_rect(img, ox + 9, oy + 3, 3, 5, Color("5a4028"))
			fill_rect(img, ox + 4, oy + 9, 3, 4, Color("5a4028"))
			fill_rect(img, ox + 9, oy + 9, 3, 4, Color("5a4028"))
			px(img, ox + 11, oy + 8, Color("f0d080"))  # knob
		6: # shrine
			fill_rect(img, ox, oy, TS, TS, floor1)
			fill_rect(img, ox + 2, oy + 10, 12, 5, Color("5a4a30"))
			fill_rect(img, ox + 4, oy + 6, 8, 6, Color("c8a86e"))
			fill_rect(img, ox + 5, oy + 4, 6, 3, Color("f0d080"))
			# flame
			px(img, ox + 7, oy + 3, Color("ff6b35"))
			px(img, ox + 8, oy + 2, Color("ffaa44"))
			px(img, ox + 7, oy + 2, Color("ff6b35"))
			px(img, ox + 8, oy + 3, Color("ffcc66"))
		7: # exit / portal base
			fill_rect(img, ox, oy, TS, TS, Color("2a1848"))
			outline_rect(img, ox + 2, oy + 2, 12, 12, Color("9b59b6"))
			outline_rect(img, ox + 4, oy + 4, 8, 8, Color("00d4ff"))
			fill_rect(img, ox + 6, oy + 6, 4, 4, Color("c080ff"))
		8: # water
			fill_rect(img, ox, oy, TS, TS, water1)
			for yy in range(TS):
				for xx in range(TS):
					if (xx + yy * 2) % 5 == 0:
						px(img, ox + xx, oy + yy, water0)
			# highlight wave
			for xx in range(2, 14):
				px(img, ox + xx, oy + 4 + (xx % 3), water2)
				px(img, ox + xx, oy + 10 + ((xx + 1) % 3), Color(water2, 0.5))
		9: # floor2 (lighter hall)
			fill_rect(img, ox, oy, TS, TS, floor0.lightened(0.08))
			for yy in range(0, TS, 8):
				for xx in range(0, TS, 8):
					outline_rect(img, ox + xx, oy + yy, 8, 8, floor1)
		10: # tree canopy tile (solid)
			fill_rect(img, ox, oy, TS, TS, g1.darkened(0.15))
			fill_rect(img, ox + 6, oy + 10, 4, 6, Color("5a3a20"))
			# leaves clusters
			_blob(img, ox + 8, oy + 6, 6, Color("1e5a30"))
			_blob(img, ox + 5, oy + 7, 5, Color("2a7040"))
			_blob(img, ox + 11, oy + 7, 5, Color("246838"))
			_blob(img, ox + 8, oy + 4, 4, Color("3a8850"))
		11: # sand
			fill_rect(img, ox, oy, TS, TS, Color("d2c090"))
			for i in 6:
				px(img, ox + (i * 3) % 14 + 1, oy + (i * 5) % 14 + 1, Color("b8a070"))
		12: # rug
			fill_rect(img, ox, oy, TS, TS, Color("6a2848"))
			outline_rect(img, ox + 1, oy + 1, 14, 14, Color("f0d080"))
			fill_rect(img, ox + 3, oy + 3, 10, 10, Color("8a3060"))
			outline_rect(img, ox + 5, oy + 5, 6, 6, Color("f0d080"))
		13: # altar
			fill_rect(img, ox, oy, TS, TS, floor1)
			fill_rect(img, ox + 1, oy + 8, 14, 7, Color("4a3a28"))
			fill_rect(img, ox + 2, oy + 6, 12, 5, Color("c8a86e"))
			fill_rect(img, ox + 4, oy + 3, 8, 4, Color("f0d080"))
			px(img, ox + 7, oy + 2, Color("00d4ff"))
			px(img, ox + 8, oy + 2, Color("00d4ff"))
		14: # warp
			fill_rect(img, ox, oy, TS, TS, Color("1a2848"))
			for r in [6, 4, 2]:
				_ring(img, ox + 8, oy + 8, r, Color("00d4ff") if r != 4 else Color("9b59b6"))
			px(img, ox + 8, oy + 8, Color("ffffff"))
		15: # tall grass
			fill_rect(img, ox, oy, TS, TS, g1)
			for i in 8:
				var bx := 1 + i * 2
				var h := 6 + (i % 3) * 2
				for yy in range(h):
					px(img, ox + bx, oy + TS - 2 - yy, g0 if yy % 2 == 0 else g2)
					if yy > h / 2:
						px(img, ox + bx + 1, oy + TS - 2 - yy, g2)
			for i in 4:
				px(img, ox + 2 + i * 4, oy + 3, Color("8fd98a"))
		16: # crack in wall
			fill_rect(img, ox, oy, TS, TS, wall1)
			for i in 5:
				px(img, ox + 6 + i, oy + 4 + i, Color("1a1020"))
				px(img, ox + 7 + i, oy + 4 + i, Color("0a0810"))
			px(img, ox + 8, oy + 8, Color("f0d080"))
		17: # dig spot
			fill_rect(img, ox, oy, TS, TS, path1)
			_blob(img, ox + 8, oy + 9, 4, path2)
			px(img, ox + 6, oy + 7, Color("3a2810"))
			px(img, ox + 10, oy + 10, Color("3a2810"))
		18: # flower / sparkle ground
			fill_rect(img, ox, oy, TS, TS, g1)
			px(img, ox + 7, oy + 6, Color("f0d080"))
			px(img, ox + 8, oy + 7, Color("00d4ff"))
			px(img, ox + 9, oy + 6, Color("f0d080"))
			px(img, ox + 8, oy + 5, Color("ffffff"))
			px(img, ox + 5, oy + 10, Color("e88"))
			px(img, ox + 11, oy + 11, Color("c8f"))
		19: # bush
			fill_rect(img, ox, oy, TS, TS, g1)
			_blob(img, ox + 8, oy + 9, 6, Color("1e5a30"))
			_blob(img, ox + 5, oy + 10, 4, Color("2a7040"))
			_blob(img, ox + 11, oy + 10, 4, Color("246838"))
		_:
			fill_rect(img, ox, oy, TS, TS, Color.MAGENTA)


static func _blob(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			var dx := x - cx
			var dy := y - cy
			if dx * dx + dy * dy <= r * r:
				px(img, x, y, c)


static func _ring(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for a in range(32):
		var ang := float(a) / 32.0 * TAU
		px(img, cx + int(cos(ang) * r), cy + int(sin(ang) * r), c)


# ── Characters: 16×24 sheets, 4 dirs × 3 frames ─────────────────────────────
# Layout: row = dir (0 down, 1 left, 2 right, 3 up), col = frame 0..2
static func player_sheet(body: Color) -> ImageTexture:
	return make_texture(16 * 3, 24 * 4, func(img: Image):
		for d in 4:
			for f in 3:
				_paint_player_frame(img, f * 16, d * 24, body, d, f)
	)


static func _paint_player_frame(img: Image, ox: int, oy: int, body: Color, dir: int, frame: int) -> void:
	var shade := body.darkened(0.3)
	var light := body.lightened(0.15)
	var skin := Color("f0c8a0")
	var outline := Color("1a1020")
	var leg_off := 0
	if frame == 1:
		leg_off = 1
	elif frame == 2:
		leg_off = -1
	# shadow
	fill_rect(img, ox + 3, oy + 21, 10, 2, Color(0, 0, 0, 0.3))
	# legs
	fill_rect(img, ox + 4 + leg_off, oy + 16, 3, 5, shade)
	fill_rect(img, ox + 9 - leg_off, oy + 16, 3, 5, shade)
	# body
	fill_rect(img, ox + 4, oy + 10, 8, 7, body)
	fill_rect(img, ox + 3, oy + 11, 10, 5, body)
	# belt
	fill_rect(img, ox + 4, oy + 15, 8, 1, Color("f0d080"))
	# head
	fill_rect(img, ox + 4, oy + 3, 8, 7, skin)
	fill_rect(img, ox + 5, oy + 2, 6, 2, skin)
	# hair / hood by dir
	fill_rect(img, ox + 4, oy + 2, 8, 3, light)
	# eyes by direction
	match dir:
		0: # down
			px(img, ox + 6, oy + 6, outline)
			px(img, ox + 9, oy + 6, outline)
		1: # left
			px(img, ox + 5, oy + 6, outline)
		2: # right
			px(img, ox + 10, oy + 6, outline)
		3: # up
			fill_rect(img, ox + 4, oy + 2, 8, 4, light)  # hair covers face
	# outline hints
	for p in [[3, 11], [12, 11], [4, 3], [11, 3]]:
		px(img, ox + p[0], oy + p[1], outline)
	# cape
	if dir != 3:
		fill_rect(img, ox + 2, oy + 11, 2, 5, shade)
		fill_rect(img, ox + 12, oy + 11, 2, 5, shade)


static func npc_sheet(body: Color) -> ImageTexture:
	return make_texture(16 * 3, 24 * 4, func(img: Image):
		for d in 4:
			for f in 3:
				_paint_npc_frame(img, f * 16, d * 24, body, d, f)
	)


static func _paint_npc_frame(img: Image, ox: int, oy: int, body: Color, dir: int, frame: int) -> void:
	var shade := body.darkened(0.25)
	var skin := Color("e8b890")
	var outline := Color("1a1020")
	var leg := 1 if frame == 1 else (-1 if frame == 2 else 0)
	fill_rect(img, ox + 3, oy + 21, 10, 2, Color(0, 0, 0, 0.28))
	fill_rect(img, ox + 5 + leg, oy + 16, 2, 5, shade)
	fill_rect(img, ox + 9 - leg, oy + 16, 2, 5, shade)
	fill_rect(img, ox + 4, oy + 10, 8, 7, body)
	fill_rect(img, ox + 5, oy + 3, 6, 7, skin)
	fill_rect(img, ox + 4, oy + 2, 8, 3, shade)
	match dir:
		0:
			px(img, ox + 6, oy + 6, outline)
			px(img, ox + 9, oy + 6, outline)
		1:
			px(img, ox + 5, oy + 6, outline)
		2:
			px(img, ox + 10, oy + 6, outline)


static func companion_sheet() -> ImageTexture:
	# 2 frame bob, single "dir"
	return make_texture(16 * 2, 16, func(img: Image):
		for f in 2:
			_paint_orb(img, f * 16, 0, f)
	)


static func _paint_orb(img: Image, ox: int, oy: int, frame: int) -> void:
	var bob := 1 if frame == 1 else 0
	var c := Color("00d4ff")
	var g := Color("f0d080")
	fill_rect(img, ox + 3, oy + 13, 10, 2, Color(0, 0, 0, 0.25))
	for y in range(2 + bob, 13 + bob):
		for x in range(3, 13):
			var dx := x - 7.5
			var dy := y - (7.5 + bob)
			if dx * dx + dy * dy <= 22.0:
				px(img, ox + x, oy + y, c)
			if dx * dx + dy * dy <= 10.0:
				px(img, ox + x, oy + y, c.lightened(0.3))
	# ring
	for a in range(16):
		var ang := float(a) / 16.0 * TAU
		px(img, ox + 8 + int(cos(ang) * 6), oy + 7 + bob + int(sin(ang) * 6), g)
	px(img, ox + 8, oy + 7 + bob, Color.WHITE)


static func foe_tex(col: Color) -> ImageTexture:
	return make_texture(32, 32, func(img: Image):
		fill_rect(img, 8, 28, 16, 3, Color(0, 0, 0, 0.35))
		# body mass with outline
		for y in range(4, 28):
			for x in range(4, 28):
				var dx := x - 15.5
				var dy := y - 15.5
				var d2 := dx * dx + dy * dy * 0.9
				if d2 <= 120.0:
					px(img, x, y, col.darkened(0.35))  # outline shell
				if d2 <= 95.0:
					px(img, x, y, col)
				if d2 <= 40.0:
					px(img, x, y, col.lightened(0.2))
		# eyes
		fill_rect(img, 10, 12, 4, 4, Color.WHITE)
		fill_rect(img, 18, 12, 4, 4, Color.WHITE)
		fill_rect(img, 11, 13, 2, 2, Color.BLACK)
		fill_rect(img, 19, 13, 2, 2, Color.BLACK)
		# brow
		fill_rect(img, 10, 11, 4, 1, Color(0.1, 0, 0))
		fill_rect(img, 18, 11, 4, 1, Color(0.1, 0, 0))
		# mouth
		fill_rect(img, 13, 20, 6, 2, Color(0.15, 0, 0.05))
	)


# ── UI chrome (Pokémon-style window) ─────────────────────────────────────────
static func window_frame(w: int, h: int) -> ImageTexture:
	return make_texture(w, h, func(img: Image):
		var border := Color("f0d080")
		var border_d := Color("8a7038")
		var fill := Color("1a1430")
		var fill2 := Color("221a3c")
		fill_rect(img, 0, 0, w, h, border_d)
		fill_rect(img, 2, 2, w - 4, h - 4, border)
		fill_rect(img, 4, 4, w - 8, h - 8, fill)
		# inner gradient stripes
		for yy in range(4, h - 4):
			if yy % 3 == 0:
				for xx in range(4, w - 4):
					px(img, xx, yy, fill2)
		# corners gems
		fill_rect(img, 0, 0, 6, 6, border)
		fill_rect(img, w - 6, 0, 6, 6, border)
		fill_rect(img, 0, h - 6, 6, 6, border)
		fill_rect(img, w - 6, h - 6, 6, 6, border)
		px(img, 2, 2, Color("00d4ff"))
		px(img, w - 3, 2, Color("00d4ff"))
		px(img, 2, h - 3, Color("00d4ff"))
		px(img, w - 3, h - 3, Color("00d4ff"))
	)


static func name_tag(w: int = 80, h: int = 16) -> ImageTexture:
	return make_texture(w, h, func(img: Image):
		fill_rect(img, 0, 0, w, h, Color("f0d080"))
		fill_rect(img, 2, 2, w - 4, h - 4, Color("2a2040"))
	)
