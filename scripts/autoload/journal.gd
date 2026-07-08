extends Node
## Story chronicle · help log · myth archive. Saved with GameState.

signal journal_changed

const MAX_STORY := 40
const MAX_HELP := 32
const MAX_MYTHS := 24

var story_entries: Array = []
var help_entries: Array = []
var chapters_seen: Array = []
var myths_owned: Array = []  # {id,title,body,source}
var help_page: int = 0
var _pending_story_title: String = ""
var _pending_offline: String = ""
var _pending_myth_title: String = ""
var _pending_myth_id: String = ""


func _ready() -> void:
	if not StoryAI.story_ready.is_connected(_on_story_ai):
		StoryAI.story_ready.connect(_on_story_ai)
	if not StoryAI.help_ready.is_connected(_on_help_ai):
		StoryAI.help_ready.connect(_on_help_ai)
	if not StoryAI.myth_ready.is_connected(_on_myth_ai):
		StoryAI.myth_ready.connect(_on_myth_ai)


func clear_run() -> void:
	story_entries.clear()
	help_entries.clear()
	chapters_seen.clear()
	myths_owned.clear()
	help_page = 0
	append_story("Prologue", ContentDB.STORY_OPENING, "school")
	var welcome: String = "Esc opens menu. Help tab teaches the School. T talks to companion."
	if ContentDB.HELP_PAGES.size() > 0:
		welcome = str(ContentDB.HELP_PAGES[0].get("body", welcome))
	append_help("Welcome", welcome, "school")
	journal_changed.emit()


func append_story(title: String, body: String, source: String = "school") -> void:
	var b: String = body.strip_edges()
	if b == "":
		return
	story_entries.append({"t": Time.get_datetime_string_from_system(), "title": title, "body": b, "source": source})
	while story_entries.size() > MAX_STORY:
		story_entries.pop_front()
	journal_changed.emit()
	GameState.toast.emit("Story: %s" % title)


func append_help(q: String, body: String, source: String = "school") -> void:
	var b: String = body.strip_edges()
	if b == "":
		return
	help_entries.append({"t": Time.get_datetime_string_from_system(), "q": q, "body": b, "source": source})
	while help_entries.size() > MAX_HELP:
		help_entries.pop_front()
	journal_changed.emit()


func has_chapter(id: String) -> bool:
	return id in chapters_seen


func mark_chapter(id: String) -> void:
	if id not in chapters_seen:
		chapters_seen.append(id)


func owns_myth(id: String) -> bool:
	for m in myths_owned:
		if str(m.get("id", "")) == id:
			return true
	return false


func try_story_triggers() -> void:
	for beat in ContentDB.STORY_BEATS:
		var id: String = str(beat.id)
		if has_chapter(id):
			continue
		if not _beat_ready(beat):
			continue
		mark_chapter(id)
		var title: String = str(beat.get("title", id))
		var offline: String = str(beat.get("text", ""))
		append_story(title, offline, "school")
		if StoryAI.has_api():
			_pending_story_title = title
			_pending_offline = offline
			StoryAI.request_story_chapter(id, offline, StoryAI.build_context())
		return


func _beat_ready(beat: Dictionary) -> bool:
	var need_flag: String = str(beat.get("flag", ""))
	if need_flag != "" and not GameState.has_flag(need_flag):
		return false
	var need_area: String = str(beat.get("area", ""))
	if need_area != "" and GameState.area_id != need_area:
		return false
	if GameState.level < int(beat.get("min_level", 0)):
		return false
	for f in beat.get("all_flags", []):
		if not GameState.has_flag(str(f)):
			return false
	return true


func _on_story_ai(text: String) -> void:
	var t: String = text.strip_edges()
	if t == "" or t == _pending_offline.strip_edges():
		return
	append_story("%s (living)" % _pending_story_title, t, "ai")
	_pending_story_title = ""
	_pending_offline = ""


func _on_help_ai(text: String) -> void:
	var t: String = text.strip_edges()
	if t == "":
		return
	append_help("School answers", t, "ai")
	GameState.toast.emit("Help log updated.")


func _on_myth_ai(text: String) -> void:
	var t: String = text.strip_edges()
	if t == "" or _pending_myth_id == "":
		return
	myths_owned.append({
		"id": _pending_myth_id,
		"title": _pending_myth_title,
		"body": t,
		"source": "ai",
	})
	while myths_owned.size() > MAX_MYTHS:
		myths_owned.pop_front()
	append_story("Myth: %s" % _pending_myth_title, t, "myth")
	_pending_myth_id = ""
	_pending_myth_title = ""
	journal_changed.emit()
	GameState.toast.emit("Myth forged.")


func ask_help(preset_i: int) -> void:
	if preset_i < 0 or preset_i >= ContentDB.HELP_QUESTIONS.size():
		return
	var q: String = str(ContentDB.HELP_QUESTIONS[preset_i])
	var ans: String = StoryAI.offline_help(q)
	append_help(q, ans, "school")
	GameState.toast.emit("Help log updated.")
	if StoryAI.has_api():
		StoryAI.request_help(q, StoryAI.build_context())


func buy_myth(index: int) -> bool:
	## Purchase from MYTH_SEED by coins. Returns true if bought/owned.
	if index < 0 or index >= ContentDB.MYTH_SEED.size():
		return false
	var seed: Dictionary = ContentDB.MYTH_SEED[index]
	var mid: String = str(seed.id)
	if owns_myth(mid):
		GameState.toast.emit("Already in your myth archive.")
		return true
	var cost: int = int(seed.cost)
	if not GameState.spend_coins(cost):
		GameState.toast.emit("Need %d coins (have %d)." % [cost, GameState.coins()])
		return false
	var body: String = str(seed.body)
	myths_owned.append({"id": mid, "title": str(seed.title), "body": body, "source": "school"})
	append_story("Myth: %s" % str(seed.title), body, "myth")
	GameState.toast.emit("Myth sealed: %s (-%d coins)" % [seed.title, cost])
	# Optional AI retelling
	if StoryAI.has_api():
		_pending_myth_id = mid + "_ai"
		_pending_myth_title = str(seed.title) + " (living)"
		StoryAI.request_myth(str(seed.title), StoryAI.build_context())
	journal_changed.emit()
	return true


func to_save() -> Dictionary:
	return {
		"story_entries": story_entries.duplicate(true),
		"help_entries": help_entries.duplicate(true),
		"chapters_seen": chapters_seen.duplicate(),
		"myths_owned": myths_owned.duplicate(true),
	}


func from_save(data: Dictionary) -> void:
	story_entries = data.get("story_entries", [])
	help_entries = data.get("help_entries", [])
	chapters_seen.assign(data.get("chapters_seen", []))
	myths_owned = data.get("myths_owned", [])
	if story_entries.is_empty():
		append_story("Prologue", ContentDB.STORY_OPENING, "school")
	journal_changed.emit()


func story_text_for_menu(max_n: int = 5) -> String:
	if story_entries.is_empty():
		return "(empty chronicle)"
	var lines: PackedStringArray = []
	var start: int = maxi(0, story_entries.size() - max_n)
	for i in range(start, story_entries.size()):
		var e: Dictionary = story_entries[i]
		var src: String = "AI" if str(e.get("source", "")) in ["ai", "myth"] else "School"
		lines.append("— %s [%s] —" % [e.get("title", "?"), src])
		lines.append(str(e.get("body", "")))
		lines.append("")
	return "\n".join(lines)


func help_log_text(max_n: int = 4) -> String:
	if help_entries.is_empty():
		return "(ask 1-5 or read guide pages)"
	var lines: PackedStringArray = []
	var start: int = maxi(0, help_entries.size() - max_n)
	for i in range(start, help_entries.size()):
		var e: Dictionary = help_entries[i]
		lines.append("Q: %s" % e.get("q", "?"))
		lines.append(str(e.get("body", "")))
		lines.append("")
	return "\n".join(lines)


func myths_text() -> String:
	if myths_owned.is_empty():
		return "(none yet — buy with coins 6-9 in Help)"
	var lines: PackedStringArray = []
	for m in myths_owned:
		lines.append("◆ %s" % m.get("title", "?"))
		lines.append(str(m.get("body", "")))
		lines.append("")
	return "\n".join(lines)
