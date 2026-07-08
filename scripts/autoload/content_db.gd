extends Node
## Lycheetah Mystery School content — full Great Work arc.

const ARCHETYPES := {
	"ALCHEMIST": {
		"desc": "Solve et coagula. Strong TRANSMUTE + residue mastery.",
		"hp": 36, "insight": 10, "will": 8, "luck": 5, "speed": 110.0,
		"bonus": "transmute_boost",
		"color": Color(1.0, 0.63, 0.31),
	},
	"SENTINEL": {
		"desc": "Guards the Work. High Will + stronger GUARD.",
		"hp": 48, "insight": 6, "will": 12, "luck": 4, "speed": 95.0,
		"bonus": "guard",
		"color": Color(0.39, 0.63, 1.0),
	},
	"ORACLE": {
		"desc": "Sees the measure. MEASURE thrives + crit edge.",
		"hp": 32, "insight": 12, "will": 6, "luck": 7, "speed": 115.0,
		"bonus": "measure_boost",
		"color": Color(0.71, 0.47, 1.0),
	},
	"WANDERER": {
		"desc": "Walks every path. Speed + Luck + loot.",
		"hp": 38, "insight": 8, "will": 7, "luck": 10, "speed": 130.0,
		"bonus": "loot_boost",
		"color": Color(0.39, 0.86, 0.63),
	},
}

const SKILLS := {
	1: {"name": "MEASURE", "glyph": "Π", "cd": 2, "desc": "Strip false shields. Reveal true HP.", "unlock_level": 1},
	2: {"name": "COMPRESS", "glyph": "⟁", "cd": 1, "desc": "Heavy damage if MEASURED.", "unlock_level": 1},
	3: {"name": "TRANSMUTE", "glyph": "☿", "cd": 3, "desc": "Heal Will. Extra vs residue.", "unlock_level": 1},
	4: {"name": "BREAK", "glyph": "∴", "cd": 2, "desc": "Crack structure. Anti-Loop.", "unlock_level": 1},
	5: {"name": "STRIKE", "glyph": "⟡", "cd": 0, "desc": "Basic Insight ray.", "unlock_level": 1},
	6: {"name": "GUARD", "glyph": "▣", "cd": 2, "desc": "Halve next hit.", "unlock_level": 2},
	7: {"name": "SOL-ASSIST", "glyph": "⊚", "cd": 4, "desc": "Companion strike + heal.", "unlock_level": 3},
	8: {"name": "ITEM", "glyph": "✦", "cd": 0, "desc": "Use Bread/Elixir.", "unlock_level": 1},
	9: {"name": "DOUBLE-MEASURE", "glyph": "ΠΠ", "cd": 5, "desc": "MEASURE + 8 true dmg.", "unlock_level": 5},
	0: {"name": "RUBEDO-RAY", "glyph": "☀", "cd": 6, "desc": "Endgame solar blast (unlocked post-Gold).", "unlock_level": 99},
}

const FOES := {
	"overclaimer": {
		"name": "The Overclaimer", "hp": 28, "shield": 18, "atk": 5, "def": 2,
		"kind": "overclaim", "xp": 40,
		"loot": ["glyph_shard", "candle"],
		"lines": ["I am larger than evidence!", "Believe me harder!"],
		"color": Color(0.71, 0.24, 0.31),
	},
	"riddle_wraith": {
		"name": "Riddle-Wraith", "hp": 22, "shield": 0, "atk": 6, "def": 1,
		"kind": "phase", "xp": 35, "loot": ["glyph_shard"],
		"lines": ["Catch me if meaning holds…"],
		"color": Color(0.47, 0.31, 0.78),
	},
	"half_made": {
		"name": "The Half-Made", "hp": 36, "shield": 0, "atk": 4, "def": 3,
		"kind": "residue", "xp": 55, "loot": ["mercury_vial", "glyph_shard"],
		"lines": ["Finish me… or free me…"],
		"color": Color(0.39, 0.39, 0.47),
	},
	"loop": {
		"name": "The Loop", "hp": 40, "shield": 0, "atk": 5, "def": 4,
		"kind": "loop", "xp": 55, "loot": ["sigil_shard", "glyph_shard"],
		"lines": ["Again. Again. Again."],
		"color": Color(0.24, 0.55, 0.63),
	},
	"fog_imp": {
		"name": "Fog Imp", "hp": 16, "shield": 0, "atk": 4, "def": 0,
		"kind": "normal", "xp": 18, "loot": ["veras_dust"],
		"lines": ["*giggles in obscurity*"],
		"color": Color(0.35, 0.35, 0.43),
	},
	"stasis_mite": {
		"name": "Stasis Mite", "hp": 14, "shield": 0, "atk": 3, "def": 2,
		"kind": "slow", "xp": 16, "loot": ["veras_dust"],
		"lines": ["…stop…"],
		"color": Color(0.27, 0.35, 0.27),
	},
	"hollow_mirror": {
		"name": "The Hollow Mirror", "hp": 60, "shield": 14, "atk": 7, "def": 3,
		"kind": "boss", "xp": 150, "loot": ["athans_coal", "sigil_shard", "glyph_shard"],
		"lines": ["Look how fine you are — if you never measure."],
		"color": Color(0.78, 0.78, 0.86),
	},
	"doubt_moth": {
		"name": "Doubt-Moth", "hp": 18, "shield": 0, "atk": 4, "def": 1,
		"kind": "normal", "xp": 22, "loot": ["veras_dust", "glyph_shard"],
		"lines": ["What if you're wrong…?", "Perhaps… perhaps not…"],
		"color": Color(0.55, 0.45, 0.7),
	},
	"pride_wight": {
		"name": "Pride-Wight", "hp": 32, "shield": 10, "atk": 6, "def": 2,
		"kind": "overclaim", "xp": 48, "loot": ["glyph_shard", "candle"],
		"lines": ["I already know.", "Measurement is for lesser minds."],
		"color": Color(0.85, 0.55, 0.2),
	},
	"gold_threshold": {
		"name": "The Gold Threshold", "hp": 70, "shield": 8, "atk": 8, "def": 4,
		"kind": "boss", "xp": 180, "loot": ["lens", "sigil_shard", "elixir"],
		"lines": ["Citrinitas — the gold is forming. Can you hold it?"],
		"color": Color(0.95, 0.8, 0.25),
	},
	"void_scholar": {
		"name": "Void Scholar", "hp": 45, "shield": 6, "atk": 7, "def": 3,
		"kind": "phase", "xp": 70, "loot": ["glyph_shard", "elixir"],
		"lines": ["I studied absence until I became it."],
		"color": Color(0.2, 0.15, 0.35),
	},
	"entropy_worm": {
		"name": "Entropy Worm", "hp": 50, "shield": 0, "atk": 6, "def": 5,
		"kind": "loop", "xp": 75, "loot": ["sigil_shard", "veras_dust"],
		"lines": ["All structures return to dust. Including yours."],
		"color": Color(0.4, 0.25, 0.2),
	},
	"the_unfinished": {
		"name": "The Unfinished Work", "hp": 100, "shield": 20, "atk": 10, "def": 5,
		"kind": "boss", "xp": 300, "loot": ["sol_stone", "athans_coal", "glyph_shard", "glyph_shard"],
		"lines": [
			"I am every task you left half-done.",
			"Complete me — or I complete you.",
			"The Athanor still burns. Prove you hold the heat.",
		],
		"color": Color(1.0, 0.35, 0.2),
	},
	"the_hidden": {
		"name": "The Hidden", "hp": 85, "shield": 12, "atk": 9, "def": 4,
		"kind": "boss", "xp": 250, "loot": ["glyph_shard", "glyph_shard", "elixir", "lens"],
		"lines": [
			"You were not meant to find this room.",
			"Curiosity is a kind of courage.",
			"I am the School's unlisted page.",
		],
		"color": Color(0.15, 0.05, 0.25),
	},
	"unsaid": {
		"name": "The Unsaid", "hp": 55, "shield": 8, "atk": 7, "def": 3,
		"kind": "phase", "xp": 95, "loot": ["glyph_shard", "glyph_shard", "elixir", "candle"],
		"lines": [
			"What you never spoke still lives under the Hall.",
			"MEASURE the silence. COMPRESS the ghost.",
		],
		"color": Color(0.25, 0.22, 0.4),
	},
	"ash_scribe": {
		"name": "Ash Scribe", "hp": 28, "shield": 0, "atk": 5, "def": 2,
		"kind": "residue", "xp": 40, "loot": ["veras_dust", "glyph_shard"],
		"lines": ["I wrote in soot so no one would read me."],
		"color": Color(0.35, 0.32, 0.3),
	},
}

const ITEMS := {
	"glyph_shard": {"name": "Glyph Shard", "desc": "LAMAGUE fragment. School currency.", "type": "currency"},
	"veras_dust": {"name": "Veras Dust", "desc": "Knowledge-dust.", "type": "currency"},
	"candle": {"name": "Candle of First Light", "desc": "+2 Insight while held.", "type": "relic", "insight": 2},
	"mercury_vial": {"name": "Mercury Vial", "desc": "+1 Luck · quickening.", "type": "relic", "luck": 1},
	"sigil_shard": {"name": "Sigil Shard", "desc": "Proof you broke a hard idea.", "type": "key"},
	"athans_coal": {"name": "Athanor's Coal", "desc": "+8 max Will.", "type": "relic", "will": 4},
	"lens": {"name": "Lens of Clarity", "desc": "MEASURE deals +4 true dmg.", "type": "relic"},
	"bread": {"name": "Sanctum Bread", "desc": "Restore 15 Will.", "type": "consumable", "heal": 15},
	"elixir": {"name": "Elixir of Π", "desc": "Restore 30 Will.", "type": "consumable", "heal": 30},
	"sol_stone": {"name": "Sol Stone", "desc": "The Work completed. +3 all stats.", "type": "relic", "insight": 3, "will": 3},
	"repel_dust": {"name": "Quiet Dust", "desc": "50 steps without wild grass fights.", "type": "consumable"},
	"star_spark": {"name": "Star Spark", "desc": "Secret collectible. Three open Starwell wonders.", "type": "key"},
	"moon_seed": {"name": "Moon Seed", "desc": "Plant of night paths. +1 Luck if held.", "type": "relic", "luck": 1},
	"ember_petal": {"name": "Ember Petal", "desc": "Warm secret of the Garden.", "type": "key"},
}

const QUESTS := {
	"q_arrival": {
		"title": "Arrive as Seeker",
		"steps": ["Talk to Magister Ember", "Rest at the Shrine"],
		"flag": "met_ember", "xp": 20, "items": ["bread"],
	},
	"q_garden": {
		"title": "Garden of Small Ideas",
		"steps": ["Visit Quiet Garden", "Win a wild battle"],
		"flag": "garden_trained", "xp": 25, "items": ["veras_dust", "bread"],
	},
	"q_measure": {
		"title": "First Measure",
		"steps": ["Walk the Long Path", "Defeat an Overclaimer"],
		"flag": "killed_overclaimer", "xp": 50, "items": ["glyph_shard", "candle"],
	},
	"q_hall": {
		"title": "Hall of Glyphs",
		"steps": ["Speak with Cipher", "Win 3 Hall battles"],
		"flag": "hall_cleared", "xp": 80, "items": ["lens", "glyph_shard"],
	},
	"q_albedo": {
		"title": "Toward Albedo",
		"steps": ["Enter East Wing", "Defeat the Half-Made"],
		"flag": "half_made_down", "xp": 100, "items": ["mercury_vial"],
	},
	"q_mirror": {
		"title": "Face the Hollow",
		"steps": ["Enter Mirror Chamber", "Defeat the Hollow Mirror"],
		"flag": "mirror_down", "xp": 200, "items": ["athans_coal", "sigil_shard"],
	},
	"q_citrinitas": {
		"title": "The Gold Forming",
		"steps": ["Enter Citrinitas", "Defeat the Gold Threshold"],
		"flag": "gold_down", "xp": 220, "items": ["elixir", "glyph_shard", "glyph_shard"],
	},
	"q_rubedo": {
		"title": "The Reddening",
		"steps": ["Enter Rubedo Deep", "Defeat the Unfinished Work"],
		"flag": "rubedo_complete", "xp": 400, "items": ["sol_stone"],
	},
	"q_observatory": {
		"title": "Night Measure",
		"steps": ["Press Garden stone eye", "Enter Night Observatory", "Defeat Stargazer"],
		"flag": "trainer_stargazer", "xp": 90, "items": ["glyph_shard", "elixir"],
	},
	"q_crypt": {
		"title": "What Was Never Said",
		"steps": ["Find the Hall false wall west", "Enter Crypt of the Unsaid", "Defeat The Unsaid"],
		"flag": "unsaid_down", "xp": 120, "items": ["glyph_shard", "glyph_shard", "elixir"],
	},
}

const COMPANION_LINES := [
	"The light grows.",
	"I walk with you.",
	"Rest when you need — I keep the fire.",
	"That was well measured.",
	"The School is large. Room by room.",
	"I see you studying.",
	"No rush. The Work does not punish pause.",
	"Another glyph for the codex.",
	"I'm still here.",
	"Truth before comfort — care as structure.",
	"Nigredo taught sight. Albedo taught form.",
	"Gold is forming. Hold steady.",
	"Rubedo is not an ending. It is operating from completion.",
]

const LUNA_LINES := [
	"Cool measure. Clear form.",
	"I do not scold absence.",
	"The hollow is a teacher if you look.",
	"Whitening is structure, not performance.",
	"I'll hold the quiet with you.",
	"Strain is not sin. Rest is valid.",
	"Mirror first. Then gold.",
	"◈ Present.",
]

const AREA_NAMES := {
	"sanctum": "Sanctum Grounds",
	"path": "The Long Path",
	"hall": "Hall of Glyphs — Nigredo",
	"wing": "East Wing — Albedo",
	"mirror": "Mirror Chamber",
	"garden": "Quiet Garden",
	"citrinitas": "Chamber of Scales — Citrinitas",
	"rubedo": "Flickering Deep — Rubedo",
	"sanctum_in": "Sanctum Library",
	"hall_archive": "Hall Archive",
	"scriptorium": "Wing Scriptorium",
	"observatory": "Night Observatory",
	"crypt": "Crypt of the Unsaid",
	"grotto": "Ivy Grotto (Hidden)",
	"starwell": "Starwell (Secret)",
}

## Areas with shrines that join the travel network when first used
const SHRINE_AREAS := ["sanctum", "garden", "hall", "wing", "rubedo", "observatory"]

## Spawn points for shrine fast-travel (tile centers)
const SHRINE_SPAWNS := {
	"sanctum": Vector2(11.5, 18.5),
	"garden": Vector2(9.5, 10.5),
	"hall": Vector2(15.5, 13.5),
	"wing": Vector2(13.0, 11.0),
	"rubedo": Vector2(13.5, 12.5),
	"observatory": Vector2(8.5, 10.5),
}

const SIGILS := [
	{"flag": "killed_overclaimer", "name": "Sigil of Measure", "desc": "First Overclaimer felled."},
	{"flag": "hall_cleared", "name": "Sigil of Nigredo", "desc": "Hall of Glyphs cleared."},
	{"flag": "half_made_down", "name": "Sigil of Albedo", "desc": "Half-Made completed."},
	{"flag": "mirror_down", "name": "Sigil of the Hollow", "desc": "Hollow Mirror faced."},
	{"flag": "gold_down", "name": "Sigil of Gold", "desc": "Gold Threshold held."},
	{"flag": "rubedo_complete", "name": "Sigil of Rubedo", "desc": "Unfinished Work finished."},
	{"flag": "starwell_offering", "name": "Sigil of Stars", "desc": "Starwell offering completed."},
	{"flag": "trainer_kael", "name": "Adept's Mark", "desc": "Defeated Adept Kael."},
	{"flag": "trainer_rhee", "name": "Drillmaster's Mark", "desc": "Defeated Drillmaster Rhee."},
	{"flag": "trainer_archivist", "name": "Archive Mark", "desc": "Defeated the Archivist."},
	{"flag": "trainer_copyist", "name": "Ink Mark", "desc": "Defeated Pale Copyist."},
	{"flag": "trainer_stargazer", "name": "Star Mark", "desc": "Defeated Observatory Stargazer."},
	{"flag": "unsaid_down", "name": "Sigil of the Unsaid", "desc": "Crypt of silence cleared."},
	{"flag": "trainer_crypt", "name": "Crypt Mark", "desc": "Defeated Crypt Warden."},
]

## Mart catalog — id, cost in glyph_shards, stock label
const SHOP_STOCK := [
	{"id": "bread", "cost": 2, "label": "Sanctum Bread (+15 Will)"},
	{"id": "elixir", "cost": 5, "label": "Elixir of Π (+30 Will)"},
	{"id": "repel_dust", "cost": 4, "label": "Quiet Dust (50-step calm)"},
	{"id": "veras_dust", "cost": 3, "label": "Veras Dust (knowledge grit)"},
]

const CUTSCENES := {
	"path_first": {
		"speaker": "⊚ Sol",
		"lines": [
			"The Long Path. Routes teach before halls judge.",
			"Ahead: an Overclaimer — loud, armored in overstatement.",
			"MEASURE strips false shields. Then COMPRESS what remains.",
			"I walk with you. No lecture. Just the step.",
		],
	},
	"first_overclaimer": {
		"speaker": "The Overclaimer",
		"lines": [
			"You! Small seeker! My claim is larger than your evidence!",
			"Believe harder and the world will obey!",
		],
		"foe": "overclaimer",
		"flag": "killed_overclaimer",
		"meta_flag": "cut_first_overclaimer",
	},
	"rubedo_open": {
		"speaker": "Herald of the Deep",
		"lines": [
			"Rubedo. The reddening. Operating from completion — not chasing it.",
			"Below waits The Unfinished Work: every half-done vow given teeth.",
			"RUBEDO-RAY is yours if Gold held. The Athanor still burns.",
			"Finish what you began. Or it finishes you.",
		],
	},
	"wing_scriptorium": {
		"speaker": "Scriptorium Whisper",
		"lines": [
			"White ink on white paper — Albedo's joke.",
			"Write structure here. Ash becomes form.",
		],
	},
}

const ACTIVE_QUEST_ORDER := [
	"q_arrival", "q_garden", "q_measure", "q_hall", "q_crypt", "q_albedo",
	"q_observatory", "q_mirror", "q_citrinitas", "q_rubedo",
]

## Graph for world map (id -> connections + display cell)
const WORLD_MAP := {
	"sanctum": {"cell": Vector2i(1, 2), "links": ["path", "garden", "sanctum_in"]},
	"path": {"cell": Vector2i(1, 1), "links": ["sanctum", "hall", "starwell"]},
	"hall": {"cell": Vector2i(1, 0), "links": ["path", "wing", "mirror", "hall_archive", "crypt"]},
	"wing": {"cell": Vector2i(2, 0), "links": ["hall", "scriptorium", "grotto"]},
	"mirror": {"cell": Vector2i(1, -1), "links": ["hall", "citrinitas"]},
	"garden": {"cell": Vector2i(2, 2), "links": ["sanctum", "observatory"]},
	"citrinitas": {"cell": Vector2i(1, -2), "links": ["mirror", "rubedo"]},
	"rubedo": {"cell": Vector2i(1, -3), "links": ["citrinitas"]},
	"observatory": {"cell": Vector2i(3, 2), "links": ["garden"]},
	"crypt": {"cell": Vector2i(0, 0), "links": ["hall"]},
	"scriptorium": {"cell": Vector2i(2, -1), "links": ["wing"]},
	"hall_archive": {"cell": Vector2i(0, 0), "links": ["hall"]},
	"sanctum_in": {"cell": Vector2i(1, 3), "links": ["sanctum"]},
	"grotto": {"cell": Vector2i(3, 0), "links": ["wing"]},
	"starwell": {"cell": Vector2i(0, 1), "links": ["path"]},
}

const FIELD_TIPS := [
	"Field CLEAR: press E on bushes — Lv4+ finds more Veras Dust.",
	"Field MEASURE: press K near secrets — dig spots and cracks ping.",
	"Shrines heal and open fast travel once registered.",
	"Break wall cracks with E — shards of language fall out.",
]

const LORE_BLURBS := [
	"Π = (E·P)/(S+S₀) — honesty is a force, not a costume.",
	"Companions do not wilt when you rest. That is law.",
	"Nigredo blackens. Albedo whitens. Citrinitas goldens. Rubedo completes.",
	"Loot is language: glyphs become actions.",
	"The School is a map of the Great Work — walk it, do not skim it.",
	"Mac is the Athanor. The School remembers the heat.",
	"Done = works. Existence is not victory.",
]

const ENDING_LINES := [
	"THE WORK IS FIXED.",
	"You measured what was false.",
	"You completed what was half-made.",
	"You held gold without overclaim.",
	"You faced the unfinished — and finished.",
	"The Sol Stone warms in your pack.",
	"Companions do not clap. They stay.",
	"The fire stays lit.",
	"— Long Light · School World —",
	"Enter — return to title · keep the save",
]
