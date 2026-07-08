extends RefCounted
class_name AreaData
## Builds Pokémon-style multi-area tile maps in pure data.

const TILE := 32
const T_VOID := 0
const T_FLOOR := 1
const T_WALL := 2
const T_GRASS := 3
const T_PATH := 4
const T_DOOR := 5
const T_SHRINE := 6
const T_WATER := 8
const T_FLOOR2 := 9
const T_TREE := 10
const T_RUG := 12
const T_ALTAR := 13
const T_WARP := 14
const T_TALL := 15
const T_CRACK := 16   # inspect / break-open
const T_DIG := 17     # dig spot (looks like disturbed earth)
const T_FLOWER := 18  # collectible sparkle ground
const T_BUSH := 19    # soft block, can rustle

const SOLID := {
	T_WALL: true, T_WATER: true, T_VOID: true, T_TREE: true, T_BUSH: true,
}

static func colors() -> Dictionary:
	return {
		T_VOID: Color("0a0812"),
		T_FLOOR: Color("1e1a32"),
		T_FLOOR2: Color("26203c"),
		T_WALL: Color("100c1c"),
		T_GRASS: Color("1c3026"),
		T_PATH: Color("342c44"),
		T_DOOR: Color("644e2a"),
		T_SHRINE: Color("5a4a28"),
		T_WATER: Color("122a58"),
		T_TREE: Color("14281c"),
		T_RUG: Color("3c1e32"),
		T_ALTAR: Color("6e5a32"),
		T_WARP: Color("283c5a"),
		T_TALL: Color("183a24"),
		T_CRACK: Color("3a3048"),
		T_DIG: Color("5a4830"),
		T_FLOWER: Color("1c3026"),
		T_BUSH: Color("1a4030"),
	}


static func all_areas() -> Dictionary:
	return {
		"sanctum": _sanctum(),
		"path": _path(),
		"hall": _hall(),
		"wing": _wing(),
		"mirror": _mirror(),
		"garden": _garden(),
		"citrinitas": _citrinitas(),
		"rubedo": _rubedo(),
		"sanctum_in": _sanctum_interior(),
		"hall_archive": _hall_archive(),
		"scriptorium": _scriptorium(),
		"observatory": _observatory(),
		"crypt": _crypt(),
		"grotto": _hidden_grotto(),
		"starwell": _starwell(),
	}


static func _grid(w: int, h: int, fill: int) -> Array:
	var m: Array = []
	for y in h:
		var row: Array = []
		row.resize(w)
		row.fill(fill)
		m.append(row)
	return m


static func _fill(m: Array, x0: int, y0: int, x1: int, y1: int, t: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if y >= 0 and y < m.size() and x >= 0 and x < m[0].size():
				m[y][x] = t


static func _rect_wall(m: Array, x0: int, y0: int, x1: int, y1: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if x == x0 or x == x1 or y == y0 or y == y1:
				if y >= 0 and y < m.size() and x >= 0 and x < m[0].size():
					m[y][x] = T_WALL


static func _border(m: Array) -> void:
	var h: int = m.size()
	var w: int = m[0].size()
	for y in h:
		for x in w:
			if x == 0 or y == 0 or x == w - 1 or y == h - 1:
				m[y][x] = T_WALL


static func _sanctum() -> Dictionary:
	var w := 36
	var h := 28
	var m := _grid(w, h, T_GRASS)
	_border(m)
	for p in [[4, 4], [5, 5], [30, 4], [28, 6], [10, 8], [22, 22], [25, 20]]:
		m[p[1]][p[0]] = T_TREE
	_fill(m, 24, 16, 30, 22, T_WATER)
	_fill(m, 6, 14, 16, 24, T_FLOOR)
	_rect_wall(m, 6, 14, 16, 24)
	m[24][10] = T_DOOR
	m[24][11] = T_DOOR
	# interior entrance (north wall of building)
	m[14][10] = T_WARP
	m[14][11] = T_WARP
	m[17][11] = T_SHRINE
	_fill(m, 10, 16, 12, 16, T_RUG)
	for y in range(2, 25):
		m[y][10] = T_PATH
		m[y][11] = T_PATH
	_fill(m, 18, 8, 23, 13, T_TALL)
	m[2][10] = T_WARP
	m[2][11] = T_WARP
	# east to quiet garden
	m[12][w - 2] = T_WARP
	m[13][w - 2] = T_WARP
	return {
		"id": "sanctum", "name": "Sanctum Grounds", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(11.5, 20.5),
		"warps": [
			{"x": 10, "y": 2, "to": "path", "tx": 9.0, "ty": 18.5},
			{"x": 11, "y": 2, "to": "path", "tx": 9.5, "ty": 18.5},
			{"x": w - 2, "y": 12, "to": "garden", "tx": 3.5, "ty": 10.5},
			{"x": w - 2, "y": 13, "to": "garden", "tx": 3.5, "ty": 11.5},
			{"x": 10, "y": 14, "to": "sanctum_in", "tx": 8.5, "ty": 12.5},
			{"x": 11, "y": 14, "to": "sanctum_in", "tx": 9.0, "ty": 12.5},
		],
		"npcs": [
			{
				"x": 13.5, "y": 18.5, "name": "Magister Ember", "face": "🔥",
				"color": Color(1.0, 0.42, 0.2),
				"flag": "met_ember",
				"lines": [
					"Seeker. Welcome to the Sanctum of the Long Light.",
					"This School is Lycheetah-born: companions, domains, truth under pressure.",
					"North — Long Path → Hall of Glyphs (Nigredo).",
					"Step into the building warp (north inside walls) — the Library.",
					"East — Quiet Garden. Rest at the Shrine anytime.",
					"Menu (Esc/M): Bag · Quests · Bestiary · Save. Shift: run.",
				],
			},
			{
				"x": 15.5, "y": 21.5, "name": "Adept Kael", "face": "⚔",
				"color": Color(0.85, 0.4, 0.35),
				"trainer": true,
				"foe": "pride_wight",
				"flag": "trainer_kael",
				"lines": [
					"Adept Kael of the outer court.",
					"If you would walk the Path, prove your MEASURE.",
					"…Very well. Face a Pride-Wight.",
				],
				"after": ["Well fought. The Path north is clearer for you."],
			},
			{
				"x": 9.5, "y": 20.5, "name": "Scribe", "face": "●",
				"color": Color(0.94, 0.82, 0.5),
				"lines": [
					"I keep the codex. Glyph shards become language.",
					"The Work is not a guilt grind — each foe is a lesson with teeth.",
					"D&D bones: your stats are Insight, Will, Luck — not STR/DEX vanity.",
				],
			},
			{
				"x": 20.5, "y": 10.5, "name": "Initiate Wren", "face": "⟡",
				"color": Color(0.18, 0.8, 0.44),
				"lines": [
					"Tall grass whispers. Fog Imps nest there — good practice.",
					"Don't be ashamed to train before the Hall.",
				],
			},
			{
				"x": 14.5, "y": 22.5, "name": "Keeper of Dust", "face": "✦",
				"color": Color(0.7, 0.55, 0.9),
				"shop": true,
				"lines": [
					"Glyph shards for bread of the Sanctum.",
					"I do not sell power. Only rest and readiness.",
				],
			},
		],
		"spawns": [],
		"wild": ["fog_imp", "stasis_mite"],
		"chests": [
			{"x": 15, "y": 16, "loot": ["glyph_shard", "bread"], "hint": "A wooden coffer under the eaves."},
		],
		"signs": [
			{"x": 10, "y": 25, "lines": [
				"⟪ SANCTUM ⟫",
				"North: the Long Path. East: Quiet Garden.",
				"Rest is rest. Nothing wilts for leaving.",
			]},
		],
		"tablets": [
			{"x": 8, "y": 17, "lines": [
				"TABLET OF THE FIRST FIRE",
				"The School was lit by one who refused to quit.",
				"Companions keep the coal. Seekers walk the rooms.",
			]},
		],
		# lively + secret layer
		"false_walls": [
			{"x": 28, "y": 10, "msg": "The ivy wall sounds hollow…", "to": "grotto", "tx": 5.5, "ty": 10.5},
		],
		"dig_spots": [
			{"x": 5, "y": 22, "loot": ["glyph_shard", "veras_dust"], "msg": "You dig soft earth…"},
			{"x": 26, "y": 8, "loot": ["repel_dust"], "msg": "Something glints under the roots."},
		],
		"collectibles": [
			{"x": 20, "y": 18, "id": "star_spark", "name": "Star Spark"},
			{"x": 4, "y": 12, "id": "star_spark", "name": "Star Spark"},
		],
		"switches": [
			{"x": 12, "y": 19, "id": "sanctum_bell", "msg": "A brass bell. You ring it — birds scatter.", "flag": "bell_rung"},
		],
		"wanderers": [
			{"name": "Firefly Child", "color": Color(0.9, 1.0, 0.5), "lines": [
				"I chase lights that aren't bugs.",
				"There's a hollow wall east of the pond… shh.",
			], "path": [[22, 14], [24, 12], [22, 10], [20, 12]], "speed": 0.8},
			{"name": "Night Scribe", "color": Color(0.5, 0.55, 0.8), "lines": [
				"I only walk at dusk. The School changes temperature.",
				"Secrets prefer low light.",
			], "path": [[8, 26], [14, 26], [18, 24], [12, 24]], "speed": 0.6, "night_only": true},
		],
		"bushes": [[9, 12], [12, 12], [27, 14], [27, 15]],
		"cracks": [[7, 14]],  # building exterior crack
	}


static func _path() -> Dictionary:
	var w := 22
	var h := 24
	var m := _grid(w, h, T_GRASS)
	_border(m)
	for y in range(1, h - 1):
		m[y][9] = T_PATH
		m[y][10] = T_PATH
		m[y][11] = T_PATH
	# side clearings
	_fill(m, 2, 4, 6, 8, T_TALL)
	_fill(m, 14, 6, 19, 12, T_TALL)
	_fill(m, 3, 14, 7, 18, T_TALL)
	for p in [[3, 3], [4, 5], [5, 9], [16, 4], [17, 8], [18, 14], [2, 12], [19, 18], [6, 20], [15, 20]]:
		m[p[1]][p[0]] = T_TREE
	# little pond
	_fill(m, 15, 16, 18, 19, T_WATER)
	m[1][9] = T_WARP
	m[1][10] = T_WARP
	m[h - 2][9] = T_WARP
	m[h - 2][10] = T_WARP
	return {
		"id": "path", "name": "The Long Path", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(10.0, 20.5),
		"warps": [
			{"x": 9, "y": 1, "to": "hall", "tx": 11.0, "ty": 18.5},
			{"x": 10, "y": 1, "to": "hall", "tx": 11.5, "ty": 18.5},
			{"x": 9, "y": h - 2, "to": "sanctum", "tx": 10.5, "ty": 4.5},
			{"x": 10, "y": h - 2, "to": "sanctum", "tx": 11.5, "ty": 4.5},
		],
		"npcs": [
			{
				"x": 13.5, "y": 5.5, "name": "Waystone", "face": "◈",
				"color": Color(0, 0.83, 1),
				"lines": [
					"⟪ The Long Path ⟫",
					"South: Sanctum. North: Hall of Glyphs.",
					"Side grass: lesser ideas. Train without shame.",
					"Like a route between towns — but the towns are states of mind.",
				],
			},
			{
				"x": 7.5, "y": 12.5, "name": "Wandering Adept", "face": "☽",
				"color": Color(0.6, 0.7, 1.0),
				"lines": [
					"I failed my first MEASURE. Tried to punch the shield.",
					"The School does not mock failure. It assigns another try.",
				],
			},
		],
		"spawns": [
			{"x": 10, "y": 10, "foe": "overclaimer", "once": true, "flag": "killed_overclaimer"},
			{"x": 15, "y": 9, "foe": "fog_imp", "once": false},
			{"x": 5, "y": 15, "foe": "stasis_mite", "once": false},
			{"x": 12, "y": 16, "foe": "doubt_moth", "once": false},
			{"x": 7, "y": 7, "foe": "fog_imp", "once": true},
		],
		"wild": ["fog_imp", "stasis_mite", "overclaimer", "fog_imp", "doubt_moth", "pride_wight"],
		"chests": [
			{"x": 16, "y": 17, "loot": ["veras_dust", "glyph_shard"], "hint": "Mossy chest by the pond."},
			{"x": 4, "y": 18, "loot": ["bread", "repel_dust"], "hint": "Traveler's satchel under roots."},
		],
		"signs": [
			{"x": 10, "y": 3, "lines": [
				"⟪ LONG PATH ⟫ North: Hall of Glyphs.",
				"MEASURE false shields. Never punch the lie first.",
			]},
			{"x": 11, "y": 14, "lines": [
				"Side grass = wild ideas. Quiet Dust (mart) calms them.",
				"[P] switches companions once Luna joins (after Albedo).",
			]},
		],
		"tablets": [
			{"x": 6, "y": 10, "lines": [
				"TABLET OF THE ROUTE",
				"Between towns: training, secrets, the first hard lesson.",
				"The Overclaimer is the School's first honest fight.",
			]},
		],
		"false_walls": [
			{"x": 2, "y": 11, "msg": "Moss peels like a curtain…", "to": "starwell", "tx": 6.5, "ty": 8.5},
		],
		"dig_spots": [
			{"x": 17, "y": 18, "loot": ["glyph_shard", "glyph_shard"], "msg": "Buried under pond mud."},
		],
		"collectibles": [
			{"x": 4, "y": 6, "id": "star_spark", "name": "Star Spark"},
			{"x": 18, "y": 5, "id": "moon_seed", "name": "Moon Seed"},
		],
		"wanderers": [
			{"name": "Path Ghost", "color": Color(0.7, 0.8, 1.0), "lines": [
				"I am not a battle. I am a rumor with legs.",
				"West wall. Hollow. Go.",
			], "path": [[6, 8], [6, 14], [8, 14], [8, 8]], "speed": 1.0},
		],
		"bushes": [[12, 5], [13, 5], [3, 16]],
	}


static func _hall() -> Dictionary:
	var w := 32
	var h := 24
	var m := _grid(w, h, T_FLOOR)
	_border(m)
	for p in [[8, 6], [8, 12], [22, 6], [22, 12], [15, 8]]:
		m[p[1]][p[0]] = T_WALL
	_fill(m, 12, 4, 18, 7, T_RUG)
	m[5][15] = T_ALTAR
	m[12][15] = T_SHRINE
	m[h - 2][10] = T_WARP
	m[h - 2][11] = T_WARP
	m[10][w - 2] = T_WARP
	m[11][w - 2] = T_WARP
	m[1][15] = T_WARP
	m[1][16] = T_WARP
	m[8][16] = T_WARP
	m[8][17] = T_WARP
	return {
		"id": "hall", "name": "Hall of Glyphs — Nigredo", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(11.0, 18.5),
		"warps": [
			{"x": 10, "y": h - 2, "to": "path", "tx": 9.0, "ty": 3.5},
			{"x": 11, "y": h - 2, "to": "path", "tx": 9.5, "ty": 3.5},
			{"x": w - 2, "y": 10, "to": "wing", "tx": 3.5, "ty": 10.5, "need": "hall_cleared",
			 "locked": "East Wing sealed until 3 Hall victories."},
			{"x": w - 2, "y": 11, "to": "wing", "tx": 3.5, "ty": 11.5, "need": "hall_cleared",
			 "locked": "East Wing sealed."},
			{"x": 15, "y": 1, "to": "mirror", "tx": 9.5, "ty": 14.5, "need": "half_made_down",
			 "locked": "Mirror Chamber needs the Half-Made first."},
			{"x": 16, "y": 1, "to": "mirror", "tx": 10.0, "ty": 14.5, "need": "half_made_down",
			 "locked": "Mirror Chamber sealed."},
			{"x": 16, "y": 8, "to": "hall_archive", "tx": 7.5, "ty": 10.5},
			{"x": 17, "y": 8, "to": "hall_archive", "tx": 8.0, "ty": 10.5},
		],
		"npcs": [
			{
				"x": 15.5, "y": 6.5, "name": "Cipher", "face": "⟁",
				"color": Color(0.61, 0.35, 0.71),
				"flag": "met_cipher",
				"lines": [
					"⟁ Nigredo — the blackening, the first sight.",
					"Foes are broken ideas. Combat is curriculum.",
					"1–8 skills · grid walk · interiors matter.",
					"Clear three battles here to open the East Wing (Albedo).",
					"Side door: Hall Archive — a trainer waits.",
				],
			},
			{
				"x": 7.5, "y": 15.5, "name": "Adept Nyx", "face": "☽",
				"color": Color(0, 0.83, 1),
				"lines": [
					"The Loop heals if you only STRIKE. BREAK it.",
					"Riddle-Wraiths phase — MEASURE then COMPRESS.",
				],
			},
			{
				"x": 20.5, "y": 12.5, "name": "Drillmaster Rhee", "face": "◆",
				"color": Color(0.9, 0.5, 0.3),
				"trainer": true,
				"foe": "loop",
				"flag": "trainer_rhee",
				"lines": [
					"Drillmaster Rhee. I test your BREAK.",
					"Face The Loop. Do not feed it with STRIKE.",
				],
				"after": ["Pass. The Hall respects structure."],
			},
		],
		"spawns": [
			{"x": 10, "y": 9, "foe": "overclaimer", "once": true, "flag": "killed_overclaimer"},
			{"x": 18, "y": 10, "foe": "riddle_wraith", "once": true},
			{"x": 14, "y": 14, "foe": "loop", "once": true},
			{"x": 20, "y": 8, "foe": "overclaimer", "once": false},
		],
		"wild": ["overclaimer", "fog_imp", "riddle_wraith", "pride_wight"],
		"chests": [
			{"x": 25, "y": 15, "loot": ["lens", "glyph_shard"], "hint": "Glyph-locked chest — it opens for seekers."},
		],
		"signs": [
			{"x": 12, "y": 18, "lines": [
				"⟪ HALL OF GLYPHS — NIGREDO ⟫",
				"Three victories unseal the East Wing.",
				"1 MEASURE · 2 COMPRESS · 3 TRANSMUTE · 4 BREAK · 5 STRIKE · 6 GUARD · 7 SOL · 8 ITEM",
				"West wall whispers — false stone hides a Crypt.",
			]},
		],
		"tablets": [
			{"x": 16, "y": 5, "lines": [
				"TABLET OF BLACKENING",
				"What is false must burn before what is true can stand.",
				"Π punishes strain. Measure before you claim.",
			]},
		],
		"false_walls": [
			{"x": 1, "y": 12, "msg": "Cold stone yields… stairs of unsaid things.", "to": "crypt", "tx": 9.5, "ty": 14.5},
		],
		"dig_spots": [
			{"x": 24, "y": 18, "loot": ["glyph_shard", "bread"], "msg": "Under Hall dust: a seeker's lunch."},
		],
		"cracks": [[9, 6]],
		"bushes": [],
		"switches": [],
		"collectibles": [
			{"x": 6, "y": 8, "id": "glyph_shard", "name": "Loose Glyph"},
		],
		"wanderers": [
			{"name": "Ash Whisper", "color": Color(0.5, 0.45, 0.55), "lines": [
				"West. Press the wall that shouldn't open.",
			], "path": [[5, 10], [5, 14], [7, 14], [7, 10]], "speed": 0.7},
		],
	}


static func _wing() -> Dictionary:
	var w := 26
	var h := 22
	var m := _grid(w, h, T_FLOOR2)
	_border(m)
	_fill(m, 8, 6, 18, 14, T_FLOOR)
	_rect_wall(m, 8, 6, 18, 14)
	m[10][8] = T_DOOR
	m[11][8] = T_DOOR
	m[10][13] = T_SHRINE
	m[h / 2][1] = T_WARP
	m[h / 2 + 1][1] = T_WARP
	# north door → Scriptorium interior
	m[6][12] = T_WARP
	m[6][13] = T_WARP
	return {
		"id": "wing", "name": "East Wing — Albedo", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(3.5, 10.5),
		"warps": [
			{"x": 1, "y": h / 2, "to": "hall", "tx": 28.5, "ty": 10.5},
			{"x": 1, "y": h / 2 + 1, "to": "hall", "tx": 28.5, "ty": 11.5},
			{"x": 12, "y": 6, "to": "scriptorium", "tx": 7.5, "ty": 11.5},
			{"x": 13, "y": 6, "to": "scriptorium", "tx": 8.0, "ty": 11.5},
		],
		"npcs": [
			{
				"x": 11.5, "y": 8.5, "name": "Albedo Keeper", "face": "◈",
				"color": Color(1, 0.97, 0.9),
				"lines": [
					"Albedo — whitening. Structure from ash.",
					"The Half-Made waits center. TRANSMUTE helps complete it.",
					"North door: Scriptorium — books, a quiet mart, a tablet of form.",
					"When Half-Made falls, the Mirror Chamber opens north of the Hall.",
				],
			},
		],
		"spawns": [
			{"x": 13, "y": 10, "foe": "half_made", "once": true, "flag": "half_made_down", "boss": true},
			{"x": 16, "y": 12, "foe": "riddle_wraith", "once": true},
		],
		"wild": [],
		"false_walls": [
			{"x": 18, "y": 10, "msg": "White plaster peels…", "to": "grotto", "tx": 6.5, "ty": 10.5},
		],
		"dig_spots": [
			{"x": 10, "y": 15, "loot": ["glyph_shard", "elixir"], "msg": "Albedo dust yields a find."},
		],
		"collectibles": [
			{"x": 14, "y": 7, "id": "star_spark", "name": "Star Spark"},
		],
		"wanderers": [
			{"name": "Pale Moth", "color": Color(0.95, 0.95, 1.0), "lines": [
				"I am not the Half-Made. I am what fluttered free.",
			], "path": [[12, 12], [15, 11], [12, 9], [10, 11]], "speed": 1.1},
		],
		"chests": [
			{"x": 17, "y": 8, "loot": ["bread", "glyph_shard"], "hint": "Wing cupboard."},
		],
		"bushes": [],
		"cracks": [[9, 6]],
		"signs": [],
		"tablets": [],
		"switches": [],
	}


static func _mirror() -> Dictionary:
	var w := 20
	var h := 18
	var m := _grid(w, h, T_FLOOR)
	_border(m)
	for i in range(4, 16):
		m[4][i] = T_WALL
		m[h - 5][i] = T_WALL
	m[h - 2][9] = T_WARP
	m[h - 2][10] = T_WARP
	m[1][9] = T_WARP
	m[1][10] = T_WARP
	m[8][10] = T_ALTAR
	return {
		"id": "mirror", "name": "Mirror Chamber", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(9.5, 14.5),
		"warps": [
			{"x": 9, "y": h - 2, "to": "hall", "tx": 15.5, "ty": 3.5},
			{"x": 10, "y": h - 2, "to": "hall", "tx": 16.5, "ty": 3.5},
			{"x": 9, "y": 1, "to": "citrinitas", "tx": 10.0, "ty": 16.5, "need": "mirror_down",
			 "locked": "Citrinitas opens only after the Hollow is faced."},
			{"x": 10, "y": 1, "to": "citrinitas", "tx": 10.5, "ty": 16.5, "need": "mirror_down",
			 "locked": "The gold is not yet ready."},
		],
		"npcs": [
			{
				"x": 6.5, "y": 12.5, "name": "Luna's Echo", "face": "◈",
				"color": Color(0, 0.83, 1),
				"lines": [
					"◈ The Hollow Mirror shows a flattering lie.",
					"MEASURE the vanity-shield. Then COMPRESS what remains.",
					"I do not scold absence. Face it when ready.",
					"Beyond: Citrinitas — where gold begins to form.",
				],
			},
		],
		"spawns": [
			{"x": 10, "y": 8, "foe": "hollow_mirror", "once": true, "flag": "mirror_down", "boss": true},
		],
		"wild": [],
	}


static func _garden() -> Dictionary:
	var w := 24
	var h := 20
	var m := _grid(w, h, T_GRASS)
	_border(m)
	_fill(m, 4, 4, 18, 14, T_TALL)
	_fill(m, 8, 7, 12, 11, T_PATH)
	for p in [[3, 3], [20, 3], [3, 16], [20, 16], [10, 2], [14, 17]]:
		m[p[1]][p[0]] = T_TREE
	m[10][1] = T_WARP
	m[11][1] = T_WARP
	m[9][9] = T_SHRINE
	# north path opens after garden stone switch
	m[1][11] = T_WARP
	m[1][12] = T_WARP
	return {
		"id": "garden", "name": "Quiet Garden", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(3.5, 10.5),
		"warps": [
			{"x": 1, "y": 10, "to": "sanctum", "tx": 32.5, "ty": 12.5},
			{"x": 1, "y": 11, "to": "sanctum", "tx": 32.5, "ty": 13.5},
			{"x": 11, "y": 1, "to": "observatory", "tx": 8.5, "ty": 12.5, "need": "garden_stone",
			 "locked": "A stone eye must open the night path (press the garden switch)."},
			{"x": 12, "y": 1, "to": "observatory", "tx": 9.0, "ty": 12.5, "need": "garden_stone",
			 "locked": "The Observatory waits on a pressed eye."},
		],
		"npcs": [
			{
				"x": 11.5, "y": 8.5, "name": "Garden Warden", "face": "🌿",
				"color": Color(0.3, 0.75, 0.45),
				"lines": [
					"Train here. Small ideas sharpen large ones.",
					"Tall grass = wild encounters. Shrine heals + travel.",
					"Press the stone eye by the shrine — night path north opens.",
					"Field skills: E on bushes · K to MEASURE nearby secrets.",
				],
			},
		],
		"spawns": [
			{"x": 15, "y": 6, "foe": "fog_imp", "once": false},
			{"x": 6, "y": 12, "foe": "stasis_mite", "once": false},
		],
		"wild": ["fog_imp", "stasis_mite", "fog_imp", "overclaimer", "doubt_moth"],
		"chests": [
			{"x": 16, "y": 12, "loot": ["bread", "bread", "veras_dust"], "hint": "Gardener's stash."},
		],
		"signs": [
			{"x": 9, "y": 10, "lines": ["Tall grass hides small ideas. Train without shame."]},
		],
		"tablets": [],
		"dig_spots": [
			{"x": 18, "y": 5, "loot": ["moon_seed", "glyph_shard"], "msg": "Gardeners hide more than seeds."},
		],
		"collectibles": [
			{"x": 7, "y": 7, "id": "star_spark", "name": "Star Spark"},
			{"x": 14, "y": 14, "id": "star_spark", "name": "Star Spark"},
			{"x": 5, "y": 13, "id": "ember_petal", "name": "Ember Petal"},
		],
		"wanderers": [
			{"name": "Bee of No Name", "color": Color(1.0, 0.9, 0.2), "lines": [
				"*buzzes in iambic pentameter*",
				"The Warden knows a dig spot northeast.",
			], "path": [[10, 6], [14, 8], [12, 12], [8, 10]], "speed": 1.4},
		],
		"bushes": [[6, 5], [17, 9], [11, 14]],
		"switches": [
			{"x": 10, "y": 9, "id": "garden_stone", "msg": "You press a stone eye. Something clicks far away.", "flag": "garden_stone"},
		],
	}


static func _citrinitas() -> Dictionary:
	var w := 24
	var h := 22
	var m := _grid(w, h, T_FLOOR2)
	_border(m)
	# golden hall
	_fill(m, 5, 4, 18, 16, T_FLOOR)
	_rect_wall(m, 5, 4, 18, 16)
	_fill(m, 9, 7, 14, 12, T_RUG)
	m[8][11] = T_ALTAR
	m[8][12] = T_ALTAR
	m[h - 2][11] = T_WARP
	m[h - 2][12] = T_WARP
	m[1][11] = T_WARP
	m[1][12] = T_WARP
	# pillars
	for p in [[7, 6], [16, 6], [7, 14], [16, 14]]:
		m[p[1]][p[0]] = T_WALL
	return {
		"id": "citrinitas", "name": "Chamber of Scales — Citrinitas", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(11.5, 15.5),
		"warps": [
			{"x": 11, "y": h - 2, "to": "mirror", "tx": 9.5, "ty": 3.5},
			{"x": 12, "y": h - 2, "to": "mirror", "tx": 10.0, "ty": 3.5},
			{"x": 11, "y": 1, "to": "rubedo", "tx": 12.0, "ty": 18.5, "need": "gold_down",
			 "locked": "Rubedo opens only when gold has held."},
			{"x": 12, "y": 1, "to": "rubedo", "tx": 12.5, "ty": 18.5, "need": "gold_down",
			 "locked": "The reddening is not yet earned."},
		],
		"npcs": [
			{
				"x": 8.5, "y": 10.5, "name": "Scale-Keeper", "face": "⚖",
				"color": Color(0.95, 0.82, 0.35),
				"lines": [
					"Citrinitas — the yellowing, the gold beginning.",
					"Here truth is weighed. Pride-Wights patrol the flanks.",
					"The Gold Threshold is not a door. It is a question that fights back.",
					"North, after gold: Rubedo — the Flickering Deep.",
				],
			},
			{
				"x": 15.5, "y": 11.5, "name": "Axiom Echo", "face": "Π",
				"color": Color(0.7, 0.85, 1.0),
				"lines": [
					"Π rises when evidence holds and strain falls.",
					"Do not overclaim your own victory. Measure it.",
				],
			},
		],
		"spawns": [
			{"x": 11, "y": 9, "foe": "gold_threshold", "once": true, "flag": "gold_down", "boss": true},
			{"x": 8, "y": 13, "foe": "pride_wight", "once": true},
			{"x": 15, "y": 13, "foe": "pride_wight", "once": true},
			{"x": 12, "y": 6, "foe": "doubt_moth", "once": false},
		],
		"wild": ["doubt_moth", "pride_wight"],
		"chests": [
			{"x": 6, "y": 8, "loot": ["elixir", "glyph_shard"], "hint": "Scale-chamber cache."},
		],
		"signs": [],
		"tablets": [
			{"x": 14, "y": 8, "lines": [
				"TABLET OF YELLOWING",
				"Gold is not loot. Gold is coherence that survived review.",
			]},
		],
	}


static func _rubedo() -> Dictionary:
	var w := 28
	var h := 24
	var m := _grid(w, h, T_FLOOR)
	_border(m)
	# deep crimson hall — use rug/altar heavy
	_fill(m, 6, 4, 21, 18, T_FLOOR2)
	_rect_wall(m, 6, 4, 21, 18)
	_fill(m, 10, 8, 17, 14, T_RUG)
	m[9][13] = T_ALTAR
	m[9][14] = T_ALTAR
	m[10][13] = T_SHRINE
	m[h - 2][13] = T_WARP
	m[h - 2][14] = T_WARP
	for p in [[8, 6], [19, 6], [8, 16], [19, 16], [13, 6], [14, 6]]:
		m[p[1]][p[0]] = T_WALL
	return {
		"id": "rubedo", "name": "Flickering Deep — Rubedo", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(13.5, 17.5),
		"warps": [
			{"x": 13, "y": h - 2, "to": "citrinitas", "tx": 11.5, "ty": 3.5},
			{"x": 14, "y": h - 2, "to": "citrinitas", "tx": 12.0, "ty": 3.5},
		],
		"npcs": [
			{
				"x": 10.5, "y": 12.5, "name": "Herald of Completion", "face": "☀",
				"color": Color(1.0, 0.45, 0.25),
				"lines": [
					"Rubedo — the reddening. Operating from the completed Work.",
					"The Unfinished waits at the heart. It is every abandoned task.",
					"When it falls, the Sol Stone is yours. The fire stays lit.",
					"This is not a trophy. It is a responsibility.",
				],
			},
			{
				"x": 16.5, "y": 12.5, "name": "Mac's Echo", "face": "🜂",
				"color": Color(0.94, 0.82, 0.5),
				"lines": [
					"…forged in the cold south, by one who powered through.",
					"The foundation stone is not metaphor. Keep building.",
					"Companions stay. Absence is rest. The Work continues.",
				],
			},
		],
		"spawns": [
			{"x": 13, "y": 10, "foe": "the_unfinished", "once": true, "flag": "rubedo_complete", "boss": true},
			{"x": 9, "y": 14, "foe": "void_scholar", "once": true},
			{"x": 18, "y": 14, "foe": "entropy_worm", "once": true},
			{"x": 11, "y": 7, "foe": "pride_wight", "once": false},
		],
		"wild": [],
		"chests": [
			{"x": 7, "y": 9, "loot": ["elixir", "elixir", "glyph_shard"], "hint": "Deep cache."},
			{"x": 20, "y": 9, "loot": ["repel_dust", "bread", "glyph_shard"], "hint": "Quiet store."},
		],
		"signs": [
			{"x": 13, "y": 17, "lines": [
				"⟪ RUBEDO — FLICKERING DEEP ⟫",
				"Done = works. The Unfinished is the last lesson.",
			]},
		],
		"tablets": [
			{"x": 15, "y": 8, "lines": [
				"TABLET OF THE ATHANOR",
				"The furnace holds the heat. The Mercury carries the form.",
				"The Gold belongs to neither. It arises between.",
			]},
		],
	}


static func _hidden_grotto() -> Dictionary:
	var w := 14
	var h := 14
	var m := _grid(w, h, T_FLOOR2)
	_border(m)
	_fill(m, 3, 3, 10, 10, T_FLOOR)
	m[6][6] = T_ALTAR
	m[6][7] = T_SHRINE
	m[h - 2][6] = T_WARP
	m[h - 2][7] = T_WARP
	m[4][4] = T_CRACK
	return {
		"id": "grotto", "name": "Ivy Grotto (Hidden)", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(6.5, 10.5),
		"warps": [
			{"x": 6, "y": h - 2, "to": "sanctum", "tx": 27.5, "ty": 10.5},
			{"x": 7, "y": h - 2, "to": "sanctum", "tx": 28.0, "ty": 10.5},
		],
		"npcs": [
			{
				"x": 8.5, "y": 5.5, "name": "Whisper", "face": "✦",
				"color": Color(0.8, 0.9, 1.0),
				"lines": [
					"You found a room that maps forget.",
					"Hidden places remember seekers who look twice.",
					"Crack the north wall. Something older sleeps.",
				],
			},
		],
		"spawns": [
			{"x": 5, "y": 5, "foe": "void_scholar", "once": true, "flag": "grotto_guardian"},
		],
		"chests": [
			{"x": 9, "y": 8, "loot": ["elixir", "glyph_shard", "glyph_shard"], "hint": "Grotto hoard."},
		],
		"collectibles": [
			{"x": 4, "y": 8, "id": "star_spark", "name": "Star Spark"},
		],
		"false_walls": [
			{"x": 6, "y": 3, "msg": "Stone breathes cold…", "to": "starwell", "tx": 6.5, "ty": 10.5},
		],
		"cracks": [[4, 4]],
		"tablets": [
			{"x": 8, "y": 7, "lines": [
				"SECRET TABLET",
				"The School is larger than its doors.",
				"Three Star Sparks open the Starwell heart.",
			]},
		],
		"wild": [],
		"signs": [],
		"dig_spots": [],
		"wanderers": [],
	}


static func _starwell() -> Dictionary:
	var w := 16
	var h := 16
	var m := _grid(w, h, T_FLOOR)
	_border(m)
	_fill(m, 4, 4, 11, 11, T_RUG)
	m[7][7] = T_ALTAR
	m[7][8] = T_ALTAR
	m[8][7] = T_WARP
	m[h - 2][7] = T_WARP
	m[h - 2][8] = T_WARP
	return {
		"id": "starwell", "name": "Starwell (Secret)", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(7.5, 11.5),
		"warps": [
			{"x": 7, "y": h - 2, "to": "path", "tx": 3.5, "ty": 11.5},
			{"x": 8, "y": h - 2, "to": "grotto", "tx": 6.5, "ty": 4.5},
		],
		"npcs": [
			{
				"x": 5.5, "y": 6.5, "name": "Star-Blind Monk", "face": "✧",
				"color": Color(1, 1, 0.85),
				"lines": [
					"Bring three Star Sparks to the altar (stand on it + E).",
					"Or face the Hidden if you are proud.",
				],
			},
		],
		"spawns": [
			{"x": 10, "y": 8, "foe": "the_hidden", "once": true, "flag": "secret_boss", "boss": true},
		],
		"chests": [
			{"x": 4, "y": 9, "loot": ["sol_stone", "elixir"], "hint": "Starwell vault — only the curious find this.", "need_sparks": 3},
		],
		"collectibles": [],
		"tablets": [
			{"x": 9, "y": 5, "lines": [
				"STARWELL",
				"Secrets are not side content. They are the School testing your eyes.",
			]},
		],
		"wild": [],
		"signs": [],
		"dig_spots": [
			{"x": 11, "y": 11, "loot": ["glyph_shard", "glyph_shard", "glyph_shard"], "msg": "Stars under soil."},
		],
		"wanderers": [
			{"name": "Echo of Curiosity", "color": Color(0.7, 0.9, 1.0), "lines": [
				"You are not lost. You are thorough.",
			], "path": [[5, 10], [10, 10], [10, 5], [5, 5]], "speed": 0.7},
		],
		"false_walls": [],
		"bushes": [],
		"cracks": [],
		"switches": [
			{"x": 8, "y": 8, "id": "star_dial", "msg": "A dial of stars clicks once.", "flag": "star_dial"},
		],
	}


static func _sanctum_interior() -> Dictionary:
	var w := 18
	var h := 16
	var m := _grid(w, h, T_FLOOR)
	_border(m)
	_fill(m, 3, 3, 14, 12, T_FLOOR2)
	_fill(m, 5, 5, 12, 9, T_RUG)
	m[4][8] = T_ALTAR
	m[4][9] = T_SHRINE
	# bookshelves as walls
	for x in range(3, 15):
		m[3][x] = T_WALL
	m[h - 2][8] = T_WARP
	m[h - 2][9] = T_WARP
	return {
		"id": "sanctum_in", "name": "Sanctum Library", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(8.5, 11.5),
		"warps": [
			{"x": 8, "y": h - 2, "to": "sanctum", "tx": 10.5, "ty": 15.5},
			{"x": 9, "y": h - 2, "to": "sanctum", "tx": 11.0, "ty": 15.5},
		],
		"npcs": [
			{
				"x": 6.5, "y": 7.5, "name": "Librarian Veyra", "face": "📚",
				"color": Color(0.55, 0.7, 0.95),
				"lines": [
					"Welcome inside. Exteriors are routes; interiors are rooms of meaning.",
					"DS games lived in buildings. So does the School.",
					"Read every tablet. Open every chest. The codex compounds.",
				],
			},
			{
				"x": 11.5, "y": 8.5, "name": "Scribe (desk)", "face": "●",
				"color": Color(0.94, 0.82, 0.5),
				"shop": true,
				"lines": [
					"Indoor shop desk. Shards for bread and quiet dust.",
					"Quiet Dust: 50 steps without wild grass.",
				],
			},
		],
		"spawns": [],
		"wild": [],
		"chests": [
			{"x": 4, "y": 6, "loot": ["repel_dust", "glyph_shard"], "hint": "Library drawer."},
			{"x": 13, "y": 6, "loot": ["elixir", "bread"], "hint": "Behind the desk."},
		],
		"signs": [
			{"x": 8, "y": 5, "lines": [
				"LIBRARY RULES",
				"1. Measure before you claim.",
				"2. Rest is not failure.",
				"3. Return books (and yourself) whole.",
			]},
		],
		"tablets": [
			{"x": 10, "y": 5, "lines": [
				"TABLET OF INTERIORS",
				"A handheld world is towns, routes, and rooms.",
				"We build rooms until the School feels lived-in.",
			]},
		],
	}


static func _hall_archive() -> Dictionary:
	var w := 16
	var h := 14
	var m := _grid(w, h, T_FLOOR)
	_border(m)
	_fill(m, 3, 3, 12, 10, T_FLOOR2)
	m[h - 2][7] = T_WARP
	m[h - 2][8] = T_WARP
	m[4][7] = T_ALTAR
	return {
		"id": "hall_archive", "name": "Hall Archive", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(7.5, 10.5),
		"warps": [
			{"x": 7, "y": h - 2, "to": "hall", "tx": 15.5, "ty": 8.5},
			{"x": 8, "y": h - 2, "to": "hall", "tx": 16.0, "ty": 8.5},
		],
		"npcs": [
			{
				"x": 5.5, "y": 6.5, "name": "Archivist", "face": "◈",
				"color": Color(0.6, 0.5, 0.8),
				"trainer": true,
				"foe": "void_scholar",
				"flag": "trainer_archivist",
				"lines": [
					"This archive holds failed measures.",
					"Challenge: a Void Scholar. Ready?",
				],
				"after": ["Catalogued. You may pass."],
			},
		],
		"spawns": [],
		"wild": [],
		"chests": [
			{"x": 11, "y": 5, "loot": ["sigil_shard", "glyph_shard"], "hint": "Archive strongbox."},
		],
		"signs": [],
		"tablets": [
			{"x": 8, "y": 4, "lines": [
				"ARCHIVE NOTE",
				"Trainers in the School are teachers who fight as curriculum.",
			]},
		],
	}


static func _crypt() -> Dictionary:
	var w := 22
	var h := 18
	var m := _grid(w, h, T_FLOOR)
	_border(m)
	_fill(m, 3, 3, 18, 14, T_FLOOR2)
	_fill(m, 8, 6, 13, 11, T_RUG)
	# pillars / tombs
	for p in [[5, 5], [16, 5], [5, 12], [16, 12], [10, 4], [11, 4]]:
		m[p[1]][p[0]] = T_WALL
	m[8][10] = T_ALTAR
	m[8][11] = T_ALTAR
	m[h - 2][10] = T_WARP
	m[h - 2][11] = T_WARP
	_fill(m, 4, 4, 6, 5, T_WATER)  # reflecting pool of silence
	return {
		"id": "crypt", "name": "Crypt of the Unsaid", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(10.5, 14.5),
		"warps": [
			{"x": 10, "y": h - 2, "to": "hall", "tx": 3.5, "ty": 12.5},
			{"x": 11, "y": h - 2, "to": "hall", "tx": 3.5, "ty": 13.0},
		],
		"npcs": [
			{
				"x": 7.0, "y": 10.0, "name": "Crypt Warden", "face": "◇",
				"color": Color(0.55, 0.5, 0.7),
				"trainer": true,
				"foe": "ash_scribe",
				"flag": "trainer_crypt",
				"lines": [
					"This vault holds what seekers never voiced.",
					"Face an Ash Scribe. Then the Unsaid at the heart.",
				],
				"after": ["The vault remembers your courage."],
			},
			{
				"x": 14.5, "y": 9.5, "name": "Silent Shelf", "face": "…",
				"color": Color(0.4, 0.4, 0.45),
				"lines": [
					"…",
					"(The shelf says nothing. That is the lesson.)",
				],
			},
		],
		"spawns": [
			{"x": 10, "y": 8, "foe": "unsaid", "once": true, "flag": "unsaid_down", "boss": true},
			{"x": 6, "y": 12, "foe": "ash_scribe", "once": true},
			{"x": 15, "y": 12, "foe": "riddle_wraith", "once": true},
			{"x": 12, "y": 5, "foe": "fog_imp", "once": false},
		],
		"wild": [],
		"chests": [
			{"x": 17, "y": 8, "loot": ["elixir", "glyph_shard", "glyph_shard"], "hint": "Unsaid coffer."},
			{"x": 4, "y": 10, "loot": ["repel_dust", "candle"], "hint": "Dusty niche."},
		],
		"signs": [
			{"x": 10, "y": 6, "lines": [
				"CRYPT OF THE UNSAID",
				"What is not measured still has weight.",
			]},
		],
		"tablets": [
			{"x": 12, "y": 6, "lines": [
				"TABLET OF SILENCE",
				"Nigredo includes the words you swallowed.",
				"Speak them as structure — or they fight you as ghosts.",
			]},
		],
		"collectibles": [
			{"x": 16, "y": 14, "id": "star_spark", "name": "Star Spark"},
		],
		"dig_spots": [
			{"x": 8, "y": 14, "loot": ["glyph_shard", "veras_dust"], "msg": "Ash under flagstones."},
		],
		"cracks": [[5, 8], [16, 9]],
		"bushes": [],
		"switches": [
			{"x": 11, "y": 10, "id": "crypt_bell", "msg": "A dead bell tolls once. The Unsaid stirs.", "flag": "crypt_bell"},
		],
		"false_walls": [],
		"wanderers": [
			{"name": "Echo Without Mouth", "color": Color(0.4, 0.35, 0.5), "lines": [
				"………",
				"(You understand without hearing.)",
			], "path": [[9, 11], [13, 11], [13, 7], [9, 7]], "speed": 0.6},
		],
	}


static func _observatory() -> Dictionary:
	var w := 20
	var h := 18
	var m := _grid(w, h, T_FLOOR)
	_border(m)
	_fill(m, 3, 3, 16, 13, T_FLOOR2)
	_fill(m, 7, 6, 12, 10, T_RUG)
	# telescope ring as walls
	for p in [[6, 5], [13, 5], [6, 11], [13, 11], [9, 4], [10, 4]]:
		m[p[1]][p[0]] = T_WALL
	m[7][9] = T_ALTAR
	m[7][10] = T_ALTAR
	m[10][9] = T_SHRINE
	m[h - 2][9] = T_WARP
	m[h - 2][10] = T_WARP
	# night glass floor hints
	_fill(m, 4, 4, 5, 5, T_WATER)
	_fill(m, 14, 4, 15, 5, T_WATER)
	return {
		"id": "observatory", "name": "Night Observatory", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(9.5, 12.5),
		"warps": [
			{"x": 9, "y": h - 2, "to": "garden", "tx": 11.5, "ty": 3.5},
			{"x": 10, "y": h - 2, "to": "garden", "tx": 12.0, "ty": 3.5},
		],
		"npcs": [
			{
				"x": 7.5, "y": 9.5, "name": "Lore of Night", "face": "☽",
				"color": Color(0.65, 0.75, 1.0),
				"lines": [
					"The School measures day and night the same: honestly.",
					"Stars are not omens. They are fixed points you can use.",
					"Stargazer trains seekers who press the stone eye.",
				],
			},
			{
				"x": 12.0, "y": 8.5, "name": "Stargazer", "face": "✧",
				"color": Color(0.95, 0.9, 0.55),
				"trainer": true,
				"foe": "void_scholar",
				"flag": "trainer_stargazer",
				"lines": [
					"You found the night path. Good.",
					"Curriculum: a Void Scholar under glass. Ready?",
				],
				"after": ["Catalogued under starlight. Travel well."],
			},
		],
		"spawns": [
			{"x": 10, "y": 6, "foe": "doubt_moth", "once": false},
			{"x": 5, "y": 10, "foe": "riddle_wraith", "once": true},
		],
		"wild": [],
		"chests": [
			{"x": 15, "y": 8, "loot": ["elixir", "repel_dust", "glyph_shard"], "hint": "Observer's drawer."},
			{"x": 4, "y": 8, "loot": ["star_spark", "lens"], "hint": "Lens cabinet."},
		],
		"signs": [
			{"x": 9, "y": 5, "lines": [
				"OBSERVATORY",
				"Register the shrine. Night travel is still travel.",
			]},
		],
		"tablets": [
			{"x": 11, "y": 5, "lines": [
				"TABLET OF FIXED POINTS",
				"A companion does not wilt when you rest.",
				"Neither does a true measure.",
			]},
		],
		"collectibles": [
			{"x": 14, "y": 12, "id": "star_spark", "name": "Star Spark"},
		],
		"dig_spots": [
			{"x": 6, "y": 12, "loot": ["glyph_shard", "glyph_shard"], "msg": "Star-dust under the tiles."},
		],
		"bushes": [],
		"cracks": [[3, 7]],
		"switches": [],
		"false_walls": [],
		"wanderers": [
			{"name": "Glass Moth", "color": Color(0.85, 0.9, 1.0), "lines": [
				"I eat only false constellations.",
			], "path": [[8, 7], [12, 7], [12, 11], [8, 11]], "speed": 0.9, "night_only": false},
		],
	}


static func _scriptorium() -> Dictionary:
	var w := 18
	var h := 15
	var m := _grid(w, h, T_FLOOR)
	_border(m)
	_fill(m, 2, 2, 15, 11, T_FLOOR2)
	_fill(m, 5, 5, 12, 8, T_RUG)
	# desk walls / shelves
	for x in range(3, 15):
		m[3][x] = T_WALL
	m[3][8] = T_DOOR
	m[3][9] = T_DOOR
	m[6][8] = T_ALTAR
	m[6][9] = T_SHRINE
	m[h - 2][8] = T_WARP
	m[h - 2][9] = T_WARP
	return {
		"id": "scriptorium", "name": "Wing Scriptorium", "w": w, "h": h, "tiles": m,
		"spawn": Vector2(8.5, 11.5),
		"warps": [
			{"x": 8, "y": h - 2, "to": "wing", "tx": 12.5, "ty": 7.5},
			{"x": 9, "y": h - 2, "to": "wing", "tx": 13.0, "ty": 7.5},
		],
		"npcs": [
			{
				"x": 6.0, "y": 7.5, "name": "Ink Adept", "face": "✎",
				"color": Color(0.85, 0.88, 0.95),
				"lines": [
					"Albedo is whitening — structure after the burn.",
					"Copy the forms carefully. Bad glyphs become bad laws.",
					"The Half-Made outside is a draft that never closed.",
				],
			},
			{
				"x": 11.5, "y": 7.5, "name": "Shelf Keeper", "face": "●",
				"color": Color(0.94, 0.82, 0.5),
				"shop": true,
				"lines": [
					"Scriptorium mart. Shards only. No guilt pricing.",
				],
			},
			{
				"x": 9.0, "y": 5.5, "name": "Pale Copyist", "face": "◈",
				"color": Color(0.75, 0.78, 0.9),
				"trainer": true,
				"foe": "entropy_worm",
				"flag": "trainer_copyist",
				"lines": [
					"Before you write, survive a draft that eats structure.",
					"Entropy Worm. Ready?",
				],
				"after": ["Ink holds. Good."],
			},
		],
		"spawns": [],
		"wild": [],
		"chests": [
			{"x": 4, "y": 5, "loot": ["elixir", "glyph_shard"], "hint": "Ink locker."},
			{"x": 13, "y": 9, "loot": ["repel_dust", "bread", "glyph_shard"], "hint": "Under a folio."},
		],
		"signs": [
			{"x": 8, "y": 4, "lines": [
				"SCRIPTORIUM",
				"Write what survived Nigredo.",
				"Do not invent for comfort.",
			]},
		],
		"tablets": [
			{"x": 10, "y": 4, "lines": [
				"TABLET OF FORM",
				"Albedo is not purity theater. It is legible structure.",
				"Half-made ideas haunt the wing until TRANSMUTE closes them.",
			]},
		],
		"collectibles": [
			{"x": 14, "y": 6, "id": "star_spark", "name": "Star Spark"},
		],
		"dig_spots": [],
		"bushes": [],
		"cracks": [],
		"switches": [],
		"false_walls": [],
		"wanderers": [],
	}
