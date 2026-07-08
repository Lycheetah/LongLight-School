extends Control
## Title → Name → Archetype → Overworld

@onready var title: Control = $Title
@onready var archetype: Control = $Archetype
@onready var overworld_host: Node = $OverworldHost
@onready var title_hint: Label = $Title/Hint

var arch_keys: Array = ["ALCHEMIST", "SENTINEL", "ORACLE", "WANDERER"]
var arch_i: int = 0
var _name_layer: Control
var _name_edit: LineEdit
var _seeker_name: String = "Seeker"
var _phase: String = "title"  # title | name | arch | play


func _ready() -> void:
	title.visible = true
	archetype.visible = false
	if overworld_host:
		overworld_host.visible = false
	_build_name_ui()
	if GameState.has_save():
		title_hint.text = "Enter — New Game   ·   L — Load   ·   Esc — Quit"
	else:
		title_hint.text = "Enter — Begin the Work   ·   Esc — Quit"
	if has_node("Title/Tag"):
		var blurb: String = ContentDB.LORE_BLURBS[randi() % ContentDB.LORE_BLURBS.size()]
		$Title/Tag.text = "GBA / DS mystery-school RPG · built in one session\n%s" % blurb
	if title and has_node("Title/TitleText"):
		var tw := create_tween().set_loops()
		tw.tween_property($Title/TitleText, "modulate", Color(1.1, 1.05, 0.9), 1.4)
		tw.tween_property($Title/TitleText, "modulate", Color.WHITE, 1.4)
	_refresh_arch()


func _build_name_ui() -> void:
	_name_layer = ColorRect.new()
	_name_layer.name = "NameEntry"
	_name_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_name_layer.color = Color("0a0812")
	_name_layer.visible = false
	add_child(_name_layer)
	var title_l := Label.new()
	title_l.text = "What is your name, Seeker?"
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_l.offset_top = 180
	title_l.offset_left = -300
	title_l.offset_right = 300
	title_l.offset_bottom = 220
	title_l.add_theme_font_size_override("font_size", 26)
	title_l.add_theme_color_override("font_color", Color("f0d080"))
	_name_layer.add_child(title_l)
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Seeker"
	_name_edit.max_length = 16
	_name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_edit.set_anchors_preset(Control.PRESET_CENTER)
	_name_edit.offset_left = -160
	_name_edit.offset_top = -24
	_name_edit.offset_right = 160
	_name_edit.offset_bottom = 24
	_name_layer.add_child(_name_edit)
	var hint := Label.new()
	hint.text = "Type a name · Enter continue · Esc = Seeker"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -120
	hint.offset_left = -300
	hint.offset_right = 300
	hint.offset_bottom = -80
	hint.add_theme_color_override("font_color", Color("8a80a8"))
	_name_layer.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if _phase == "title" or title.visible:
		if event.is_action_pressed("interact"):
			title.visible = false
			_phase = "name"
			_name_layer.visible = true
			_name_edit.grab_focus()
			_name_edit.text = ""
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_L:
			if GameState.load_game():
				_phase = "play"
				_start_overworld()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("menu"):
			get_tree().quit()
		return

	if _phase == "name" and _name_layer.visible:
		if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_ENTER):
			_seeker_name = _name_edit.text.strip_edges()
			if _seeker_name == "":
				_seeker_name = "Seeker"
			_name_layer.visible = false
			archetype.visible = true
			_phase = "arch"
			_refresh_arch()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("menu"):
			_seeker_name = "Seeker"
			_name_layer.visible = false
			archetype.visible = true
			_phase = "arch"
			_refresh_arch()
			get_viewport().set_input_as_handled()
		return

	if _phase == "arch" and archetype.visible:
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_up"):
			arch_i = (arch_i - 1 + arch_keys.size()) % arch_keys.size()
			_refresh_arch()
		elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down"):
			arch_i = (arch_i + 1) % arch_keys.size()
			_refresh_arch()
		elif event.is_action_pressed("interact"):
			GameState.new_game(arch_keys[arch_i], _seeker_name)
			_phase = "play"
			_start_overworld()
		get_viewport().set_input_as_handled()


func _refresh_arch() -> void:
	var k: String = arch_keys[arch_i]
	var a: Dictionary = ContentDB.ARCHETYPES[k]
	$Archetype/Name.text = k
	$Archetype/Desc.text = str(a.desc)
	$Archetype/Stats.text = "WILL %d   INS %d   WIL %d   LCK %d   SPD %.0f" % [
		a.hp, a.insight, a.will, a.luck, a.speed
	]
	$Archetype/Hint.text = "%s · ← → path · Enter confirm" % _seeker_name


func _start_overworld() -> void:
	title.visible = false
	archetype.visible = false
	if _name_layer:
		_name_layer.visible = false
	for c in overworld_host.get_children():
		c.queue_free()
	var scn: PackedScene = load("res://scenes/overworld.tscn")
	var node: Node = scn.instantiate()
	overworld_host.add_child(node)
	overworld_host.visible = true
