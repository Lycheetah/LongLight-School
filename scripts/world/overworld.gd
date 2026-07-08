extends Node2D
## Tile overworld — draw maps, player, NPCs, warps, encounters.

const TILE := 32
const PixelArtUtil = preload("res://scripts/util/pixel_art.gd")
const UIChromeUtil = preload("res://scripts/ui/ui_chrome.gd")

@onready var map_draw: Node2D = $MapDraw
@onready var entities: Node2D = $Entities
@onready var player: CharacterBody2D = $Entities/Player
@onready var companion: Node2D = $Entities/Companion
@onready var camera: Camera2D = $Entities/Player/Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var dialogue_ui: Control = $HUD/Dialogue
@onready var toast_label: Label = $HUD/Toast
@onready var hp_label: Label = $HUD/TopBar/HPLabel
@onready var area_label: Label = $HUD/TopBar/AreaLabel
@onready var companion_label: Label = $HUD/BottomBar/CompanionLine
@onready var menu_panel: Control = $HUD/MenuPanel
@onready var battle_layer: CanvasLayer = $BattleLayer

var area: Dictionary = {}
var tiles: Array = []
var area_w: int = 0
var area_h: int = 0
var npcs: Array = []
var warps: Array = []
var spawns: Array = []
var chests: Array = []
var signs: Array = []
var tablets: Array = []
var false_walls: Array = []
var dig_spots: Array = []
var collectibles: Array = []
var switches: Array = []
var wanderers: Array = []  # runtime positions
var spawn_dead: Dictionary = {}  # key "x,y" -> true if once-defeated
var _ambient: Array = []  # fireflies etc
var _secret_toast_cd: float = 0.0
var steps: int = 0
var dialogue_lines: Array = []
var dialogue_i: int = 0
var dialogue_speaker: String = ""
var toast_t: float = 0.0
var menu_open: bool = false
var colors: Dictionary = {}

var _comp_sheet: ImageTexture
var _comp_anim: float = 0.0
var _quest_label: Label
var _phase_label: Label
var _minimap: Control
var _encounter_fx: CanvasLayer
var _pending_battle: Dictionary = {}
var _shop_mode: bool = false
var _location_splash: CanvasLayer
var _pending_trainer: Dictionary = {}


func _ready() -> void:
	colors = AreaData.colors()
	GameState.toast.connect(_on_toast)
	GameState.hp_changed.connect(_refresh_hud)
	GameState.battle_requested.connect(_on_battle_req)
	GameState.quest_updated.connect(_refresh_hud)
	dialogue_ui.visible = false
	menu_panel.visible = false
	battle_layer.visible = false
	_style_ui()
	_build_extra_hud()
	_setup_encounter_fx()
	_setup_location_splash()
	_setup_companion()
	if player.has_method("_paint_sprite"):
		player._paint_sprite()
	if camera:
		camera.zoom = Vector2(2.15, 2.15)
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 12.0
	load_area(GameState.area_id, GameState.pos)
	_refresh_hud()


func _build_extra_hud() -> void:
	# Always-on quest tip (DS-style objective strip)
	_quest_label = Label.new()
	_quest_label.name = "QuestTip"
	_quest_label.position = Vector2(12, 40)
	_quest_label.size = Vector2(700, 24)
	_quest_label.add_theme_font_size_override("font_size", 13)
	_quest_label.add_theme_color_override("font_color", Color("f0d080"))
	_quest_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	_quest_label.add_theme_constant_override("shadow_offset_x", 1)
	_quest_label.add_theme_constant_override("shadow_offset_y", 1)
	hud.add_child(_quest_label)
	_phase_label = Label.new()
	_phase_label.name = "Phase"
	_phase_label.position = Vector2(12, 60)
	_phase_label.size = Vector2(200, 20)
	_phase_label.add_theme_font_size_override("font_size", 12)
	_phase_label.add_theme_color_override("font_color", Color("8a80a8"))
	hud.add_child(_phase_label)
	# Mini-map (bottom-right)
	_minimap = Control.new()
	_minimap.name = "Minimap"
	_minimap.set_script(load("res://scripts/world/minimap.gd"))
	_minimap.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_minimap.offset_left = -148
	_minimap.offset_top = -172
	_minimap.offset_right = -12
	_minimap.offset_bottom = -52
	hud.add_child(_minimap)
	_minimap.world = self


func _setup_encounter_fx() -> void:
	var fx_script: Script = load("res://scripts/world/encounter_fx.gd")
	_encounter_fx = fx_script.new()
	_encounter_fx.layer = 30
	add_child(_encounter_fx)
	if _encounter_fx.has_signal("finished"):
		_encounter_fx.finished.connect(_on_encounter_fx_done)


func _setup_location_splash() -> void:
	var ls: Script = load("res://scripts/ui/location_splash.gd")
	_location_splash = ls.new()
	add_child(_location_splash)


func _style_ui() -> void:
	UIChromeUtil.style_panel(dialogue_ui)
	UIChromeUtil.style_panel(menu_panel)
	if has_node("HUD/Dialogue/Speaker"):
		UIChromeUtil.style_label_title($HUD/Dialogue/Speaker)
	if has_node("HUD/Dialogue/Body"):
		UIChromeUtil.style_label_body($HUD/Dialogue/Body)
	if has_node("HUD/MenuPanel/Title"):
		UIChromeUtil.style_label_title($HUD/MenuPanel/Title)
	if has_node("HUD/MenuPanel/Body"):
		UIChromeUtil.style_label_body($HUD/MenuPanel/Body)
	# top bar strip
	if has_node("HUD/TopBar"):
		$HUD/TopBar.color = Color("120c20e6")
	if has_node("HUD/BottomBar"):
		$HUD/BottomBar.color = Color("120c20e6")


func _setup_companion() -> void:
	var cs := companion.get_node_or_null("CompSprite") as Sprite2D
	if cs:
		_comp_sheet = PixelArtUtil.companion_sheet()
		cs.texture = _comp_sheet
		cs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cs.region_enabled = true
		cs.region_rect = Rect2(0, 0, 16, 16)
		cs.scale = Vector2(2, 2)
		cs.position = Vector2(0, -6)
		cs.centered = true


func load_area(id: String, at: Vector2 = Vector2.ZERO) -> void:
	var all := AreaData.all_areas()
	if not all.has(id):
		id = "sanctum"
	var prev := GameState.area_id
	area = all[id]
	tiles = area.tiles
	area_w = int(area.w)
	area_h = int(area.h)
	npcs = area.get("npcs", [])
	warps = area.get("warps", [])
	spawns = area.get("spawns", [])
	chests = area.get("chests", [])
	signs = area.get("signs", [])
	tablets = area.get("tablets", [])
	false_walls = area.get("false_walls", [])
	dig_spots = area.get("dig_spots", [])
	collectibles = area.get("collectibles", [])
	switches = area.get("switches", [])
	_init_wanderers(area.get("wanderers", []))
	_stamp_secret_tiles()
	_spawn_ambient()
	GameState.area_id = id
	if at != Vector2.ZERO:
		player.global_position = at
	else:
		var sp: Vector2 = area.get("spawn", Vector2(10, 10))
		player.global_position = Vector2(sp.x * TILE, sp.y * TILE)
	GameState.pos = player.global_position
	companion.global_position = player.global_position + Vector2(0, 24)
	map_draw.queue_redraw()
	_refresh_hud()
	GameState.area_changed.emit(id)
	if prev != id:
		SFX.warp()
		if _location_splash and _location_splash.has_method("show_location"):
			_location_splash.show_location(str(area.get("name", id)))
	GameState.toast.emit(str(area.get("name", id)))
	# snap player to grid
	if player.has_method("_tile_center"):
		var t: Vector2i = player._tile_of(player.global_position)
		player.global_position = player._tile_center(t)
	var intro_key := "intro_%s" % id
	if not GameState.has_flag(intro_key) and ContentDB.AREA_NAMES.has(id):
		GameState.set_flag(intro_key, true)
		GameState.companion_line = ContentDB.COMPANION_LINES[randi() % ContentDB.COMPANION_LINES.size()]


func _stamp_secret_tiles() -> void:
	for d in dig_spots:
		var x := int(d.x)
		var y := int(d.y)
		if y >= 0 and y < tiles.size() and x >= 0 and x < tiles[0].size():
			if not GameState.has_flag("dig:%s:%d:%d" % [GameState.area_id, x, y]):
				tiles[y][x] = AreaData.T_DIG
	for c in area.get("cracks", []):
		var x2 := int(c[0]) if typeof(c) == TYPE_ARRAY else int(c.x)
		var y2 := int(c[1]) if typeof(c) == TYPE_ARRAY else int(c.y)
		if y2 >= 0 and y2 < tiles.size() and x2 >= 0 and x2 < tiles[0].size():
			tiles[y2][x2] = AreaData.T_CRACK
	for b in area.get("bushes", []):
		var bx := int(b[0])
		var by := int(b[1])
		if by >= 0 and by < tiles.size() and bx >= 0 and bx < tiles[0].size():
			if tiles[by][bx] in [AreaData.T_GRASS, AreaData.T_PATH, AreaData.T_FLOOR]:
				tiles[by][bx] = AreaData.T_BUSH
	for col in collectibles:
		var cx := int(col.x)
		var cy := int(col.y)
		var ck := "col:%s:%d:%d" % [GameState.area_id, cx, cy]
		if ck in GameState.collectibles:
			continue
		if cy >= 0 and cy < tiles.size() and cx >= 0 and cx < tiles[0].size():
			tiles[cy][cx] = AreaData.T_FLOWER


func _init_wanderers(defs: Array) -> void:
	wanderers = []
	for w in defs:
		if bool(w.get("night_only", false)):
			var ph := Atmosphere.phase_name()
			if ph in ["day", "dawn", "golden"]:
				continue
		var path: Array = w.get("path", [[5, 5]])
		var p0: Array = path[0]
		wanderers.append({
			"name": w.get("name", "Wanderer"),
			"color": w.get("color", Color.WHITE),
			"lines": w.get("lines", ["…"]),
			"path": path,
			"pi": 0,
			"x": float(p0[0]) + 0.5,
			"y": float(p0[1]) + 0.5,
			"speed": float(w.get("speed", 0.9)),
			"wait": 0.0,
		})


func _spawn_ambient() -> void:
	_ambient = []
	var n := 12 if GameState.area_id in ["garden", "sanctum", "path"] else 6
	if Atmosphere.phase_name() in ["night", "late_night", "dusk"]:
		n += 8
	for i in n:
		_ambient.append({
			"x": randf() * area_w * TILE,
			"y": randf() * area_h * TILE,
			"vx": randf_range(-12, 12),
			"vy": randf_range(-8, 8),
			"phase": randf() * TAU,
			"kind": "firefly" if Atmosphere.phase_name() in ["night", "dusk", "late_night"] else "mote",
		})


func _process(delta: float) -> void:
	if toast_t > 0:
		toast_t -= delta
		if toast_t <= 0:
			toast_label.visible = false
	_comp_anim += delta * 4.0
	var cs := companion.get_node_or_null("CompSprite") as Sprite2D
	if cs and _comp_sheet:
		var fr := int(_comp_anim) % 2
		cs.region_rect = Rect2(fr * 16, 0, 16, 16)
	if _phase_label:
		_phase_label.text = "⊙ %s" % Atmosphere.phase_name().capitalize()
	if _minimap:
		_minimap.queue_redraw()
	if not GameState.in_battle:
		SFX.ambient_tick(delta)
	_update_wanderers(delta)
	_update_ambient(delta)
	_secret_toast_cd = maxf(0.0, _secret_toast_cd - delta)
	if GameState.in_battle or menu_open or dialogue_ui.visible:
		return
	GameState.pos = player.global_position
	var target: Vector2 = player.global_position - player.facing * 22.0
	companion.global_position = companion.global_position.lerp(target, minf(1.0, 5.5 * delta))
	_check_tile_triggers()
	_check_collectible_step()
	_check_trainer_los()
	_random_world_event(delta)


func _update_wanderers(delta: float) -> void:
	for w in wanderers:
		if float(w.wait) > 0.0:
			w.wait = float(w.wait) - delta
			continue
		var path: Array = w.path
		if path.is_empty():
			continue
		var pi: int = int(w.pi) % path.size()
		var dest: Array = path[pi]
		var tx := float(dest[0]) + 0.5
		var ty := float(dest[1]) + 0.5
		var pos := Vector2(float(w.x), float(w.y))
		var goal := Vector2(tx, ty)
		var step: Vector2 = (goal - pos)
		if step.length() < 0.05:
			w.pi = (pi + 1) % path.size()
			w.wait = randf_range(0.4, 1.6)
			continue
		pos += step.normalized() * float(w.speed) * delta
		w.x = pos.x
		w.y = pos.y
	map_draw.queue_redraw()


func _update_ambient(delta: float) -> void:
	for a in _ambient:
		a.phase = float(a.phase) + delta * 2.0
		a.x = float(a.x) + float(a.vx) * delta
		a.y = float(a.y) + float(a.vy) * delta + sin(float(a.phase)) * 4.0 * delta
		if a.x < 0 or a.x > area_w * TILE:
			a.vx = -float(a.vx)
		if a.y < 0 or a.y > area_h * TILE:
			a.vy = -float(a.vy)


var _event_cd: float = 8.0


func _random_world_event(delta: float) -> void:
	_event_cd -= delta
	if _event_cd > 0.0 or not player.moved_this_frame:
		return
	_event_cd = randf_range(14.0, 28.0)
	if randf() > 0.22:
		return
	var rolls := [
		"A warm wind. Sol says nothing. That is enough.",
		"You smell old parchment and rain that never fell.",
		"Far off, a bell that isn't the Sanctum's.",
		"Footprints in dust that vanish as you look.",
		"Π ticks once in your chest — then quiet.",
	]
	if Atmosphere.phase_name() in ["night", "late_night"]:
		rolls.append("Stars lean closer over the School.")
		rolls.append("A firefly writes a glyph and forgets it.")
	GameState.toast.emit(rolls[randi() % rolls.size()])


func _check_trainer_los() -> void:
	# Pokémon-style: if you're in a straight line (row/col) within 5 tiles facing them
	if GameState.in_battle or not _pending_battle.is_empty():
		return
	var pt := Vector2i(int(player.global_position.x / TILE), int(player.global_position.y / TILE))
	for n in npcs:
		if not bool(n.get("trainer", false)):
			continue
		var tflag := str(n.get("flag", ""))
		if tflag != "" and GameState.has_flag(tflag):
			continue
		var nx := int(floor(float(n.x)))
		var ny := int(floor(float(n.y)))
		var same_row := ny == pt.y
		var same_col := nx == pt.x
		if not (same_row or same_col):
			continue
		var dist := absi(nx - pt.x) + absi(ny - pt.y)
		if dist < 1 or dist > 5:
			continue
		# clear line?
		var step := Vector2i(signi(nx - pt.x), signi(ny - pt.y))
		var ok := true
		var c := pt + step
		while c.x != nx or c.y != ny:
			if is_solid(c.x, c.y):
				ok = false
				break
			c += step
		if not ok:
			continue
		# eye contact: player facing trainer or always snag (classic feels aggressive — use always)
		GameState.toast.emit("%s spots you!" % str(n.name))
		SFX.encounter()
		_pending_trainer = n.duplicate()
		_open_dialogue(str(n.name), n.get("lines", ["Battle!"]))
		return


func _check_collectible_step() -> void:
	var tx := int(player.global_position.x / TILE)
	var ty := int(player.global_position.y / TILE)
	for col in collectibles:
		if int(col.x) == tx and int(col.y) == ty:
			var ck := "col:%s:%d:%d" % [GameState.area_id, tx, ty]
			if GameState.take_collectible(ck, str(col.id), str(col.get("name", col.id))):
				SFX.measure()
				tiles[ty][tx] = AreaData.T_GRASS if GameState.area_id in ["garden", "sanctum", "path"] else AreaData.T_FLOOR
				map_draw.queue_redraw()
			return


func _unhandled_input(event: InputEvent) -> void:
	if GameState.in_battle:
		return
	if event.is_action_pressed("menu"):
		if dialogue_ui.visible:
			return
		_toggle_menu()
		get_viewport().set_input_as_handled()
		return
	if menu_open:
		if event.is_action_pressed("interact"):
			_menu_confirm()
			get_viewport().set_input_as_handled()
		return
	if dialogue_ui.visible:
		if event.is_action_pressed("interact"):
			_advance_dialogue()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact"):
		_interact()
		get_viewport().set_input_as_handled()


func _check_tile_triggers() -> void:
	var tx := int(player.global_position.x / TILE)
	var ty := int(player.global_position.y / TILE)
	if tx < 0 or ty < 0 or tx >= area_w or ty >= area_h:
		return
	var t: int = tiles[ty][tx]
	# warps
	if t == AreaData.T_WARP:
		for w in warps:
			if int(w.x) == tx and int(w.y) == ty:
				_try_warp(w)
				return
	# fixed spawns
	for s in spawns:
		var key := "%d,%d" % [int(s.x), int(s.y)]
		if int(s.x) == tx and int(s.y) == ty:
			if bool(s.get("once", true)) and spawn_dead.get(key, false):
				continue
			if bool(s.get("once", true)) and s.has("flag") and GameState.has_flag(str(s.flag)):
				spawn_dead[key] = true
				continue
			_start_battle(str(s.foe), s)
			return
	# tall grass wild
	if t == AreaData.T_TALL and player.moved_this_frame:
		steps += 1
		# Quiet Dust repel
		var repel: int = int(GameState.flags.get("repel_steps", 0))
		if repel > 0:
			GameState.flags["repel_steps"] = repel - 1
			return
		if steps % 28 == 0:
			var wild: Array = area.get("wild", [])
			if wild.size() > 0:
				_start_battle(str(wild[randi() % wild.size()]), {})


func _try_warp(w: Dictionary) -> void:
	if w.has("need") and not GameState.has_flag(str(w.need)):
		GameState.toast.emit(str(w.get("locked", "Sealed.")))
		SFX.ui()
		player.global_position -= player.facing * 16.0
		return
	var dest := str(w.to)
	var tp := Vector2(float(w.tx) * TILE, float(w.ty) * TILE)
	load_area(dest, tp)


func _interact() -> void:
	var front: Vector2 = player.global_position + player.facing * 28.0
	var ftx := int(front.x / TILE)
	var fty := int(front.y / TILE)
	# wanderers
	for w in wanderers:
		var wp := Vector2(float(w.x) * TILE, float(w.y) * TILE)
		if wp.distance_to(front) < 36.0 or wp.distance_to(player.global_position) < 36.0:
			_open_dialogue(str(w.name), w.get("lines", ["…"]))
			return
	# false walls (secret doors)
	for fw in false_walls:
		if int(fw.x) == ftx and int(fw.y) == fty:
			GameState.secrets_found += 1
			SFX.warp()
			_open_dialogue("Secret", [
				str(fw.get("msg", "A hidden way opens.")),
				"You slip through.",
			])
			await get_tree().create_timer(0.35).timeout
			load_area(str(fw.to), Vector2(float(fw.tx) * TILE, float(fw.ty) * TILE))
			GameState.toast.emit("✧ Hidden path discovered!")
			return
	# dig spots
	for d in dig_spots:
		if int(d.x) == ftx and int(d.y) == fty:
			var dk := "dig:%s:%d:%d" % [GameState.area_id, int(d.x), int(d.y)]
			if GameState.has_flag(dk):
				GameState.toast.emit("Already dug.")
				return
			GameState.set_flag(dk, true)
			GameState.secrets_found += 1
			for it in d.get("loot", []):
				GameState.add_item(str(it))
			SFX.save_ok()
			tiles[int(d.y)][int(d.x)] = AreaData.T_PATH
			map_draw.queue_redraw()
			_open_dialogue("Dig", [str(d.get("msg", "You dig.")), "Loot secured."])
			return
	# switches
	for sw in switches:
		if int(sw.x) == ftx and int(sw.y) == fty:
			var sid := str(sw.get("id", "sw"))
			GameState.set_flag(str(sw.get("flag", sid)), true)
			SFX.ui()
			_open_dialogue("Switch", [str(sw.get("msg", "Click.")), "Something in the School shifted."])
			return
	# cracks — break open to path + sometimes loot
	if fty >= 0 and fty < tiles.size() and ftx >= 0 and ftx < tiles[0].size():
		if int(tiles[fty][ftx]) == AreaData.T_CRACK:
			tiles[fty][ftx] = AreaData.T_FLOOR
			GameState.secrets_found += 1
			GameState.add_item("glyph_shard", 1)
			SFX.hit()
			map_draw.queue_redraw()
			_open_dialogue("Crack", ["You BREAK the seam.", "A glyph shard falls from the wall."])
			return
		if int(tiles[fty][ftx]) == AreaData.T_BUSH:
			tiles[fty][ftx] = AreaData.T_GRASS
			if randf() < 0.35:
				GameState.add_item("veras_dust", 1)
				GameState.toast.emit("Rustle — Veras Dust!")
			else:
				GameState.toast.emit("Just a bush.")
			SFX.step()
			map_draw.queue_redraw()
			return
	# altar star spark offering (starwell)
	if fty >= 0 and fty < tiles.size() and ftx >= 0 and ftx < tiles[0].size():
		if int(tiles[fty][ftx]) == AreaData.T_ALTAR and GameState.area_id == "starwell":
			if GameState.count_item("star_spark") >= 3 and not GameState.has_flag("starwell_offering"):
				GameState.set_flag("starwell_offering", true)
				GameState.add_item("elixir", 2)
				GameState.add_item("glyph_shard", 5)
				GameState.secrets_found += 3
				SFX.level_up()
				_open_dialogue("Starwell", [
					"Three sparks sink into the altar.",
					"The well answers with light — and gifts.",
					"The Hidden may still challenge you if pride remains.",
				])
				return
			elif not GameState.has_flag("starwell_offering"):
				_open_dialogue("Starwell", [
					"The altar wants three Star Sparks (you have %d)." % GameState.count_item("star_spark"),
				])
				return
	# NPC / trainers
	for n in npcs:
		var np := Vector2(float(n.x) * TILE, float(n.y) * TILE)
		if np.distance_to(front) < 40.0 or np.distance_to(player.global_position) < 40.0:
			if bool(n.get("trainer", false)):
				_talk_trainer(n)
				return
			if n.has("flag") and not bool(n.get("trainer", false)):
				GameState.set_flag(str(n.flag), true)
			if bool(n.get("shop", false)):
				_open_shop(n)
				return
			_open_dialogue(str(n.name), n.lines)
			return
	# chests
	for c in chests:
		var ck := "%s:%d:%d" % [GameState.area_id, int(c.x), int(c.y)]
		var cp := Vector2(float(c.x) * TILE + 16, float(c.y) * TILE + 16)
		if cp.distance_to(front) < 40.0 or cp.distance_to(player.global_position) < 36.0:
			if GameState.chest_taken(ck):
				GameState.toast.emit("Empty coffer.")
				return
			if c.has("need_sparks") and GameState.count_item("star_spark") < int(c.need_sparks):
				_open_dialogue("Sealed Chest", [
					"It wants %d Star Sparks (you have %d)." % [int(c.need_sparks), GameState.count_item("star_spark")],
				])
				return
			var loot: Array = c.get("loot", ["glyph_shard"])
			if GameState.open_chest(ck, loot):
				SFX.save_ok()
				_open_dialogue("Chest", [str(c.get("hint", "A chest.")), "You take what the School left."])
				map_draw.queue_redraw()
			return
	# signs
	for s in signs:
		var sp := Vector2(float(s.x) * TILE + 16, float(s.y) * TILE + 16)
		if sp.distance_to(front) < 40.0 or (int(s.x) == ftx and int(s.y) == fty):
			_open_dialogue("Sign", s.get("lines", ["…"]))
			return
	# lore tablets
	for t in tablets:
		var tp := Vector2(float(t.x) * TILE + 16, float(t.y) * TILE + 16)
		if tp.distance_to(front) < 40.0:
			var tk := "tab:%s:%d:%d" % [GameState.area_id, int(t.x), int(t.y)]
			if not GameState.has_flag(tk):
				GameState.set_flag(tk, true)
				GameState.secrets_found += 1
				GameState.toast.emit("Lore secured. Secrets: %d" % GameState.secrets_found)
			SFX.measure()
			_open_dialogue("Tablet", t.get("lines", ["…"]))
			return
	# shrine underfoot / adjacent
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var tx := int(player.global_position.x / TILE) + dx
			var ty := int(player.global_position.y / TILE) + dy
			if tx < 0 or ty < 0 or tx >= area_w or ty >= area_h:
				continue
			if tiles[ty][tx] == AreaData.T_SHRINE:
				GameState.heal_full()
				SFX.heal()
				return
			if tiles[ty][tx] == AreaData.T_ALTAR:
				_open_dialogue("Altar", [
					"The altar hums with unspent Π.",
					"Kneeling here clarifies: rest is valid. Absence is not failure.",
				])
				return
	GameState.toast.emit("… nothing to touch.")


func _talk_trainer(n: Dictionary) -> void:
	var tflag := str(n.get("flag", ""))
	if tflag != "" and GameState.has_flag(tflag):
		_open_dialogue(str(n.name), n.get("after", ["…You already proved yourself."]))
		return
	_pending_trainer = n.duplicate()
	var lines: Array = n.get("lines", ["Battle!"]).duplicate()
	_open_dialogue(str(n.name), lines)
	# after dialogue ends, start battle — hook via advance


func _open_shop(n: Dictionary) -> void:
	_shop_mode = true
	var shards := int(GameState.inventory.get("glyph_shard", 0))
	var lines: Array = n.get("lines", []).duplicate()
	lines.append("— KEEPER'S SHELF — you have ⟡%d —" % shards)
	lines.append("E again while talking: buy Bread (2⟡) if you can afford it.")
	lines.append("Menu [1] use Bread · [2] use Elixir (5⟡ at shop via E×2).")
	if shards >= 2:
		GameState.inventory["glyph_shard"] = shards - 2
		if GameState.inventory["glyph_shard"] <= 0:
			GameState.inventory.erase("glyph_shard")
		GameState.add_item("bread", 1)
		SFX.ui()
		lines.append("✦ Traded 2 shards for Sanctum Bread.")
	else:
		lines.append("(Need 2 Glyph Shards. Defeat ideas. Return.)")
	if int(GameState.inventory.get("glyph_shard", 0)) >= 5:
		GameState.inventory["glyph_shard"] = int(GameState.inventory.get("glyph_shard", 0)) - 5
		GameState.add_item("elixir", 1)
		lines.append("✦ Also granted Elixir of Π for 5 shards.")
	_open_dialogue(str(n.name), lines)


func _open_dialogue(speaker: String, lines: Array) -> void:
	dialogue_speaker = speaker
	dialogue_lines = lines.duplicate()
	dialogue_i = 0
	dialogue_ui.visible = true
	player.can_move = false
	SFX.talk()
	_render_dialogue()


func _render_dialogue() -> void:
	$HUD/Dialogue/Speaker.text = dialogue_speaker
	if dialogue_i < dialogue_lines.size():
		$HUD/Dialogue/Body.text = str(dialogue_lines[dialogue_i])
	else:
		dialogue_ui.visible = false
		player.can_move = true


func _advance_dialogue() -> void:
	dialogue_i += 1
	if dialogue_i >= dialogue_lines.size():
		dialogue_ui.visible = false
		player.can_move = true
		# trainer challenge after dialogue
		if not _pending_trainer.is_empty():
			var n: Dictionary = _pending_trainer
			_pending_trainer = {}
			var tflag := str(n.get("flag", ""))
			if tflag == "" or not GameState.has_flag(tflag):
				var foe := str(n.get("foe", "fog_imp"))
				var meta := {"trainer": true, "flag": tflag, "boss": false, "once": true}
				_start_battle(foe, meta)
	else:
		_render_dialogue()


func _start_battle(foe_id: String, meta: Dictionary) -> void:
	if GameState.in_battle or not _pending_battle.is_empty():
		return
	player.can_move = false
	_pending_battle = {"foe": foe_id, "meta": meta}
	SFX.encounter()
	if _encounter_fx and _encounter_fx.has_method("play_and_wait"):
		_encounter_fx.play_and_wait()
	else:
		_on_encounter_fx_done()


func _on_encounter_fx_done() -> void:
	if _pending_battle.is_empty():
		return
	var foe_id: String = str(_pending_battle.get("foe", "fog_imp"))
	var meta: Dictionary = _pending_battle.get("meta", {})
	_pending_battle = {}
	GameState.in_battle = true
	Atmosphere.set_battle_mode(true)
	battle_layer.visible = true
	battle_layer.start_battle(foe_id, meta)


func _on_battle_req(foe_id: String, meta: Dictionary) -> void:
	_start_battle(foe_id, meta)


func on_battle_ended(won: bool, meta: Dictionary) -> void:
	GameState.in_battle = false
	Atmosphere.set_battle_mode(false)
	battle_layer.visible = false
	player.can_move = true
	if bool(meta.get("fled", false)):
		_refresh_hud()
		return
	if won:
		SFX.win()
		var key := "%d,%d" % [int(meta.get("x", -1)), int(meta.get("y", -1))]
		if meta.get("once", true) and int(meta.get("x", -1)) >= 0:
			spawn_dead[key] = true
		if meta.has("flag") and str(meta.flag) != "":
			GameState.set_flag(str(meta.flag), true)
		if bool(meta.get("trainer", false)):
			GameState.toast.emit("Trainer defeated. Curriculum advanced.")
			GameState.add_xp(15)
		if GameState.area_id == "hall":
			GameState.record_hall_win()
		if GameState.area_id == "garden":
			GameState.set_flag("garden_trained", true)
		if GameState.has_flag("rubedo_complete"):
			_trigger_ending()
		elif GameState.has_flag("gold_down"):
			GameState.toast.emit("Gold holds. North of Citrinitas: Rubedo.")
		elif GameState.has_flag("mirror_down"):
			GameState.toast.emit("Hollow faced. North of the Mirror: Citrinitas.")
		GameState.companion_line = ContentDB.COMPANION_LINES[randi() % ContentDB.COMPANION_LINES.size()]
		_refresh_hud()
		map_draw.queue_redraw()
	else:
		SFX.lose()
		GameState.hp = GameState.max_hp
		load_area("sanctum", Vector2(11.5 * TILE, 20.5 * TILE))
		GameState.toast.emit("You wake at the Sanctum shrine.")


func _trigger_ending() -> void:
	player.can_move = false
	var end := CanvasLayer.new()
	end.layer = 50
	end.name = "Ending"
	add_child(end)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("0a0812")
	end.add_child(bg)
	var lab := Label.new()
	lab.set_anchors_preset(Control.PRESET_FULL_RECT)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.add_theme_font_size_override("font_size", 20)
	lab.add_theme_color_override("font_color", Color("f0d080"))
	lab.text = "\n".join(ContentDB.ENDING_LINES)
	end.add_child(lab)
	SFX.win()
	SFX.level_up()
	# wait for Enter
	await get_tree().create_timer(0.5).timeout
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("menu"):
			break
	GameState.save_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _toggle_menu() -> void:
	menu_open = not menu_open
	menu_panel.visible = menu_open
	player.can_move = not menu_open and not dialogue_ui.visible
	SFX.ui()
	if menu_open:
		_fill_menu()


func _fill_menu() -> void:
	var body: Label = $HUD/MenuPanel/Body
	var qlines: PackedStringArray = []
	qlines.append("— QUESTS —")
	for qid in ContentDB.QUESTS.keys():
		var q: Dictionary = ContentDB.QUESTS[qid]
		var mark := "✓" if (qid in GameState.quests_done or GameState.has_flag(str(q.flag))) else "○"
		qlines.append("%s %s" % [mark, q.title])
		if mark == "○":
			for step in q.get("steps", []):
				qlines.append("    · %s" % str(step))
	qlines.append("")
	qlines.append("— PARTY —")
	qlines.append("%s  Lv%d  %s" % [GameState.player_name, GameState.level, GameState.archetype])
	qlines.append("WILL %d/%d  INS %d  WIL %d  LCK %d" % [
		GameState.hp, GameState.max_hp,
		GameState.insight + GameState._relic_insight(),
		GameState.will_stat + GameState._relic_will(),
		GameState.luck
	])
	qlines.append("XP %d / %d   Hall wins: %d/3" % [GameState.xp, GameState.xp_next, GameState.hall_wins])
	qlines.append("")
	qlines.append("— INVENTORY —")
	if GameState.inventory.is_empty() and GameState.relics.is_empty():
		qlines.append("(empty)")
	for k in GameState.inventory.keys():
		var nm: String = str(ContentDB.ITEMS.get(k, {}).get("name", k))
		qlines.append("%s x%d" % [nm, int(GameState.inventory[k])])
	for r in GameState.relics:
		var nm2: String = str(ContentDB.ITEMS.get(r, {}).get("name", r))
		qlines.append("◆ %s — %s" % [nm2, ContentDB.ITEMS.get(r, {}).get("desc", "")])
	qlines.append("")
	qlines.append("— CODEX / SKILLS —")
	qlines.append("1Π 2⟁ 3☿ 4∴ 5⟡ 6▣GUARD 7⊚SOL 8ITEM  F:flee")
	if GameState.has_flag("killed_overclaimer"):
		qlines.append("• Overclaim: MEASURE the shield first.")
	if GameState.has_flag("half_made_down"):
		qlines.append("• Residue: TRANSMUTE completes the form.")
	if GameState.has_flag("mirror_down"):
		qlines.append("• Hollow Mirror: vanity is a shield.")
	if GameState.has_flag("gold_down"):
		qlines.append("• Gold Threshold: the yellowing held.")
	if GameState.hall_wins >= 1:
		qlines.append("• Hall victories: %d / 3 → Albedo." % GameState.hall_wins)
	qlines.append("Secrets %d · Chests %d" % [GameState.secrets_found, GameState.chests_opened.size()])
	qlines.append("")
	qlines.append("— BESTIARY —")
	if GameState.bestiary.is_empty():
		qlines.append("(no ideas catalogued yet)")
	else:
		for fid in GameState.bestiary.keys():
			var b: Dictionary = GameState.bestiary[fid]
			qlines.append("• %s ×%d" % [b.get("name", fid), int(b.get("kills", 0))])
	qlines.append("")
	qlines.append("[1] Bread  [2] Elixir  [3] Quiet Dust  [S] Save  [L] Load  [Esc]")
	body.text = "\n".join(qlines)


func _menu_confirm() -> void:
	pass


func _input(event: InputEvent) -> void:
	if not menu_open:
		return
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_1:
				GameState.use_consumable("bread")
				_fill_menu()
				_refresh_hud()
			KEY_2:
				GameState.use_consumable("elixir")
				_fill_menu()
				_refresh_hud()
			KEY_3:
				GameState.use_consumable("repel_dust")
				_fill_menu()
				_refresh_hud()
			KEY_S:
				GameState.save_game()
				SFX.save_ok()
			KEY_L:
				if GameState.load_game():
					load_area(GameState.area_id, GameState.pos)
					_fill_menu()
					_refresh_hud()
					SFX.save_ok()


func _on_toast(msg: String) -> void:
	toast_label.text = msg
	toast_label.visible = true
	toast_t = 2.6
	SFX.ui()


func _refresh_hud() -> void:
	var shards := int(GameState.inventory.get("glyph_shard", 0))
	hp_label.text = "❤ %d/%d   Lv%d %s   ⟡%d" % [
		GameState.hp, GameState.max_hp, GameState.level, GameState.archetype, shards
	]
	area_label.text = str(area.get("name", GameState.area_id))
	companion_label.text = "⊚ Sol: \"%s\"" % GameState.companion_line
	if _quest_label:
		_quest_label.text = "▶ %s   ✧%d sparks · 🔎%d secrets" % [
			GameState.current_quest_tip(), GameState.star_sparks, GameState.secrets_found
		]


func is_solid(tx: int, ty: int) -> bool:
	if tx < 0 or ty < 0 or tx >= area_w or ty >= area_h:
		return true
	# false walls still solid until used as warp interact
	return AreaData.SOLID.has(tiles[ty][tx])
