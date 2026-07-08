extends Node
## Persistent run state — flags, inventory, party, position, save.

signal flags_changed
signal inventory_changed
signal hp_changed
signal area_changed(area_id: String)
signal battle_requested(foe_id: String, meta: Dictionary)
signal dialogue_requested(speaker: String, lines: Array)
signal toast(msg: String)
signal quest_updated

const SAVE_PATH := "user://longlight_save.json"

var archetype: String = "ALCHEMIST"
var player_name: String = "Seeker"
var level: int = 1
var xp: int = 0
var xp_next: int = 50
var hp: int = 36
var max_hp: int = 36
var insight: int = 10
var will_stat: int = 8
var luck: int = 5
var move_speed: float = 110.0
var bonus: String = "transmute_boost"

var area_id: String = "sanctum"
var pos: Vector2 = Vector2(352, 640)  # tile*32 coords
var facing: Vector2 = Vector2(0, 1)

var inventory: Dictionary = {}  # id -> count
var relics: Array[String] = []
var flags: Dictionary = {}  # string -> bool/int
var hall_wins: int = 0
var companion_line: String = "The light grows. I walk with you."
var quests_done: Array[String] = []
var bestiary: Dictionary = {}  # foe_id -> {name, kills}
var secrets_found: int = 0
var chests_opened: Array[String] = []  # "area:x:y"
var star_sparks: int = 0
var collectibles: Array[String] = []  # keys taken

var in_battle: bool = false
var paused: bool = false


func _ready() -> void:
	randomize()


func new_game(arch: String, seeker: String = "Seeker") -> void:
	archetype = arch
	player_name = seeker if seeker.strip_edges() != "" else "Seeker"
	var a: Dictionary = ContentDB.ARCHETYPES[arch]
	max_hp = int(a.hp)
	hp = max_hp
	insight = int(a.insight)
	will_stat = int(a.will)
	luck = int(a.luck)
	move_speed = float(a.speed)
	bonus = str(a.bonus)
	level = 1
	xp = 0
	xp_next = 50
	inventory = {"bread": 2}
	relics = []
	flags = {}
	hall_wins = 0
	area_id = "sanctum"
	pos = Vector2(11 * 32 + 16, 20 * 32 + 16)
	quests_done = []
	bestiary = {}
	secrets_found = 0
	chests_opened = []
	star_sparks = 0
	collectibles = []
	companion_line = "Welcome, %s. The light grows." % player_name
	recalc_relics()
	flags_changed.emit()
	inventory_changed.emit()
	hp_changed.emit()


func get_stat_block() -> Dictionary:
	return {
		"hp": hp,
		"max_hp": max_hp,
		"insight": insight + _relic_insight(),
		"will": will_stat + _relic_will(),
		"luck": luck + _relic_luck(),
		"bonus": bonus,
		"relics": relics.duplicate(),
		"level": level,
		"unlock_rubedo_ray": has_flag("gold_down"),
	}


func skill_unlocked(skill_id: int) -> bool:
	if skill_id == 0:  # RUBEDO-RAY mapped to key 0 / KEY_9
		return has_flag("gold_down")
	if skill_id == 9:
		return level >= 5
	var sk: Dictionary = ContentDB.SKILLS.get(skill_id, {})
	return level >= int(sk.get("unlock_level", 1))


func _relic_insight() -> int:
	var n := 0
	for r in relics:
		if ContentDB.ITEMS.has(r) and ContentDB.ITEMS[r].has("insight"):
			n += int(ContentDB.ITEMS[r].insight)
	return n


func _relic_will() -> int:
	var n := 0
	for r in relics:
		if ContentDB.ITEMS.has(r) and ContentDB.ITEMS[r].has("will"):
			n += int(ContentDB.ITEMS[r].will)
	return n


func _relic_luck() -> int:
	var n := 0
	for r in relics:
		if ContentDB.ITEMS.has(r) and ContentDB.ITEMS[r].has("luck"):
			n += int(ContentDB.ITEMS[r].luck)
	return n


func recalc_relics() -> void:
	var a: Dictionary = ContentDB.ARCHETYPES[archetype]
	max_hp = int(a.hp) + (level - 1) * 4
	if "athans_coal" in relics:
		max_hp += 8
	if "sol_stone" in relics:
		max_hp += 6
		insight = maxi(insight, int(a.insight) + 3)
		will_stat = maxi(will_stat, int(a.will) + 3)
		luck = maxi(luck, int(a.luck) + 3)
	hp = mini(hp, max_hp)


func add_item(id: String, n: int = 1) -> void:
	if not ContentDB.ITEMS.has(id):
		return
	var t: String = str(ContentDB.ITEMS[id].get("type", ""))
	if t == "relic" or t == "key":
		if id not in relics:
			relics.append(id)
			recalc_relics()
	else:
		inventory[id] = int(inventory.get(id, 0)) + n
	inventory_changed.emit()
	toast.emit("Obtained: %s x%d" % [ContentDB.ITEMS[id].name, n])


func use_consumable(id: String) -> bool:
	if int(inventory.get(id, 0)) <= 0:
		return false
	var it: Dictionary = ContentDB.ITEMS.get(id, {})
	if str(it.get("type", "")) != "consumable":
		return false
	if id == "repel_dust":
		flags["repel_steps"] = 50
		inventory[id] = int(inventory[id]) - 1
		if inventory[id] <= 0:
			inventory.erase(id)
		inventory_changed.emit()
		toast.emit("Quiet Dust — wild grass sleeps for 50 steps.")
		return true
	var heal: int = int(it.get("heal", 0))
	hp = mini(max_hp, hp + heal)
	inventory[id] = int(inventory[id]) - 1
	if inventory[id] <= 0:
		inventory.erase(id)
	inventory_changed.emit()
	hp_changed.emit()
	toast.emit("Used %s (+%d Will)" % [it.name, heal])
	return true


func set_flag(key: String, val = true) -> void:
	flags[key] = val
	flags_changed.emit()
	_check_quests()


func has_flag(key: String) -> bool:
	return bool(flags.get(key, false))


func add_xp(n: int) -> void:
	xp += n
	toast.emit("+%d XP" % n)
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		xp_next = int(xp_next * 1.45) + 10
		max_hp += 4
		hp = max_hp
		insight += 1
		if level % 2 == 0:
			will_stat += 1
		if level % 3 == 0:
			luck += 1
		toast.emit("✦ Level %d — the Work deepens." % level)
		if Engine.has_singleton("SFX") or true:
			if SFX.has_method("level_up"):
				SFX.level_up()
	hp_changed.emit()


func current_quest_tip() -> String:
	for qid in ContentDB.ACTIVE_QUEST_ORDER:
		if qid in quests_done:
			continue
		var q: Dictionary = ContentDB.QUESTS.get(qid, {})
		if q.is_empty():
			continue
		if has_flag(str(q.flag)):
			continue
		var steps: Array = q.get("steps", [])
		var step0 := str(steps[0]) if steps.size() > 0 else str(q.title)
		return "%s — %s" % [q.title, step0]
	return "The School is quiet. Explore. Rest. Measure."


func record_bestiary(foe_id: String, foe_name: String) -> void:
	if not bestiary.has(foe_id):
		bestiary[foe_id] = {"name": foe_name, "kills": 0}
		toast.emit("Bestiary: %s recorded." % foe_name)
	bestiary[foe_id]["kills"] = int(bestiary[foe_id].get("kills", 0)) + 1


func open_chest(key: String, loot: Array) -> bool:
	if key in chests_opened:
		return false
	chests_opened.append(key)
	secrets_found += 1
	for it in loot:
		add_item(str(it))
	toast.emit("Chest opened. Secrets found: %d" % secrets_found)
	return true


func chest_taken(key: String) -> bool:
	return key in chests_opened


func take_collectible(key: String, item_id: String, nice_name: String) -> bool:
	if key in collectibles:
		return false
	collectibles.append(key)
	secrets_found += 1
	if item_id == "star_spark":
		star_sparks += 1
		add_item("star_spark", 1)
		toast.emit("✧ Star Spark! (%d/3+) — %s" % [star_sparks, nice_name])
	else:
		add_item(item_id, 1)
		toast.emit("Secret: %s" % nice_name)
	return true


func count_item(id: String) -> int:
	return int(inventory.get(id, 0))


func heal_full() -> void:
	hp = max_hp
	hp_changed.emit()
	companion_line = "Rest is rest. I keep the fire."
	toast.emit("Shrine — Will restored. Nothing wilts for resting.")


func record_hall_win() -> void:
	hall_wins += 1
	if hall_wins >= 3 and not has_flag("hall_cleared"):
		set_flag("hall_cleared", true)
		toast.emit("East Wing unsealed — Albedo opens.")


func _check_quests() -> void:
	for qid in ContentDB.QUESTS.keys():
		if qid in quests_done:
			continue
		var q: Dictionary = ContentDB.QUESTS[qid]
		if has_flag(str(q.flag)):
			quests_done.append(qid)
			add_xp(int(q.xp))
			for it in q.get("items", []):
				add_item(str(it))
			toast.emit("Quest complete: %s" % q.title)
			quest_updated.emit()


func save_game() -> void:
	var data := {
		"archetype": archetype,
		"player_name": player_name,
		"level": level,
		"xp": xp,
		"xp_next": xp_next,
		"hp": hp,
		"max_hp": max_hp,
		"insight": insight,
		"will_stat": will_stat,
		"luck": luck,
		"move_speed": move_speed,
		"bonus": bonus,
		"area_id": area_id,
		"pos": [pos.x, pos.y],
		"inventory": inventory,
		"relics": relics,
		"flags": flags,
		"hall_wins": hall_wins,
		"quests_done": quests_done,
		"companion_line": companion_line,
		"bestiary": bestiary,
		"secrets_found": secrets_found,
		"chests_opened": chests_opened,
		"star_sparks": star_sparks,
		"collectibles": collectibles,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		toast.emit("Game saved.")


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	archetype = str(data.get("archetype", "ALCHEMIST"))
	player_name = str(data.get("player_name", "Seeker"))
	level = int(data.get("level", 1))
	xp = int(data.get("xp", 0))
	xp_next = int(data.get("xp_next", 50))
	hp = int(data.get("hp", 36))
	max_hp = int(data.get("max_hp", 36))
	insight = int(data.get("insight", 10))
	will_stat = int(data.get("will_stat", 8))
	luck = int(data.get("luck", 5))
	move_speed = float(data.get("move_speed", 110))
	bonus = str(data.get("bonus", ""))
	area_id = str(data.get("area_id", "sanctum"))
	var p = data.get("pos", [352, 640])
	pos = Vector2(float(p[0]), float(p[1]))
	inventory = data.get("inventory", {})
	relics.assign(data.get("relics", []))
	flags = data.get("flags", {})
	hall_wins = int(data.get("hall_wins", 0))
	quests_done.assign(data.get("quests_done", []))
	companion_line = str(data.get("companion_line", ContentDB.COMPANION_LINES[0]))
	bestiary = data.get("bestiary", {})
	secrets_found = int(data.get("secrets_found", 0))
	chests_opened.assign(data.get("chests_opened", []))
	star_sparks = int(data.get("star_sparks", 0))
	collectibles.assign(data.get("collectibles", []))
	flags_changed.emit()
	inventory_changed.emit()
	hp_changed.emit()
	toast.emit("Game loaded.")
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
