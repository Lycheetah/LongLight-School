extends CanvasLayer
## Framework combat — full skill kit + juice.

const PixelArtUtil = preload("res://scripts/util/pixel_art.gd")
const CombatCore = preload("res://scripts/combat/combat_core.gd")
const BattleFxScript = preload("res://scripts/combat/battle_fx.gd")

signal battle_finished(won: bool, meta: Dictionary)

var meta: Dictionary = {}
var battle: Dictionary = {}
var stats: Dictionary = {}
var log_lines: PackedStringArray = []
var _shake: float = 0.0
var _flash_mod: float = 0.0

@onready var title: Label = $Panel/Title
@onready var foe_label: Label = $Panel/FoeName
@onready var log_label: Label = $Panel/Log
@onready var skills_label: Label = $Panel/Skills
@onready var bars: Label = $Panel/Bars
@onready var status: Label = $Panel/Status
@onready var panel: ColorRect = $Panel
var foe_sprite: Sprite2D
var bar_foe: ColorRect
var bar_foe_bg: ColorRect
var bar_you: ColorRect
var bar_you_bg: ColorRect
var bar_shield: ColorRect
var _fx: Node2D
var _arena: ColorRect
var _comp_sprite: Sprite2D


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_extra_ui()


func _build_extra_ui() -> void:
	var arena_border := ColorRect.new()
	arena_border.color = Color("f0d080")
	arena_border.position = Vector2(696, 36)
	arena_border.size = Vector2(528, 308)
	panel.add_child(arena_border)
	_arena = ColorRect.new()
	_arena.color = Color("0e1830")
	_arena.position = Vector2(700, 40)
	_arena.size = Vector2(520, 300)
	panel.add_child(_arena)

	foe_sprite = Sprite2D.new()
	foe_sprite.position = Vector2(960, 200)
	foe_sprite.scale = Vector2(5, 5)
	foe_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_child(foe_sprite)

	_comp_sprite = Sprite2D.new()
	_comp_sprite.position = Vector2(780, 280)
	_comp_sprite.scale = Vector2(3, 3)
	_comp_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_child(_comp_sprite)

	_fx = BattleFxScript.new()
	_fx.z_index = 20
	panel.add_child(_fx)

	bar_foe_bg = ColorRect.new()
	bar_foe_bg.color = Color(0.08, 0.06, 0.1)
	bar_foe_bg.position = Vector2(40, 118)
	bar_foe_bg.size = Vector2(524, 20)
	panel.add_child(bar_foe_bg)
	bar_foe = ColorRect.new()
	bar_foe.color = Color("e74c3c")
	bar_foe.position = Vector2(42, 120)
	bar_foe.size = Vector2(520, 16)
	panel.add_child(bar_foe)
	bar_shield = ColorRect.new()
	bar_shield.color = Color("9b59b6")
	bar_shield.position = Vector2(42, 110)
	bar_shield.size = Vector2(0, 6)
	panel.add_child(bar_shield)
	bar_you_bg = ColorRect.new()
	bar_you_bg.color = Color(0.08, 0.1, 0.08)
	bar_you_bg.position = Vector2(40, 158)
	bar_you_bg.size = Vector2(524, 20)
	panel.add_child(bar_you_bg)
	bar_you = ColorRect.new()
	bar_you.color = Color("2ecc71")
	bar_you.position = Vector2(42, 160)
	bar_you.size = Vector2(520, 16)
	panel.add_child(bar_you)


func _process(delta: float) -> void:
	if not visible:
		return
	if _shake > 0:
		_shake -= delta
		panel.position = Vector2(randf_range(-4, 4), randf_range(-3, 3)) * (_shake * 8.0)
		if _shake <= 0:
			panel.position = Vector2.ZERO
	if _flash_mod > 0:
		_flash_mod = maxf(0.0, _flash_mod - delta * 3.0)
		if _arena:
			_arena.color = Color("0e1830").lerp(Color("3a2040"), _flash_mod)
	if foe_sprite:
		foe_sprite.position.y = 200 + sin(Time.get_ticks_msec() * 0.004) * 6.0
		foe_sprite.modulate.a = 0.45 if bool(battle.get("phased", false)) else 1.0
	if _comp_sprite:
		_comp_sprite.position.y = 280 + sin(Time.get_ticks_msec() * 0.005) * 4.0


func start_battle(id: String, m: Dictionary) -> void:
	meta = m.duplicate()
	var f: Dictionary = ContentDB.FOES.get(id, ContentDB.FOES.overclaimer)
	# level-scale lightly
	var lvl: int = GameState.level
	var hp_sc: int = int(f.hp) + (lvl - 1) * 3
	battle = {
		"foe_id": id,
		"foe_name": str(f.name),
		"foe_hp": hp_sc,
		"foe_max": hp_sc,
		"foe_shield": int(f.get("shield", 0)),
		"foe_atk": int(f.atk) + (lvl - 1) / 2,
		"foe_def": int(f.def),
		"kind": str(f.kind),
		"xp": int(f.xp) + (lvl - 1) * 4,
		"loot": f.get("loot", []).duplicate(),
		"lines": f.get("lines", []).duplicate(),
		"color": f.get("color", Color.RED),
		"measured": false,
		"phased": false,
		"broken_turns": 0,
		"strain": 0,
		"guarded": false,
		"assist_used": false,
		"cd": {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0},
		"turn": "player",
		"done": false,
		"won": false,
	}
	stats = GameState.get_stat_block()
	stats.hp = GameState.hp
	stats.max_hp = GameState.max_hp
	log_lines = PackedStringArray([
		"%s emerges from broken idea-space!" % battle.foe_name,
		"1–5 core · 6 GUARD · 7 SOL · 8 ITEM · 9 Double-Π (Lv5) · 0 Rubedo-Ray",
		"[F] flee non-boss",
	])
	if foe_sprite:
		foe_sprite.texture = PixelArtUtil.foe_tex(battle.color)
	if _comp_sprite:
		if GameState.active_companion == "luna":
			_comp_sprite.texture = PixelArtUtil.companion_sheet_luna()
		else:
			_comp_sprite.texture = PixelArtUtil.companion_sheet()
	visible = true
	SFX.encounter()
	if _fx and _fx.has_method("cast"):
		_fx.cast(7, Vector2(780, 260))
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if bool(battle.get("done", false)):
		if event.is_action_pressed("interact"):
			_finish()
			get_viewport().set_input_as_handled()
		return
	if str(battle.get("turn", "")) != "player":
		return
	var skill := -1
	if event.is_action_pressed("skill_1"):
		skill = 1
	elif event.is_action_pressed("skill_2"):
		skill = 2
	elif event.is_action_pressed("skill_3"):
		skill = 3
	elif event.is_action_pressed("skill_4"):
		skill = 4
	elif event.is_action_pressed("skill_5"):
		skill = 5
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_6: skill = 6
			KEY_7: skill = 7
			KEY_8: skill = 8
			KEY_9: skill = 9
			KEY_0: skill = 0
			KEY_F:
				_try_flee()
				get_viewport().set_input_as_handled()
				return
	if skill >= 0:
		_skill(skill)
		get_viewport().set_input_as_handled()


func _try_flee() -> void:
	if str(battle.get("kind", "")) in ["boss"] or bool(meta.get("boss", false)):
		_log("No fleeing a Threshold. Face it.")
		SFX.ui()
		_refresh()
		return
	var luck: int = int(stats.get("luck", 5))
	if randf() < 0.35 + luck * 0.04:
		_log("You slip the idea's grip.")
		battle.done = true
		battle.won = false
		# special: flee win=false but not death
		meta["fled"] = true
		SFX.warp()
		_refresh()
	else:
		_log("Couldn't break contact!")
		battle.turn = "foe"
		_refresh()
		_foe_turn()


func _skill(n: int) -> void:
	if not GameState.skill_unlocked(n) and n not in [0, 9]:
		pass
	if n == 9 and GameState.level < 5:
		_log("Double-Measure unlocks at Level 5.")
		SFX.ui()
		_refresh()
		return
	if n == 0 and not GameState.has_flag("gold_down"):
		_log("Rubedo-Ray unlocks after the Gold Threshold.")
		SFX.ui()
		_refresh()
		return
	if n == 6 and GameState.level < 2:
		_log("GUARD unlocks at Level 2.")
		SFX.ui()
		_refresh()
		return
	if n == 7 and GameState.level < 3:
		_log("SOL-ASSIST unlocks at Level 3.")
		SFX.ui()
		_refresh()
		return
	# cast juice at arena center / companion
	var cast_origin := Vector2(860, 220)
	if _fx and _fx.has_method("cast"):
		_fx.cast(n, cast_origin)
	_flash_mod = 0.55
	SFX.cast(n)
	var logs: PackedStringArray = CombatCore.player_act(battle, stats, n, GameState.inventory)
	var hitty := false
	var healy := false
	for line in logs:
		_log(line)
		if "MEASURE" in line:
			SFX.measure()
		elif "TRANSMUTE" in line or "Bread" in line or "Elixir" in line or "heal" in line.to_lower() or "restore" in line.to_lower():
			SFX.heal()
			healy = true
		elif "GUARD" in line:
			SFX.guard()
			if _fx and _fx.has_method("guard_ring"):
				_fx.guard_ring(Vector2(780, 280))
		elif "SOL" in line or "LUNA" in line or "ASSIST" in line:
			SFX.assist()
		elif "cooling" in line or "No consumable" in line or "unlock" in line.to_lower():
			SFX.ui()
		else:
			hitty = true
	if hitty:
		SFX.hit()
		_shake = 0.14
		if _fx and _fx.has_method("hit_flash"):
			_fx.hit_flash(Vector2(960, 200), n in [0, 2, 9])
		if foe_sprite:
			var tw := create_tween()
			tw.tween_property(foe_sprite, "modulate", Color(2, 0.6, 0.6), 0.05)
			tw.tween_property(foe_sprite, "modulate", Color.WHITE, 0.12)
	if healy and _fx and _fx.has_method("heal_burst"):
		_fx.heal_burst(Vector2(780, 280))
	GameState.hp = int(stats.hp)
	GameState.hp_changed.emit()
	GameState.inventory_changed.emit()
	if bool(battle.done):
		if bool(battle.won):
			SFX.win()
			if _fx:
				_fx.hit_flash(Vector2(960, 200), true)
		_refresh()
		return
	if str(battle.turn) == "foe":
		_refresh()
		_foe_turn()
	else:
		_refresh()


func _foe_turn() -> void:
	var logs: PackedStringArray = CombatCore.foe_act(battle, stats)
	for line in logs:
		_log(line)
	_shake = 0.18
	_flash_mod = 0.7
	SFX.hit()
	if _fx and _fx.has_method("hit_flash"):
		_fx.hit_flash(Vector2(780, 280), true)
	GameState.hp = int(stats.hp)
	GameState.hp_changed.emit()
	if bool(battle.done) and not bool(battle.won):
		SFX.lose()
	_refresh()


func _log(s: String) -> void:
	log_lines.append(s)
	if log_lines.size() > 9:
		log_lines = log_lines.slice(log_lines.size() - 9)


func _refresh() -> void:
	title.text = "INNER DEMON"
	var tags := ""
	if bool(battle.get("measured", false)):
		tags += "  [MEASURED]"
	if bool(battle.get("phased", false)):
		tags += "  [PHASED]"
	if int(battle.get("broken_turns", 0)) > 0:
		tags += "  [CRACKED]"
	if int(battle.get("strain", 0)) > 0:
		tags += "  strain:%d" % int(battle.strain)
	foe_label.text = str(battle.foe_name) + tags
	var sh := "  · shield %d" % int(battle.foe_shield) if int(battle.foe_shield) > 0 else ""
	bars.text = "Foe  %d / %d%s\nYou  %d / %d Will" % [
		int(battle.foe_hp), int(battle.foe_max), sh, GameState.hp, GameState.max_hp
	]
	if bar_foe and int(battle.foe_max) > 0:
		bar_foe.size.x = 520.0 * float(battle.foe_hp) / float(battle.foe_max)
		bar_foe.color = Color("f39c12") if bool(battle.measured) else Color("e74c3c")
	if bar_shield:
		bar_shield.size.x = 520.0 * float(battle.foe_shield) / 30.0 if int(battle.foe_shield) > 0 else 0.0
	if bar_you and GameState.max_hp > 0:
		bar_you.size.x = 520.0 * float(GameState.hp) / float(GameState.max_hp)

	var cd: Dictionary = battle.get("cd", {})
	var sk: PackedStringArray = []
	var defs := {
		1: "Strip false shields · reveal true HP",
		2: "Heavy dmg if MEASURED",
		3: "Heal Will · cleanse strain · hurt residue",
		4: "Crack structure · extra vs Loop",
		5: "Basic ray · feeds Loops!",
		6: "Halve next hit",
		7: "Active companion strikes + heals",
		8: "Use Bread/Elixir from pack",
	}
	var names := {1: "MEASURE", 2: "COMPRESS", 3: "TRANSMUTE", 4: "BREAK", 5: "STRIKE", 6: "GUARD", 7: "SOL", 8: "ITEM", 9: "DBL-Π", 0: "RUBEDO"}
	var glyphs := {1: "Π", 2: "⟁", 3: "☿", 4: "∴", 5: "⟡", 6: "▣", 7: "⊚", 8: "✦", 9: "ΠΠ", 0: "☀"}
	defs[9] = "Lv5+: measure + true burst"
	defs[0] = "Post-Gold: solar blast"
	for i in [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]:
		var c: int = int(cd.get(i, 0))
		var cd_s := "CD%d" % c if c > 0 else "OK"
		var lock := ""
		if i == 6 and GameState.level < 2:
			lock = " [Lv2]"
		elif i == 7 and GameState.level < 3:
			lock = " [Lv3]"
		elif i == 9 and GameState.level < 5:
			lock = " [Lv5]"
		elif i == 0 and not GameState.has_flag("gold_down"):
			lock = " [locked]"
		sk.append("[%s] %s %s %s%s — %s" % [
			str(i) if i != 0 else "0", glyphs[i], names[i], cd_s, lock, defs.get(i, "")
		])
	sk.append("[F] Flee (non-boss)")
	skills_label.text = "\n".join(sk)
	log_label.text = "\n".join(log_lines)
	if bool(battle.done):
		if bool(meta.get("fled", false)):
			status.text = "Escaped — Enter"
		elif bool(battle.won):
			status.text = "✦ VICTORY — Enter"
		else:
			status.text = "▽ DEFEATED — Enter (Sanctum)"
	else:
		status.text = "Your turn — 1–8 skills" if str(battle.turn) == "player" else "…"


func _finish() -> void:
	visible = false
	var fled: bool = bool(meta.get("fled", false))
	if bool(battle.won) and not fled:
		GameState.add_xp(int(battle.xp))
		GameState.record_bestiary(str(battle.foe_id), str(battle.foe_name))
		for it in battle.get("loot", []):
			var always := str(it) in ["glyph_shard", "athans_coal", "sigil_shard", "candle", "lens", "mercury_vial"]
			if always or randf() < (0.85 if GameState.bonus == "loot_boost" else 0.65):
				GameState.add_item(str(it))
	var ow := get_parent()
	if ow.has_method("on_battle_ended"):
		if fled:
			# treat flee as non-death exit
			GameState.in_battle = false
			Atmosphere.set_battle_mode(false)
			if SFX.has_method("set_battle_bgm"):
				SFX.set_battle_bgm(false)
			ow.player.can_move = true
			visible = false
			# nudge player back
			ow.player.global_position -= ow.player.facing * 24.0
			GameState.toast.emit("You step back from the idea.")
			return
		ow.on_battle_ended(bool(battle.won), meta)
	battle_finished.emit(bool(battle.won), meta)
