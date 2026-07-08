extends CharacterBody2D
## Pokémon/DS-style **grid step** movement + walk cycle.

const TILE := 32
const PixelArtUtil = preload("res://scripts/util/pixel_art.gd")

var facing: Vector2 = Vector2(0, 1)
var can_move: bool = true
var moved_this_frame: bool = false
var _anim: float = 0.0
var _dir_i: int = 0  # 0 down 1 left 2 right 3 up
var _sheet: ImageTexture

var _sliding: bool = false
var _slide_from: Vector2 = Vector2.ZERO
var _slide_to: Vector2 = Vector2.ZERO
var _slide_t: float = 0.0
var _slide_dur: float = 0.14
var _held_dir: Vector2 = Vector2.ZERO
var _step_sfx_cd: float = 0.0

@onready var overworld: Node2D = get_parent().get_parent()
@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	_ensure_sprite()
	_rebuild_sheet()
	var cs := $CollisionShape2D as CollisionShape2D
	if cs and cs.shape == null:
		var circle := CircleShape2D.new()
		circle.radius = 8.0
		cs.shape = circle
	# snap to tile center
	global_position = _tile_center(_tile_of(global_position))


func _ensure_sprite() -> void:
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		add_child(sprite)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = true
	sprite.offset = Vector2(0, -4)
	sprite.scale = Vector2(2, 2)


func _rebuild_sheet() -> void:
	var col: Color = ContentDB.ARCHETYPES.get(GameState.archetype, {}).get("color", Color("f0d080"))
	_sheet = PixelArtUtil.player_sheet(col)
	sprite.texture = _sheet
	sprite.region_enabled = true
	_set_frame(0, 0)


func _paint_sprite() -> void:
	_rebuild_sheet()


func _set_frame(dir: int, frame: int) -> void:
	sprite.region_rect = Rect2(frame * 16, dir * 24, 16, 24)


func _tile_of(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / TILE)), int(floor(p.y / TILE)))


func _tile_center(t: Vector2i) -> Vector2:
	return Vector2(t.x * TILE + TILE * 0.5, t.y * TILE + TILE * 0.5)


func _read_input_dir() -> Vector2:
	# Prefer last pressed axis for snappy Pokémon feel
	if Input.is_action_just_pressed("move_up") or (Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down")):
		if Input.is_action_pressed("move_up") and not (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")) \
			or Input.is_action_just_pressed("move_up"):
			pass
	var d := Vector2.ZERO
	# priority: most recent just_pressed, else held
	if Input.is_action_just_pressed("move_up"):
		return Vector2(0, -1)
	if Input.is_action_just_pressed("move_down"):
		return Vector2(0, 1)
	if Input.is_action_just_pressed("move_left"):
		return Vector2(-1, 0)
	if Input.is_action_just_pressed("move_right"):
		return Vector2(1, 0)
	if Input.is_action_pressed("move_up"):
		d = Vector2(0, -1)
	elif Input.is_action_pressed("move_down"):
		d = Vector2(0, 1)
	elif Input.is_action_pressed("move_left"):
		d = Vector2(-1, 0)
	elif Input.is_action_pressed("move_right"):
		d = Vector2(1, 0)
	return d


func _physics_process(delta: float) -> void:
	moved_this_frame = false
	_step_sfx_cd = maxf(0.0, _step_sfx_cd - delta)
	velocity = Vector2.ZERO

	if not can_move or GameState.in_battle:
		_set_frame(_dir_i, 0)
		return

	# mid-slide: interpolate
	if _sliding:
		_slide_t += delta
		var u: float = clampf(_slide_t / _slide_dur, 0.0, 1.0)
		# ease out slightly
		var e: float = 1.0 - (1.0 - u) * (1.0 - u)
		global_position = _slide_from.lerp(_slide_to, e)
		_anim += delta * 12.0
		var frames: Array = [0, 1, 0, 2]
		var f: int = int(frames[int(_anim) % 4])
		_set_frame(_dir_i, f)
		if u >= 1.0:
			global_position = _slide_to
			_sliding = false
			moved_this_frame = true
			if _step_sfx_cd <= 0.0:
				SFX.step()
				_step_sfx_cd = 0.05
			# chain walk if still holding
			var cont := _read_input_dir()
			if cont != Vector2.ZERO:
				_try_step(cont)
			else:
				_set_frame(_dir_i, 0)
		return

	# idle: face / start step
	var dir := _read_input_dir()
	if dir != Vector2.ZERO:
		_try_step(dir)
	else:
		_anim = 0.0
		_set_frame(_dir_i, 0)


func _try_step(dir: Vector2) -> void:
	# face even if blocked (Pokémon bump)
	facing = dir
	if dir.y > 0:
		_dir_i = 0
	elif dir.x < 0:
		_dir_i = 1
	elif dir.x > 0:
		_dir_i = 2
	else:
		_dir_i = 3

	var cur := _tile_of(global_position)
	var nxt := Vector2i(cur.x + int(dir.x), cur.y + int(dir.y))
	if overworld.is_solid(nxt.x, nxt.y):
		_set_frame(_dir_i, 0)
		# tiny bump feedback
		global_position = _tile_center(cur) + dir * 2.0
		return

	var sprint := Input.is_key_pressed(KEY_SHIFT)
	_slide_dur = 0.09 if sprint else 0.145
	_slide_from = _tile_center(cur)
	_slide_to = _tile_center(nxt)
	_slide_t = 0.0
	_sliding = true
	moved_this_frame = true
