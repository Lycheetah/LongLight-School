extends RefCounted
## Pure combat resolution — skills, status, companion assist, crits.
## Battle UI calls these; no Node dependencies.

const SKILL_META := {
	1: {"name": "MEASURE", "glyph": "Π", "cd": 2},
	2: {"name": "COMPRESS", "glyph": "⟁", "cd": 1},
	3: {"name": "TRANSMUTE", "glyph": "☿", "cd": 3},
	4: {"name": "BREAK", "glyph": "∴", "cd": 2},
	5: {"name": "STRIKE", "glyph": "⟡", "cd": 0},
	6: {"name": "GUARD", "glyph": "▣", "cd": 2},
	7: {"name": "SOL-ASSIST", "glyph": "⊚", "cd": 4},
	8: {"name": "ITEM", "glyph": "✦", "cd": 0},
}


static func dmg(base: int, power: int, defense: int, mult: float, crit: bool = false) -> int:
	var raw: float = (base + power) * mult - defense * 0.45
	var v: int = maxi(1, int(raw) + randi_range(0, 2))
	if crit:
		v = int(v * 1.6) + 1
	return v


static func roll_crit(luck: int) -> bool:
	return randf() < clampf(0.06 + luck * 0.012, 0.06, 0.35)


## Apply player skill. Mutates battle dict + stats dict. Returns log lines.
## battle keys: foe_hp, foe_max, foe_shield, foe_atk, foe_def, kind, measured, phased,
##   broken_turns, strain, guarded, cd{}, done, won, lines, foe_name, assist_used
static func player_act(battle: Dictionary, stats: Dictionary, skill: int, inventory: Dictionary) -> PackedStringArray:
	var logs: PackedStringArray = []
	if bool(battle.get("done", false)) or str(battle.get("turn", "")) != "player":
		return logs
	var cd: Dictionary = battle.get("cd", {})
	if int(cd.get(skill, 0)) > 0 and skill != 8:
		logs.append("Skill cooling…")
		return logs

	var insight: int = int(stats.get("insight", 8))
	var will: int = int(stats.get("will", 6))
	var luck: int = int(stats.get("luck", 4))
	var bonus: String = str(stats.get("bonus", ""))
	var relics: Array = stats.get("relics", [])
	var has_lens: bool = "lens" in relics
	var kind: String = str(battle.get("kind", "normal"))
	var crit := roll_crit(luck)

	# phase dodge
	if bool(battle.get("phased", false)) and skill not in [1, 4, 6, 7, 8]:
		battle["phased"] = false
		logs.append("Your strike passes through mist!")
		battle["turn"] = "foe"
		return logs

	match skill:
		1: # MEASURE
			battle["measured"] = true
			var stripped: int = int(battle.get("foe_shield", 0))
			battle["foe_shield"] = 0
			cd[1] = 1 if bonus == "measure_boost" else 2
			logs.append("Π MEASURE — false shield (%d) collapses." % stripped)
			logs.append("True form: %d HP." % int(battle.foe_hp))
			if has_lens:
				battle.foe_hp = maxi(0, int(battle.foe_hp) - 4)
				logs.append("Lens of Clarity burns 4 true damage.")
			if kind == "phase":
				battle["phased"] = false
				logs.append("The Wraith solidifies under measure.")
			# reveal weakness text
			logs.append(_weakness_hint(kind))
		2: # COMPRESS
			var mult := 1.75 if bool(battle.measured) else 0.65
			if kind == "phase" and bool(battle.measured):
				mult += 0.25
			var d: int = dmg(6, insight, int(battle.foe_def), mult, crit)
			battle.foe_hp = maxi(0, int(battle.foe_hp) - d)
			cd[2] = 1
			logs.append("⟁ COMPRESS — %d%s%s" % [
				d,
				" CRIT!" if crit else "",
				" (measured)" if bool(battle.measured) else " (unmeasured)"
			])
		3: # TRANSMUTE
			var heal: int = will + 4 + (5 if bonus == "transmute_boost" else 0)
			if kind == "residue":
				heal += 4
				var d2: int = dmg(5, insight, int(battle.foe_def), 1.1, crit)
				battle.foe_hp = maxi(0, int(battle.foe_hp) - d2)
				logs.append("☿ TRANSMUTE completes residue — %d dmg + heal %d." % [d2, heal])
			else:
				logs.append("☿ TRANSMUTE — restore %d Will." % heal)
			stats.hp = mini(int(stats.max_hp), int(stats.hp) + heal)
			# cleanse strain
			battle["strain"] = 0
			cd[3] = 2 if bonus == "transmute_boost" else 3
		4: # BREAK
			var mult4 := 1.9 if kind == "loop" else 1.15
			if int(battle.get("broken_turns", 0)) > 0:
				mult4 += 0.2
			var d4: int = dmg(5, luck + insight / 2, int(battle.foe_def), mult4, crit)
			battle.foe_hp = maxi(0, int(battle.foe_hp) - d4)
			battle["broken_turns"] = 2  # foe stunned-ish
			cd[4] = 2
			logs.append("∴ BREAK — %d%s%s" % [
				d4, " CRIT!" if crit else "",
				" (loop snapped!)" if kind == "loop" else " — structure cracks."
			])
			if kind == "phase":
				battle["phased"] = false
		5: # STRIKE
			if kind == "loop":
				battle.foe_hp = mini(int(battle.foe_max), int(battle.foe_hp) + 5)
				logs.append("⟡ STRIKE — The Loop feeds (+5)! Use BREAK.")
			elif int(battle.foe_shield) > 0:
				var d5: int = dmg(3, insight / 2, int(battle.foe_def), 1.0, crit)
				battle.foe_shield = maxi(0, int(battle.foe_shield) - d5)
				logs.append("⟡ STRIKE chips shield (%d). MEASURE it!" % d5)
			else:
				var d5b: int = dmg(4, insight / 2, int(battle.foe_def), 1.0, crit)
				battle.foe_hp = maxi(0, int(battle.foe_hp) - d5b)
				logs.append("⟡ STRIKE — %d%s" % [d5b, " CRIT!" if crit else ""])
			cd[5] = 0
		6: # GUARD
			battle["guarded"] = true
			cd[6] = 2 if bonus == "guard" else 3
			logs.append("▣ GUARD — next hit is halved. Sentinel breath.")
		7: # SOL ASSIST
			if bool(battle.get("assist_used", false)) and int(cd.get(7, 0)) > 0:
				logs.append("Sol is still gathering light…")
				return logs
			var ad: int = dmg(8, insight + will / 2, int(battle.foe_def), 1.3 if bool(battle.measured) else 1.0, true)
			battle.foe_hp = maxi(0, int(battle.foe_hp) - ad)
			var aheal: int = 6 + will / 2
			stats.hp = mini(int(stats.max_hp), int(stats.hp) + aheal)
			cd[7] = 4
			battle["assist_used"] = true
			logs.append("⊚ SOL ASSISTS — radiant ⟡ for %d dmg + heal %d." % [ad, aheal])
			logs.append("\"The light grows. I walk with you.\"")
		8: # ITEM bread priority
			if int(inventory.get("bread", 0)) > 0:
				inventory["bread"] = int(inventory.bread) - 1
				if inventory.bread <= 0:
					inventory.erase("bread")
				stats.hp = mini(int(stats.max_hp), int(stats.hp) + 15)
				logs.append("✦ Ate Sanctum Bread (+15 Will).")
			elif int(inventory.get("elixir", 0)) > 0:
				inventory["elixir"] = int(inventory.elixir) - 1
				if inventory.elixir <= 0:
					inventory.erase("elixir")
				stats.hp = mini(int(stats.max_hp), int(stats.hp) + 30)
				logs.append("✦ Drank Elixir of Π (+30 Will).")
			else:
				logs.append("No consumables. Carry bread from the Sanctum.")
				return logs
		9: # DOUBLE MEASURE (lv5+)
			if int(stats.get("level", 1)) < 5:
				logs.append("Double-Measure unlocks at Level 5.")
				return logs
			battle["measured"] = true
			var st2: int = int(battle.get("foe_shield", 0))
			battle["foe_shield"] = 0
			var d9: int = dmg(8, insight, int(battle.foe_def), 1.2, crit)
			battle.foe_hp = maxi(0, int(battle.foe_hp) - d9)
			cd[9] = 5
			logs.append("ΠΠ DOUBLE-MEASURE — shield (%d) gone + %d true." % [st2, d9])
		0: # RUBEDO RAY
			if not bool(stats.get("unlock_rubedo_ray", false)):
				logs.append("Rubedo-Ray unlocks after the Gold Threshold.")
				return logs
			var d0: int = dmg(14, insight + will, int(battle.foe_def), 1.5 if bool(battle.measured) else 1.1, true)
			battle.foe_hp = maxi(0, int(battle.foe_hp) - d0)
			battle["foe_shield"] = 0
			battle["measured"] = true
			cd[0] = 6
			logs.append("☀ RUBEDO-RAY — solar %d. The Work operates." % d0)
		_:
			logs.append("Unknown skill.")
			return logs

	battle["cd"] = cd
	battle["player_turns"] = int(battle.get("player_turns", 0)) + 1
	# win check
	if int(battle.foe_hp) <= 0 and int(battle.foe_shield) <= 0:
		battle["done"] = true
		battle["won"] = true
		logs.append("%s dissolves into light." % str(battle.foe_name))
		return logs

	# passive Sol assist every 4 player turns (party-system seed)
	if int(battle.get("player_turns", 0)) % 4 == 0 and int(cd.get(7, 0)) == 0 and skill != 7:
		var pad: int = dmg(3, insight / 3, int(battle.foe_def), 1.0, false)
		battle.foe_hp = maxi(0, int(battle.foe_hp) - pad)
		logs.append("⊚ Sol's passive light chips %d." % pad)
		if int(battle.foe_hp) <= 0 and int(battle.foe_shield) <= 0:
			battle["done"] = true
			battle["won"] = true
			logs.append("%s dissolves into light." % str(battle.foe_name))
			return logs

	battle["turn"] = "foe"
	return logs


static func foe_act(battle: Dictionary, stats: Dictionary) -> PackedStringArray:
	var logs: PackedStringArray = []
	if bool(battle.get("done", false)):
		return logs
	# tick CDs
	var cd: Dictionary = battle.get("cd", {})
	for k in cd.keys():
		cd[k] = maxi(0, int(cd[k]) - 1)
	battle["cd"] = cd

	# broken: skip aggressive action
	if int(battle.get("broken_turns", 0)) > 0:
		battle["broken_turns"] = int(battle.broken_turns) - 1
		logs.append("%s staggers — structure still cracked." % str(battle.foe_name))
		battle["turn"] = "player"
		return logs

	var kind: String = str(battle.get("kind", "normal"))
	var lines: Array = battle.get("lines", [])
	if lines.size() > 0 and randf() < 0.4:
		logs.append('"%s"' % str(lines[randi() % lines.size()]))

	if kind == "phase" and randf() < 0.4:
		battle["phased"] = true
		logs.append("%s phases into riddle-mist!" % str(battle.foe_name))

	var atk: int = int(battle.get("foe_atk", 5))
	var will: int = int(stats.get("will", 6))
	var bonus: String = str(stats.get("bonus", ""))
	var dmg_in: int

	if int(battle.get("foe_shield", 0)) > 0 and kind in ["overclaim", "boss"]:
		battle.foe_shield = mini(45, int(battle.foe_shield) + 2)
		dmg_in = maxi(2, atk - will / 4)
		logs.append("%s inflates the lie!" % str(battle.foe_name))
	elif kind == "loop" and randf() < 0.35:
		battle.foe_hp = mini(int(battle.foe_max), int(battle.foe_hp) + 6)
		dmg_in = maxi(2, atk - 1)
		logs.append("%s cycles and heals 6." % str(battle.foe_name))
	elif kind == "slow":
		dmg_in = maxi(1, atk - 1)
		battle["strain"] = int(battle.get("strain", 0)) + 1
		logs.append("%s bleeds stasis into you (strain %d)." % [str(battle.foe_name), int(battle.strain)])
	else:
		dmg_in = maxi(2, atk + randi_range(0, 3) - will / 5)

	if bonus == "guard":
		dmg_in = maxi(1, dmg_in - 2)
	if bool(battle.get("guarded", false)):
		dmg_in = maxi(1, dmg_in / 2)
		battle["guarded"] = false
		logs.append("▣ Guard absorbs half.")
	# strain amplifies next hits slightly
	dmg_in += int(battle.get("strain", 0))

	stats.hp = maxi(0, int(stats.hp) - dmg_in)
	logs.append("You take %d." % dmg_in)

	if int(stats.hp) <= 0:
		battle["done"] = true
		battle["won"] = false
		logs.append("You fall. The shrine will take you.")
	else:
		battle["turn"] = "player"
	return logs


static func _weakness_hint(kind: String) -> String:
	match kind:
		"overclaim", "boss":
			return "Codex: false shields die to MEASURE before damage."
		"phase":
			return "Codex: phase-beings solidify under MEASURE / BREAK."
		"loop":
			return "Codex: loops feed on STRIKE — BREAK the cycle."
		"residue":
			return "Codex: residue yields to TRANSMUTE."
		"slow":
			return "Codex: stasis builds strain — TRANSMUTE cleanses."
		_:
			return "Codex: every idea has a seam."
