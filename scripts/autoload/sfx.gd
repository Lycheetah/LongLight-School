extends Node
## Lightweight procedural SFX — no external audio files required.

var _player: AudioStreamPlayer
var _gen: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _hz: float = 44100.0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_gen = AudioStreamGenerator.new()
	_gen.mix_rate = _hz
	_gen.buffer_length = 0.1
	_player.stream = _gen
	_player.volume_db = -8.0
	add_child(_player)


func _ensure() -> bool:
	if not _player.playing:
		_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	return _playback != null


func _tone(freq: float, ms: float, vol: float = 0.15, wave: String = "sine") -> void:
	if not _ensure():
		return
	var n: int = int(_hz * ms / 1000.0)
	for i in n:
		var t: float = float(i) / _hz
		var env: float = 1.0 - float(i) / float(maxi(1, n))
		var s: float
		match wave:
			"square":
				s = 0.2 if sin(TAU * freq * t) > 0.0 else -0.2
			"tri":
				s = 0.25 * (2.0 * absf(2.0 * fmod(freq * t, 1.0) - 1.0) - 1.0)
			_:
				s = sin(TAU * freq * t) * 0.25
		s *= vol * env
		_playback.push_frame(Vector2(s, s))


func ui() -> void:
	_tone(880, 40, 0.1, "tri")


func step() -> void:
	_tone(120 + randf() * 40, 25, 0.06, "square")


func talk() -> void:
	_tone(520, 50, 0.1, "sine")
	_tone(660, 40, 0.08, "sine")


func measure() -> void:
	_tone(440, 60, 0.12, "sine")
	_tone(880, 80, 0.1, "sine")
	_tone(1320, 100, 0.08, "sine")


func hit() -> void:
	_tone(180, 70, 0.14, "square")


func heal() -> void:
	_tone(523, 50, 0.1, "sine")
	_tone(659, 60, 0.1, "sine")
	_tone(784, 80, 0.1, "sine")


func win() -> void:
	for f in [523, 659, 784, 1046]:
		_tone(float(f), 90, 0.1, "sine")


func lose() -> void:
	_tone(200, 150, 0.12, "tri")
	_tone(140, 200, 0.1, "tri")


func warp() -> void:
	_tone(300, 40, 0.08, "sine")
	_tone(600, 60, 0.1, "sine")
	_tone(900, 80, 0.08, "sine")


func save_ok() -> void:
	_tone(700, 40, 0.1, "tri")
	_tone(1000, 60, 0.1, "tri")


func encounter() -> void:
	_tone(200, 40, 0.12, "square")
	_tone(400, 50, 0.12, "square")
	_tone(800, 80, 0.1, "tri")


func level_up() -> void:
	for f in [392, 494, 587, 784, 988]:
		_tone(float(f), 70, 0.09, "sine")


# Soft ambient pad (call periodically from overworld)
var _amb_cd: float = 0.0

func ambient_tick(delta: float) -> void:
	_amb_cd -= delta
	if _amb_cd > 0.0:
		return
	_amb_cd = 2.8 + randf() * 2.0
	var base := 146.0
	if typeof(Atmosphere) != TYPE_NIL and Atmosphere.has_method("phase_name"):
		if Atmosphere.phase_name() in ["night", "late_night", "dusk"]:
			base = 110.0
	_tone(base, 400, 0.03, "sine")
	_tone(base * 1.5, 350, 0.025, "sine")
