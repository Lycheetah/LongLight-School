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
var _mart_open: bool = false
var _pending_mart: bool = false
var _location_splash: CanvasLayer
var _pending_trainer: Dictionary = {}
var _pending_cut_battle: Dictionary = {}
var _menu_tab: int = 0  # 0 quests 1 bag 2 codex 3 story 4 help 5 save · 10 mart 11 travel 12 map
var _travel_open: bool = false
var _travel_list: Array = []
var _map_open: bool = false
var _los_flash: Dictionary = {}  # {from: Vector2, to: Vector2, t: float}
var _menu_body: Label
var _menu_scroll: ScrollContainer
var _help_section: int = 0  # 0 guide 1 ask 2 myths 3 log


func _ready() -> void:
	colors = AreaData.colors()
	GameState.toast.connect(_on_toast)
	GameState.hp_changed.connect(_refresh_hud)
	GameState.battle_requested.connect(_on_battle_req)
	GameState.quest_updated.connect(_refresh_hud)
	if Journal.journal_changed.get_connections().is_empty() or true:
		if not Journal.journal_changed.is_connected(_on_journal):
			Journal.journal_changed.connect(_on_journal)
	if StoryAI and not StoryAI.status_changed.is_connected(_on_ai_status):
		StoryAI.status_changed.connect(_on_ai_status)
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
	# Ensure journal has prologue if new boot into overworld mid-run
	if Journal.story_entries.is_empty():
		Journal.clear_run()
	load_area(GameState.area_id, GameState.pos)
	_refresh_hud()


func _on_journal() -> void:
	if menu_open and _menu_tab in [3, 4]:
		_fill_menu()


func _on_ai_status(msg: String) -> void:
	if msg != "":
		GameState.toast.emit(msg)


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
		var dbody: Label = $HUD/Dialogue/Body
		dbody.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dbody.add_theme_font_size_override("font_size", 17)
	if has_node("HUD/MenuPanel/Title"):
		UIChromeUtil.style_label_title($HUD/MenuPanel/Title)
	_setup_menu_body()
	# top bar strip
	if has_node("HUD/TopBar"):
		$HUD/TopBar.color = Color("120c20e6")
	if has_node("HUD/BottomBar"):
		$HUD/BottomBar.color = Color("120c20e6")


func _setup_menu_body() -> void:
	## Prefer Scroll/Body from scene; fall back to creating chrome.
	if has_node("HUD/MenuPanel/Scroll"):
		_menu_scroll = $HUD/MenuPanel/Scroll
	if has_node("HUD/MenuPanel/Scroll/Body"):
		_menu_body = $HUD/MenuPanel/Scroll/Body
	elif has_node("HUD/MenuPanel/Body"):
		_menu_body = $HUD/MenuPanel/Body
	if _menu_body == null:
		return
	UIChromeUtil.style_label_body(_menu_body)
	_menu_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_body.add_theme_font_size_override("font_size", 15)
	_menu_body.add_theme_constant_override("line_spacing", 5)
	# Width drives wrap; height grows for scroll
	var inner_w: float = 780.0
	if _menu_scroll:
		inner_w = maxf(200.0, _menu_scroll.size.x - 24.0)
		if inner_w < 100.0:
			inner_w = 780.0
	_menu_body.custom_minimum_size = Vector2(inner_w, 0)
	_menu_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _set_menu_text(text: String) -> void:
	if _menu_body == null:
		_setup_menu_body()
	if _menu_body == null:
		return
	# Soft-wrap long single lines so boxes stay readable
	_menu_body.text = _polish_menu_text(text)
	# Grow label height for scroll; reset scroll next frame
	if _menu_scroll:
		call_deferred("_menu_scroll_top")


func _menu_scroll_top() -> void:
	if _menu_scroll and is_instance_valid(_menu_scroll):
		_menu_scroll.scroll_vertical = 0
	if _menu_body and _menu_scroll:
		var w: float = maxf(200.0, _menu_scroll.size.x - 16.0)
		_menu_body.custom_minimum_size = Vector2(w, 0)


func _polish_menu_text(text: String) -> String:
	## Break very long lines at ~72 cols; keep intentional newlines.
	var out: PackedStringArray = []
	for raw in text.split("\n"):
		var line: String = str(raw)
		if line.length() <= 72:
			out.append(line)
			continue
		var words: PackedStringArray = line.split(" ", false)
		var cur: String = ""
		for w in words:
			if cur == "":
				cur = w
			elif cur.length() + 1 + w.length() <= 72:
				cur += " " + w
			else:
				out.append(cur)
				cur = w
		if cur != "":
			out.append(cur)
	return "\n".join(out)


func _setup_companion() -> void:
	var cs := companion.get_node_or_null("CompSprite") as Sprite2D
	if cs:
		_refresh_companion_sprite()
		cs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cs.region_enabled = true
		cs.region_rect = Rect2(0, 0, 16, 16)
		cs.scale = Vector2(2, 2)
		cs.position = Vector2(0, -6)
		cs.centered = true


func _refresh_companion_sprite() -> void:
	var cs := companion.get_node_or_null("CompSprite") as Sprite2D
	if not cs:
		return
	if GameState.active_companion == "luna":
		_comp_sheet = PixelArtUtil.companion_sheet_luna()
	else:
		_comp_sheet = PixelArtUtil.companion_sheet()
	cs.texture = _comp_sheet


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
	GameState.mark_area_visited(id)
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
	Journal.try_story_triggers()
	# snap player to grid
	if player.has_method("_tile_center"):
		var t: Vector2i = player._tile_of(player.global_position)
		player.global_position = player._tile_center(t)
	var intro_key := "intro_%s" % id
	if not GameState.has_flag(intro_key) and ContentDB.AREA_NAMES.has(id):
		GameState.set_flag(intro_key, true)
		GameState.companion_line = ContentDB.COMPANION_LINES[randi() % ContentDB.COMPANION_LINES.size()]
	call_deferred("_maybe_area_cutscene", id, prev)


func _maybe_area_cutscene(id: String, prev: String) -> void:
	if prev == id:
		return
	if GameState.in_battle or dialogue_ui.visible:
		return
	if id == "path" and not GameState.has_flag("cut_path_first"):
		GameState.set_flag("cut_path_first", true)
		var cs: Dictionary = ContentDB.CUTSCENES.get("path_first", {})
		# after Sol intro, chain Overclaimer challenge if not yet cleared
		if not GameState.has_flag("killed_overclaimer") and not GameState.has_flag("cut_first_overclaimer"):
			var fo: Dictionary = ContentDB.CUTSCENES.get("first_overclaimer", {})
			_pending_cut_battle = {
				"foe": str(fo.get("foe", "overclaimer")),
				"meta": {
					"flag": "killed_overclaimer",
					"once": true,
					"boss": false,
					"cutscene": true,
				},
			}
			GameState.set_flag("cut_first_overclaimer", true)
			var lines: Array = cs.get("lines", []).duplicate()
			for ln in fo.get("lines", []):
				lines.append(ln)
			_open_dialogue(str(cs.get("speaker", "⊚ Sol")), lines)
		else:
			_open_dialogue(str(cs.get("speaker", "⊚ Sol")), cs.get("lines", []).duplicate())
		return
	if id == "rubedo" and not GameState.has_flag("cut_rubedo_open"):
		GameState.set_flag("cut_rubedo_open", true)
		var rb: Dictionary = ContentDB.CUTSCENES.get("rubedo_open", {})
		_open_dialogue(str(rb.get("speaker", "Herald")), rb.get("lines", []).duplicate())
		return
	if id == "scriptorium" and not GameState.has_flag("cut_scriptorium"):
		GameState.set_flag("cut_scriptorium", true)
		var sc: Dictionary = ContentDB.CUTSCENES.get("wing_scriptorium", {})
		_open_dialogue(str(sc.get("speaker", "…")), sc.get("lines", []).duplicate())


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
	SFX.ambient_tick(delta)
	_update_wanderers(delta)
	_update_ambient(delta)
	_secret_toast_cd = maxf(0.0, _secret_toast_cd - delta)
	if not _los_flash.is_empty():
		_los_flash.t = float(_los_flash.t) - delta
		if float(_los_flash.t) <= 0.0:
			_los_flash = {}
		queue_redraw()
	if GameState.in_battle or menu_open or dialogue_ui.visible or _map_open:
		return
	GameState.pos = player.global_position
	var target: Vector2 = player.global_position - player.facing * 22.0
	companion.global_position = companion.global_position.lerp(target, minf(1.0, 5.5 * delta))
	_check_tile_triggers()
	_check_collectible_step()
	_check_trainer_los()
	_random_world_event(delta)


func _draw() -> void:
	if _los_flash.is_empty():
		return
	var a: float = clampf(float(_los_flash.t) / 0.45, 0.0, 1.0)
	draw_line(Vector2(_los_flash.from), Vector2(_los_flash.to), Color(1.0, 0.2, 0.15, a), 2.0)
	draw_circle(Vector2(_los_flash.from), 6.0, Color(1.0, 0.3, 0.1, a))


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
		# eye flash line then snag
		_los_flash = {
			"from": Vector2(float(nx) + 0.5, float(ny) + 0.5) * TILE,
			"to": player.global_position,
			"t": 0.45,
		}
		GameState.toast.emit("! %s spots you!" % str(n.name))
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
				SFX.secret()
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
		if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed \
				and (event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_KP_ENTER or event.physical_keycode == KEY_SPACE)):
			_advance_dialogue()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("menu") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
			_close_dialogue(true)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_P:
				GameState.switch_companion()
				_refresh_companion_sprite()
				_refresh_hud()
				SFX.assist()
				get_viewport().set_input_as_handled()
				return
			KEY_T:
				_talk_companion()
				get_viewport().set_input_as_handled()
				return
			KEY_K:
				_field_measure()
				get_viewport().set_input_as_handled()
				return
			KEY_N:
				_toggle_world_map()
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed("interact"):
		_interact()
		get_viewport().set_input_as_handled()


func _field_measure() -> void:
	## Ping nearby digs, cracks, false walls, collectibles within 4 tiles.
	SFX.measure()
	var pt := Vector2i(int(player.global_position.x / TILE), int(player.global_position.y / TILE))
	var hits: PackedStringArray = []
	for d in dig_spots:
		var dx := absi(int(d.x) - pt.x) + absi(int(d.y) - pt.y)
		var dk := "dig:%s:%d:%d" % [GameState.area_id, int(d.x), int(d.y)]
		if dx <= 4 and not GameState.has_flag(dk):
			hits.append("disturbed earth (%d,%d)" % [int(d.x), int(d.y)])
	for fw in false_walls:
		var d2 := absi(int(fw.x) - pt.x) + absi(int(fw.y) - pt.y)
		if d2 <= 4:
			hits.append("hollow wall nearby…")
	for col in collectibles:
		var ck := "col:%s:%d:%d" % [GameState.area_id, int(col.x), int(col.y)]
		var d3 := absi(int(col.x) - pt.x) + absi(int(col.y) - pt.y)
		if d3 <= 4 and ck not in GameState.collectibles:
			hits.append("a spark of collectible light")
	# cracks on tiles
	for yy in range(maxi(0, pt.y - 3), mini(area_h, pt.y + 4)):
		for xx in range(maxi(0, pt.x - 3), mini(area_w, pt.x + 4)):
			if int(tiles[yy][xx]) == AreaData.T_CRACK:
				hits.append("crack in the structure")
	if hits.is_empty():
		GameState.toast.emit("Π Field MEASURE — nothing false nearby.")
	else:
		GameState.toast.emit("Π senses: %s" % hits[0])
		if hits.size() > 1:
			GameState.companion_line = "More than one secret. Keep scanning."
			_refresh_hud()


func _open_shrine_menu() -> void:
	_travel_list = GameState.shrine_destinations()
	_travel_open = true
	menu_open = true
	menu_panel.visible = true
	player.can_move = false
	_menu_tab = 11
	_fill_menu()
	SFX.ui()


func _toggle_world_map() -> void:
	if dialogue_ui.visible or _mart_open or _travel_open:
		return
	_map_open = not _map_open
	menu_open = _map_open
	menu_panel.visible = _map_open
	player.can_move = not _map_open
	if _map_open:
		_menu_tab = 12
		_fill_menu()
	else:
		_menu_tab = 0
	SFX.ui()


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
		GameState.steps_taken += 1
		# Quiet Dust repel
		var repel: int = int(GameState.flags.get("repel_steps", 0))
		if repel > 0:
			GameState.flags["repel_steps"] = repel - 1
			return
		# night: denser encounters (every ~18 steps vs 28 day)
		var interval := 18 if Atmosphere.phase_name() in ["night", "late_night", "dusk"] else 28
		if steps % interval == 0:
			var wild: Array = area.get("wild", []).duplicate()
			if wild.size() > 0:
				# night swaps in tougher ideas sometimes
				if Atmosphere.phase_name() in ["night", "late_night"] and randf() < 0.35:
					if ContentDB.FOES.has("pride_wight"):
						wild.append("pride_wight")
					if ContentDB.FOES.has("doubt_moth"):
						wild.append("doubt_moth")
				_start_battle(str(wild[randi() % wild.size()]), {"wild": true})


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
			GameState.earn_coins(1, "dig")
			SFX.save_ok()
			tiles[int(d.y)][int(d.x)] = AreaData.T_PATH
			map_draw.queue_redraw()
			_open_dialogue("Dig", [str(d.get("msg", "You dig.")), "Loot secured. +1 coin."])
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
			# Field CLEAR — Cut-analogue
			tiles[fty][ftx] = AreaData.T_GRASS
			var p_loot := 0.35 + (0.2 if GameState.level >= 4 else 0.0)
			if GameState.count_item("veras_dust") > 0 and randf() < 0.15:
				p_loot += 0.15
			if randf() < p_loot:
				GameState.add_item("veras_dust", 1)
				GameState.toast.emit("Field CLEAR — Veras Dust!")
			elif randf() < 0.12:
				GameState.add_item("glyph_shard", 1)
				GameState.toast.emit("Field CLEAR — a shard in the roots!")
			else:
				GameState.toast.emit("Field CLEAR — bush gone.")
			SFX.cast(4)
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
				SFX.chest()
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
	# shrine underfoot / adjacent — heal + register + travel
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var tx := int(player.global_position.x / TILE) + dx
			var ty := int(player.global_position.y / TILE) + dy
			if tx < 0 or ty < 0 or tx >= area_w or ty >= area_h:
				continue
			if tiles[ty][tx] == AreaData.T_SHRINE:
				GameState.heal_full()
				GameState.register_shrine(GameState.area_id)
				SFX.heal()
				_open_shrine_menu()
				return
			if tiles[ty][tx] == AreaData.T_ALTAR:
				_open_dialogue("Altar", [
					"The altar hums with unspent Π.",
					"Kneeling here clarifies: rest is valid. Absence is not failure.",
					ContentDB.FIELD_TIPS[randi() % ContentDB.FIELD_TIPS.size()],
				])
				return
			if tiles[ty][tx] == AreaData.T_WATER:
				_open_dialogue("Water", [
					"Still water. No surf skill in this School — yet.",
					"Reflection is free. Crossing is not.",
				])
				return
	GameState.toast.emit("… nothing to touch. (K = field MEASURE)")


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
	_pending_mart = true
	var greets: Array = n.get("lines", ["Welcome."]).duplicate()
	greets.append("Browse the shelf when ready…")
	_open_dialogue(str(n.name), greets)


func _open_mart_ui() -> void:
	_mart_open = true
	menu_open = true
	menu_panel.visible = true
	player.can_move = false
	_menu_tab = 10
	_fill_menu()
	SFX.ui()


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
		var more: bool = dialogue_i < dialogue_lines.size() - 1
		$HUD/Dialogue/Body.text = str(dialogue_lines[dialogue_i])
		if has_node("HUD/Dialogue/Next"):
			var nlab: Label = $HUD/Dialogue/Next
			if more:
				nlab.text = "Enter continue · Esc exit  (%d/%d)" % [dialogue_i + 1, dialogue_lines.size()]
			else:
				nlab.text = "Enter close · Esc exit  (%d/%d)" % [dialogue_i + 1, dialogue_lines.size()]
	else:
		_close_dialogue(false)


func _close_dialogue(cancel: bool = false) -> void:
	## Exit talk. cancel=true skips pending trainer/battle/mart from this chat.
	dialogue_ui.visible = false
	dialogue_lines = []
	dialogue_i = 0
	if cancel:
		_pending_trainer = {}
		_pending_cut_battle = {}
		_pending_mart = false
		player.can_move = not menu_open and not _mart_open
		GameState.toast.emit("Talk ended.")
		return
	if not _pending_trainer.is_empty():
		var n: Dictionary = _pending_trainer
		_pending_trainer = {}
		var tflag := str(n.get("flag", ""))
		if tflag == "" or not GameState.has_flag(tflag):
			var foe := str(n.get("foe", "fog_imp"))
			var meta := {"trainer": true, "flag": tflag, "boss": false, "once": true}
			_start_battle(foe, meta)
			return
	if not _pending_cut_battle.is_empty():
		var cb: Dictionary = _pending_cut_battle
		_pending_cut_battle = {}
		_start_battle(str(cb.get("foe", "overclaimer")), cb.get("meta", {"once": true}))
		return
	if _pending_mart:
		_pending_mart = false
		_open_mart_ui()
		return
	player.can_move = not menu_open and not _mart_open


func _advance_dialogue() -> void:
	dialogue_i += 1
	if dialogue_i >= dialogue_lines.size():
		_close_dialogue(false)
	else:
		_render_dialogue()
		SFX.talk()


func _talk_companion() -> void:
	var who: String = GameState.active_companion
	var lines: Array = []
	if who == "luna":
		var pool: Array = ContentDB.COMPANION_TALK_LUNA
		lines.append(pool[randi() % pool.size()])
		lines.append("Press T anytime. P switches lead when both walk with you.")
	else:
		var pool2: Array = ContentDB.COMPANION_TALK_SOL
		lines.append(pool2[randi() % pool2.size()])
		lines.append("Quest tip: %s" % GameState.current_quest_tip())
	# small coin tip chance
	if randf() < 0.2:
		GameState.earn_coins(1, "companion wisdom")
	var speaker: String = "%s %s" % [GameState.companion_glyph(), GameState.companion_name()]
	_open_dialogue(speaker, lines)
	if StoryAI.has_api():
		StoryAI.request_companion_line(who, StoryAI.build_context())


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
	if SFX.has_method("set_battle_bgm"):
		SFX.set_battle_bgm(true)
	battle_layer.visible = true
	battle_layer.start_battle(foe_id, meta)


func _on_battle_req(foe_id: String, meta: Dictionary) -> void:
	_start_battle(foe_id, meta)


func on_battle_ended(won: bool, meta: Dictionary) -> void:
	GameState.in_battle = false
	Atmosphere.set_battle_mode(false)
	if SFX.has_method("set_battle_bgm"):
		SFX.set_battle_bgm(false)
	battle_layer.visible = false
	player.can_move = true
	if bool(meta.get("fled", false)):
		_refresh_hud()
		return
	if won:
		SFX.win()
		GameState.battles_won += 1
		var coin_n: int = 2 + (3 if bool(meta.get("trainer", false)) else 0) + (4 if bool(meta.get("boss", false)) else 0)
		if bool(meta.get("wild", false)):
			coin_n = 1 + randi() % 2
		GameState.earn_coins(coin_n, "battle")
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
	if _mart_open:
		_close_mart()
		return
	if _travel_open:
		_close_travel()
		return
	if _map_open:
		_map_open = false
		menu_open = false
		menu_panel.visible = false
		player.can_move = not dialogue_ui.visible
		_menu_tab = 0
		SFX.ui()
		return
	menu_open = not menu_open
	menu_panel.visible = menu_open
	player.can_move = not menu_open and not dialogue_ui.visible
	SFX.ui()
	if menu_open:
		_menu_tab = 0
		_fill_menu()


func _close_mart() -> void:
	_mart_open = false
	_shop_mode = false
	menu_open = false
	menu_panel.visible = false
	player.can_move = not dialogue_ui.visible
	_menu_tab = 0
	SFX.ui()


func _close_travel() -> void:
	_travel_open = false
	menu_open = false
	menu_panel.visible = false
	player.can_move = not dialogue_ui.visible
	_menu_tab = 0
	SFX.ui()


func _do_travel(index: int) -> void:
	if index < 0 or index >= _travel_list.size():
		return
	var dest: Dictionary = _travel_list[index]
	var aid := str(dest.id)
	if aid == GameState.area_id:
		GameState.toast.emit("Already here.")
		_close_travel()
		return
	var sp: Vector2 = ContentDB.SHRINE_SPAWNS.get(aid, Vector2(10, 10))
	_close_travel()
	SFX.warp()
	GameState.toast.emit("Shrine-light carries you…")
	load_area(aid, Vector2(sp.x * TILE, sp.y * TILE))


func _fill_menu() -> void:
	var title_n: Label = $HUD/MenuPanel/Title if has_node("HUD/MenuPanel/Title") else null
	var tab_hint: Label = $HUD/MenuPanel/TabHint if has_node("HUD/MenuPanel/TabHint") else null
	var qlines: PackedStringArray = []
	if _mart_open or _menu_tab == 10:
		if title_n:
			title_n.text = "KEEPER MART"
		if tab_hint:
			tab_hint.text = "1–4 buy · Esc close"
		qlines.append("School Coins: %d" % GameState.coins())
		qlines.append("")
		var i := 1
		for stock in ContentDB.SHOP_STOCK:
			qlines.append("[%d]  %s" % [i, stock.label])
			qlines.append("     cost %d¢" % int(stock.cost))
			i += 1
		qlines.append("")
		qlines.append("Press 1–4 to buy one.")
		_set_menu_text("\n".join(qlines))
		return
	if _travel_open or _menu_tab == 11:
		if title_n:
			title_n.text = "SHRINE"
		if tab_hint:
			tab_hint.text = "0 rest till dawn · 1–9 travel · Esc close"
		qlines.append("Will restored · phase: %s" % Atmosphere.phase_name())
		qlines.append("")
		qlines.append("[0]  Rest until dawn")
		qlines.append("")
		qlines.append("— FAST TRAVEL —")
		var ti := 1
		for d in _travel_list:
			var here := "  ← you" if str(d.id) == GameState.area_id else ""
			qlines.append("[%d]  %s%s" % [ti, d.name, here])
			ti += 1
		if _travel_list.is_empty():
			qlines.append("(use more shrines to register them)")
		_set_menu_text("\n".join(qlines))
		return
	if _map_open or _menu_tab == 12:
		if title_n:
			title_n.text = "WORLD MAP"
		if tab_hint:
			tab_hint.text = "N or Esc close · ★ = visited"
		qlines.append("Playtime %s" % GameState.playtime_str())
		qlines.append("Steps %d · Areas %d · Secrets %d" % [
			GameState.steps_taken, GameState.areas_visited.size(), GameState.secrets_found
		])
		qlines.append("Battles won %d · fled %d" % [GameState.battles_won, GameState.battles_fled])
		qlines.append("")
		qlines.append("— SCHOOL GRAPH —")
		for aid in ContentDB.WORLD_MAP.keys():
			var star := "★" if aid in GameState.areas_visited else "·"
			var here := "  ◀ here" if aid == GameState.area_id else ""
			var nm: String = str(ContentDB.AREA_NAMES.get(aid, aid))
			qlines.append("%s  %s%s" % [star, nm, here])
		_set_menu_text("\n".join(qlines))
		return
	var tabs := ["QUESTS", "BAG", "CODEX", "STORY", "HELP", "SAVE"]
	var ti_safe: int = clampi(_menu_tab, 0, 5)
	if title_n:
		title_n.text = "MENU · %s" % tabs[ti_safe]
	var ai_s := "AI ON" if StoryAI.has_key() else "AI off"
	if tab_hint:
		tab_hint.text = "Q B C Y H V · %s · ¢%d · scroll ↓" % [ai_s, GameState.coins()]
	match ti_safe:
		0:
			qlines.append("NOW")
			qlines.append(GameState.current_quest_tip())
			qlines.append("")
			qlines.append("QUESTS")
			for qid in ContentDB.QUESTS.keys():
				var q: Dictionary = ContentDB.QUESTS[qid]
				var mark := "✓" if (qid in GameState.quests_done or GameState.has_flag(str(q.flag))) else "○"
				qlines.append("%s  %s" % [mark, q.title])
				if mark == "○":
					for step in q.get("steps", []):
						qlines.append("     · %s" % str(step))
			qlines.append("")
			qlines.append("PARTY")
			qlines.append("%s · Lv%d · %s" % [GameState.player_name, GameState.level, GameState.archetype])
			qlines.append("Will %d/%d · Ins %d · Wil %d · Lck %d" % [
				GameState.hp, GameState.max_hp,
				GameState.insight + GameState._relic_insight(),
				GameState.will_stat + GameState._relic_will(),
				GameState.luck
			])
			qlines.append("XP %d/%d · Hall %d/3 · ✧%d · secrets %d" % [
				GameState.xp, GameState.xp_next, GameState.hall_wins,
				GameState.star_sparks, GameState.secrets_found
			])
			qlines.append("Lead: %s  (P switch · T talk)" % GameState.companion_name())
		1:
			qlines.append("ITEMS  [1] bread  [2] elixir  [3] dust")
			qlines.append("")
			var consumable_n := 0
			for k in GameState.inventory.keys():
				var it: Dictionary = ContentDB.ITEMS.get(k, {})
				if str(it.get("type", "")) == "consumable":
					qlines.append("• %s  ×%d" % [it.get("name", k), int(GameState.inventory[k])])
					qlines.append("  %s" % it.get("desc", ""))
					consumable_n += 1
			if consumable_n == 0:
				qlines.append("(no consumables)")
			qlines.append("")
			qlines.append("COINS / CURRENCY")
			qlines.append("• School Coins  ¢%d" % GameState.coins())
			for k2 in GameState.inventory.keys():
				var it2: Dictionary = ContentDB.ITEMS.get(k2, {})
				if str(it2.get("type", "")) == "currency" and str(k2) != "glyph_shard":
					qlines.append("• %s  ×%d" % [it2.get("name", k2), int(GameState.inventory[k2])])
			qlines.append("")
			qlines.append("RELICS / KEYS")
			if GameState.relics.is_empty():
				qlines.append("(none yet)")
			for r in GameState.relics:
				var nm2: String = str(ContentDB.ITEMS.get(r, {}).get("name", r))
				qlines.append("◆ %s" % nm2)
				qlines.append("  %s" % ContentDB.ITEMS.get(r, {}).get("desc", ""))
			for k3 in GameState.inventory.keys():
				var it3: Dictionary = ContentDB.ITEMS.get(k3, {})
				if str(it3.get("type", "")) == "key":
					qlines.append("★ %s  ×%d" % [it3.get("name", k3), int(GameState.inventory[k3])])
		2:
			qlines.append("BATTLE SKILLS")
			qlines.append("1 MEASURE   strip false shields")
			qlines.append("2 COMPRESS  heavy if measured")
			qlines.append("3 TRANSMUTE heal · residue damage")
			qlines.append("4 BREAK     anti-loop")
			qlines.append("5 STRIKE    basic (feeds loops!)")
			qlines.append("6 GUARD     Lv2+")
			qlines.append("7 ASSIST    companion · Lv3+")
			qlines.append("8 ITEM      bread/elixir")
			qlines.append("9 DBL-Π     Lv5+ · 0 RUBEDO post-Gold")
			qlines.append("F flee (non-boss)")
			qlines.append("")
			qlines.append("FIELD")
			qlines.append("E bush CLEAR · K sense secrets · shrine travel")
			qlines.append("")
			qlines.append("LESSONS")
			if GameState.has_flag("killed_overclaimer"):
				qlines.append("• Overclaim: MEASURE first.")
			if GameState.has_flag("half_made_down"):
				qlines.append("• Residue: TRANSMUTE completes form.")
			if GameState.has_flag("mirror_down"):
				qlines.append("• Hollow: vanity is a shield.")
			if GameState.has_flag("gold_down"):
				qlines.append("• Gold held · RUBEDO-RAY open.")
			if GameState.hall_wins >= 1:
				qlines.append("• Hall wins %d/3 → Albedo." % GameState.hall_wins)
			qlines.append("")
			qlines.append("SIGILS  (%d/%d)" % [GameState.sigils_earned().size(), ContentDB.SIGILS.size()])
			var sigs: Array = GameState.sigils_earned()
			if sigs.is_empty():
				qlines.append("(defeat bosses & trainers)")
			else:
				for sg in sigs:
					qlines.append("◆ %s" % sg.name)
					qlines.append("  %s" % sg.desc)
			qlines.append("")
			qlines.append("BESTIARY")
			if GameState.bestiary.is_empty():
				qlines.append("(none catalogued)")
			else:
				for fid in GameState.bestiary.keys():
					var b: Dictionary = GameState.bestiary[fid]
					qlines.append("• %s  ×%d" % [b.get("name", fid), int(b.get("kills", 0))])
		3:
			qlines.append("CHRONICLE")
			qlines.append("Pages seal as you walk and win.")
			if StoryAI.has_key():
				qlines.append("AI: on · [R] weave next page")
			else:
				qlines.append("AI: off · School texts only · [R] check beats")
			qlines.append("")
			qlines.append(Journal.story_text_for_menu(4))
		4:
			_fill_help_menu(qlines)
		5:
			qlines.append("SAVE SLOTS")
			qlines.append("Journal, myths, and coins save with you.")
			qlines.append("")
			for s in range(1, GameState.SAVE_SLOTS + 1):
				var peek: Dictionary = GameState.peek_save(s)
				var mark := "▶" if s == GameState.active_slot else " "
				if peek.is_empty():
					qlines.append("%s [%d]  empty" % [mark, s])
				else:
					var aname: String = str(ContentDB.AREA_NAMES.get(str(peek.area_id), peek.area_id))
					qlines.append("%s [%d]  %s · Lv%d %s" % [
						mark, s, peek.player_name, int(peek.level), peek.archetype
					])
					qlines.append("         %s" % aname)
			qlines.append("")
			qlines.append("[1/2/3] select · [S] save · [L] load")
		_:
			qlines.append("(tab)")
	_set_menu_text("\n".join(qlines))


func _fill_help_menu(qlines: PackedStringArray) -> void:
	## Sectioned help so text fits: 0 guide · 1 ask · 2 myths · 3 log
	var sec_names := ["GUIDE", "ASK", "MYTHS", "LOG"]
	_help_section = clampi(_help_section, 0, 3)
	qlines.append("HELP  ·  section %s  (%d/4)" % [sec_names[_help_section], _help_section + 1])
	qlines.append("¢%d coins · %d myths · %s" % [
		GameState.coins(), Journal.myths_owned.size(),
		"AI on" if StoryAI.has_key() else "AI off",
	])
	qlines.append("Tab section:  , / .   or  keys below")
	qlines.append("")
	match _help_section:
		0:
			var pages: Array = ContentDB.HELP_PAGES
			var pi: int = clampi(Journal.help_page, 0, maxi(0, pages.size() - 1))
			Journal.help_page = pi
			qlines.append("GUIDE PAGE %d / %d" % [pi + 1, maxi(1, pages.size())])
			if pages.size() > 0:
				var pg: Dictionary = pages[pi]
				qlines.append("")
				qlines.append(str(pg.get("title", "")).to_upper())
				qlines.append("")
				qlines.append(str(pg.get("body", "")))
			qlines.append("")
			qlines.append(",  previous page     .  next page")
			qlines.append("1–4 jump section    Esc close")
		1:
			qlines.append("ASK THE SCHOOL")
			qlines.append("Press a number for a clear answer.")
			qlines.append("")
			var qi := 1
			for qq in ContentDB.HELP_QUESTIONS:
				qlines.append("[%d]  %s" % [qi, qq])
				qi += 1
			qlines.append("")
			qlines.append("Answers also land in LOG (section 4).")
		2:
			qlines.append("MYTH ARCHIVE")
			qlines.append("Spend School Coins for sealed myths.")
			qlines.append("")
			var mi := 0
			for seed in ContentDB.MYTH_SEED:
				if mi >= 4:
					break
				var owned: bool = Journal.owns_myth(str(seed.id))
				var tag: String = "owned ✓" if owned else "%d¢" % int(seed.cost)
				qlines.append("[%d]  %s" % [6 + mi, seed.title])
				qlines.append("     %s" % tag)
				mi += 1
			qlines.append("")
			if Journal.myths_owned.is_empty():
				qlines.append("Your shelf is empty — buy one above.")
			else:
				qlines.append("YOUR SHELF")
				qlines.append(Journal.myths_text())
		3:
			qlines.append("HELP LOG")
			qlines.append("Recent answers and tips.")
			qlines.append("")
			qlines.append(Journal.help_log_text(6))
		_:
			qlines.append("(section)")


func _menu_confirm() -> void:
	pass


func _buy_mart(index: int) -> void:
	if index < 0 or index >= ContentDB.SHOP_STOCK.size():
		return
	var stock: Dictionary = ContentDB.SHOP_STOCK[index]
	var cost := int(stock.cost)
	var iid := str(stock.id)
	if not GameState.spend_shards(cost):
		GameState.toast.emit("Need %d⟡ — earn shards in battle." % cost)
		return
	GameState.add_item(iid, 1)
	SFX.ui()
	_fill_menu()
	_refresh_hud()


func _input(event: InputEvent) -> void:
	if not menu_open:
		return
	if event is InputEventKey and event.pressed:
		var code: int = event.physical_keycode
		# mart mode
		if _mart_open or _menu_tab == 10:
			match code:
				KEY_1:
					_buy_mart(0)
				KEY_2:
					_buy_mart(1)
				KEY_3:
					_buy_mart(2)
				KEY_4:
					_buy_mart(3)
				KEY_ESCAPE:
					_close_mart()
			return
		# shrine travel
		if _travel_open or _menu_tab == 11:
			match code:
				KEY_0:
					Atmosphere.time_of_day = 0.22  # dawn
					GameState.heal_full()
					GameState.toast.emit("You rest. Dawn returns. Absence is not failure.")
					SFX.heal()
					_close_travel()
				KEY_1:
					_do_travel(0)
				KEY_2:
					_do_travel(1)
				KEY_3:
					_do_travel(2)
				KEY_4:
					_do_travel(3)
				KEY_5:
					_do_travel(4)
				KEY_6:
					_do_travel(5)
				KEY_ESCAPE:
					_close_travel()
			return
		if _map_open or _menu_tab == 12:
			if code == KEY_ESCAPE or code == KEY_N:
				_toggle_world_map()
			return
		# tab switch (6 main tabs)
		match code:
			KEY_LEFT:
				_menu_tab = (_menu_tab - 1 + 6) % 6
				_fill_menu()
				return
			KEY_RIGHT:
				_menu_tab = (_menu_tab + 1) % 6
				_fill_menu()
				return
			KEY_Q:
				_menu_tab = 0
				_fill_menu()
				return
			KEY_B:
				_menu_tab = 1
				_fill_menu()
				return
			KEY_C:
				_menu_tab = 2
				_fill_menu()
				return
			KEY_Y:
				_menu_tab = 3
				_fill_menu()
				return
			KEY_H:
				_menu_tab = 4
				_fill_menu()
				return
			KEY_V:
				_menu_tab = 5
				_fill_menu()
				return
		if _menu_tab == 1:
			match code:
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
		elif _menu_tab == 3:
			# Story
			if code == KEY_R:
				Journal.try_story_triggers()
				if StoryAI.has_api() and not StoryAI._busy:
					# Force a companion reflection if no new beat
					StoryAI.request_story_chapter(
						"reflect_%s" % GameState.area_id,
						"Reflect on where the seeker stands now in the School.",
						StoryAI.build_context()
					)
				_fill_menu()
				_refresh_hud()
		elif _menu_tab == 4:
			# Help: sections + pages + ask + myths
			match code:
				KEY_COMMA:
					# prev guide page or prev section
					if _help_section == 0:
						if Journal.help_page > 0:
							Journal.help_page -= 1
						else:
							_help_section = 3
					else:
						_help_section = maxi(0, _help_section - 1)
					_fill_menu()
				KEY_PERIOD:
					if _help_section == 0:
						if Journal.help_page < ContentDB.HELP_PAGES.size() - 1:
							Journal.help_page += 1
						else:
							_help_section = mini(3, _help_section + 1)
					else:
						_help_section = mini(3, _help_section + 1)
					_fill_menu()
				KEY_BRACKETLEFT:
					Journal.help_page = maxi(0, Journal.help_page - 1)
					_help_section = 0
					_fill_menu()
				KEY_BRACKETRIGHT:
					Journal.help_page = mini(ContentDB.HELP_PAGES.size() - 1, Journal.help_page + 1)
					_help_section = 0
					_fill_menu()
				KEY_1:
					if _help_section == 1:
						Journal.ask_help(0)
					else:
						_help_section = 0
					_fill_menu()
				KEY_2:
					if _help_section == 1:
						Journal.ask_help(1)
					else:
						_help_section = 1
					_fill_menu()
				KEY_3:
					if _help_section == 1:
						Journal.ask_help(2)
					else:
						_help_section = 2
					_fill_menu()
				KEY_4:
					if _help_section == 1:
						Journal.ask_help(3)
					else:
						_help_section = 3
					_fill_menu()
				KEY_5:
					if _help_section == 1:
						Journal.ask_help(4)
						_fill_menu()
				KEY_6:
					_help_section = 2
					Journal.buy_myth(0)
					_fill_menu()
					_refresh_hud()
				KEY_7:
					_help_section = 2
					Journal.buy_myth(1)
					_fill_menu()
					_refresh_hud()
				KEY_8:
					_help_section = 2
					Journal.buy_myth(2)
					_fill_menu()
					_refresh_hud()
				KEY_9:
					_help_section = 2
					Journal.buy_myth(3)
					_fill_menu()
					_refresh_hud()
		elif _menu_tab == 5:
			match code:
				KEY_1:
					GameState.active_slot = 1
					_fill_menu()
				KEY_2:
					GameState.active_slot = 2
					_fill_menu()
				KEY_3:
					GameState.active_slot = 3
					_fill_menu()
				KEY_S:
					GameState.save_game(GameState.active_slot)
					SFX.save_ok()
					_fill_menu()
				KEY_L:
					if GameState.load_game(GameState.active_slot):
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
	hp_label.text = "❤ %d/%d  Lv%d %s  ¢%d" % [
		GameState.hp, GameState.max_hp, GameState.level, GameState.archetype, shards
	]
	area_label.text = str(area.get("name", GameState.area_id))
	companion_label.text = "%s %s: \"%s\"  [T] talk [P] switch" % [
		GameState.companion_glyph(), GameState.companion_name(), GameState.companion_line
	]
	if _quest_label:
		_quest_label.text = "▶ %s   ✧%d sparks · 🔎%d secrets" % [
			GameState.current_quest_tip(), GameState.star_sparks, GameState.secrets_found
		]


func is_solid(tx: int, ty: int) -> bool:
	if tx < 0 or ty < 0 or tx >= area_w or ty >= area_h:
		return true
	# false walls still solid until used as warp interact
	return AreaData.SOLID.has(tiles[ty][tx])
