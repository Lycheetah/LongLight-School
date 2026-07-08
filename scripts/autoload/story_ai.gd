extends Node
## Optional DeepSeek brain. Offline always works.
## Key: env DEEPSEEK_KEY | LONG_LIGHT_API_KEY | user://deepseek_key.txt | AZOTH .env

signal story_ready(text: String)
signal help_ready(text: String)
signal myth_ready(text: String)
signal status_changed(msg: String)

const API_URL := "https://api.deepseek.com/chat/completions"
const MODEL := "deepseek-chat"
const MAX_TOKENS := 260

var _http: HTTPRequest
var _key: String = ""
var _busy: bool = false
var _pending_kind: String = ""
var _enabled: bool = true


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 45.0
	add_child(_http)
	_http.request_completed.connect(_on_http_done)
	_key = _load_key()
	if _key.is_empty():
		status_changed.emit("AI offline — School texts only.")
	else:
		status_changed.emit("AI story brain ready.")


func has_key() -> bool:
	return not _key.is_empty() and _enabled


func has_api() -> bool:
	## Ready to accept a new request
	return has_key() and not _busy


func is_busy() -> bool:
	return _busy


func _load_key() -> String:
	var k: String = OS.get_environment("DEEPSEEK_KEY").strip_edges()
	if k.is_empty():
		k = OS.get_environment("LONG_LIGHT_API_KEY").strip_edges()
	if k.is_empty() and FileAccess.file_exists("user://deepseek_key.txt"):
		var f := FileAccess.open("user://deepseek_key.txt", FileAccess.READ)
		if f:
			k = f.get_as_text().strip_edges()
	if k.is_empty() and FileAccess.file_exists("/home/guestpc/AZOTH/.env"):
		var ef := FileAccess.open("/home/guestpc/AZOTH/.env", FileAccess.READ)
		if ef:
			for line in ef.get_as_text().split("\n"):
				var s: String = str(line).strip_edges()
				if s.begins_with("DEEPSEEK_KEY="):
					k = s.substr(13).strip_edges().trim_prefix("\"").trim_suffix("\"")
					break
	return k


func request_story_chapter(chapter_id: String, offline_text: String, context: Dictionary) -> void:
	if not has_api():
		story_ready.emit(offline_text)
		return
	_busy = true
	_pending_kind = "story"
	status_changed.emit("School is weaving the next page…")
	var sys: String = "You are the chronicle of Long Light School RPG. Write 3-5 short sentences. Warm, precise. Never shame rest. No spoilers past flags. Plain prose."
	var user: String = "Chapter: %s | Seeker %s %s Lv%d | Area %s | Flags %s | Seed: %s" % [
		chapter_id,
		str(context.get("name", "Seeker")),
		str(context.get("archetype", "?")),
		int(context.get("level", 1)),
		str(context.get("area", "?")),
		str(context.get("flags_summary", "")),
		offline_text,
	]
	_post_chat(sys, user)


func request_help(question: String, context: Dictionary) -> void:
	if not has_api():
		help_ready.emit(offline_help(question))
		return
	_busy = true
	_pending_kind = "help"
	status_changed.emit("Consulting the School…")
	var sys: String = "Tutor for Long Light School. Under 100 words. Teach controls, MEASURE-first combat, field skills, shrines, companions. Rest is valid."
	var user: String = "Q: %s | %s Lv%d at %s | quest: %s" % [
		question,
		str(context.get("name", "Seeker")),
		int(context.get("level", 1)),
		str(context.get("area", "?")),
		str(context.get("quest", "")),
	]
	_post_chat(sys, user)


func request_myth(seed_title: String, context: Dictionary) -> void:
	if not has_api():
		myth_ready.emit("")
		return
	_busy = true
	_pending_kind = "myth"
	status_changed.emit("Forging a myth…")
	var sys: String = "Write one short Lycheetah School myth (4-6 sentences). Title already given. Poetic but clear. Companion Clause holds."
	var user: String = "Myth title: %s | Seeker %s at %s" % [
		seed_title,
		str(context.get("name", "Seeker")),
		str(context.get("area", "?")),
	]
	_post_chat(sys, user)


func request_companion_line(who: String, context: Dictionary) -> void:
	if not has_api():
		help_ready.emit("")  # caller uses offline lines
		return
	_busy = true
	_pending_kind = "help"
	status_changed.emit("%s is thinking…" % who.capitalize())
	var sys: String = "You are %s, companion in Long Light School. One or two warm lines. No guilt for rest. In character." % who
	var user: String = "Seeker %s Lv%d in %s. Quest tip: %s. Speak." % [
		str(context.get("name", "Seeker")),
		int(context.get("level", 1)),
		str(context.get("area", "?")),
		str(context.get("quest", "")),
	]
	_post_chat(sys, user)


func offline_help(q: String) -> String:
	var ql: String = q.to_lower()
	if "combat" in ql or "fight" in ql or "battle" in ql:
		return "Combat: 1 MEASURE shields · 2 COMPRESS if measured · 3 TRANSMUTE heal · 4 BREAK loops · 5 STRIKE (feeds loops!) · 6 GUARD · 7 companion · 8 item · F flee non-boss."
	if "control" in ql or "move" in ql or "key" in ql or "play" in ql:
		return "WASD step · Shift run · E interact · Enter continue talk · Esc exit talk/menu · T talk companion · P switch · K measure secrets · N map · Esc menu Help for full guide."
	if "story" in ql or "where" in ql or "go" in ql or "next" in ql:
		return "Sanctum N→Path→Hall (3 wins)→Wing→Mirror→Citrinitas→Rubedo. Secrets: Hall west Crypt · Garden stone Observatory · Path west Starwell."
	if "companion" in ql or "luna" in ql or "sol" in ql or "talk" in ql:
		return "T talks to active companion. P switches (Luna after Half-Made). Sol chips damage; Luna heals strain. Neither wilts if you rest."
	if "coin" in ql or "myth" in ql or "money" in ql:
		return "Battles and digs pay School Coins (shards). Help tab 6-9 buys myths from the Archive. AI can forge new myths if key set."
	return "Esc → Help tab: full guide pages [ ] and ask 1-5. Story tab Y for chronicle. Coins buy myths."


func build_context() -> Dictionary:
	var flags_bits: PackedStringArray = []
	for k in ["met_ember", "killed_overclaimer", "hall_cleared", "half_made_down", "mirror_down", "gold_down", "rubedo_complete", "unsaid_down"]:
		if GameState.has_flag(k):
			flags_bits.append(k)
	return {
		"name": GameState.player_name,
		"archetype": GameState.archetype,
		"level": GameState.level,
		"area": GameState.area_id,
		"quest": GameState.current_quest_tip(),
		"flags_summary": ", ".join(flags_bits),
	}


func _post_chat(system: String, user: String) -> void:
	var body := {
		"model": MODEL,
		"messages": [
			{"role": "system", "content": system},
			{"role": "user", "content": user},
		],
		"max_tokens": MAX_TOKENS,
		"temperature": 0.7,
	}
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer %s" % _key,
	])
	var err: int = _http.request(API_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		_busy = false
		status_changed.emit("Request failed (%d)." % err)
		_emit_empty()


func _emit_empty() -> void:
	match _pending_kind:
		"story":
			story_ready.emit("")
		"myth":
			myth_ready.emit("")
		_:
			help_ready.emit("")
	_pending_kind = ""


func _on_http_done(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	var kind: String = _pending_kind
	_pending_kind = ""
	if response_code != 200:
		status_changed.emit("AI HTTP %d — offline path." % response_code)
		if kind == "story":
			story_ready.emit("")
		elif kind == "myth":
			myth_ready.emit("")
		else:
			help_ready.emit("AI unreachable. Read Help pages.")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		_pending_kind = kind
		_emit_empty()
		return
	var choices: Array = data.get("choices", [])
	if choices.is_empty():
		if kind == "story":
			story_ready.emit("")
		elif kind == "myth":
			myth_ready.emit("")
		else:
			help_ready.emit("Empty AI reply.")
		return
	var msg: Dictionary = choices[0].get("message", {})
	var content: String = str(msg.get("content", "")).strip_edges()
	status_changed.emit("AI page sealed.")
	if kind == "story":
		story_ready.emit(content)
	elif kind == "myth":
		myth_ready.emit(content)
	else:
		help_ready.emit(content)
