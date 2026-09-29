class_name Sfx
extends RefCounted
## Sound for every view: procedural tones (always available, and the only
## source the text view's stereo sonar needs) plus the CC0 samples and the
## rendered music beds that install.sh puts under res://assets.

const RATE: int = 22050

static var _tones: Dictionary = {}


## A decaying sine (plus optional noise), panned -1 left .. 1 right.
static func tone(
	freq: float, seconds: float, pan: float = 0.0, noise: float = 0.0
) -> AudioStreamWAV:
	var key: String = "%s|%s|%s|%s" % [freq, seconds, pan, noise]
	if _tones.has(key):
		return _tones[key]
	var frames: int = int(seconds * RATE)
	var data: PackedByteArray = Wire.sized_bytes(frames * 4)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(freq * 100.0)
	var left: float = clampf(1.0 - pan, 0.0, 1.0)
	var right: float = clampf(1.0 + pan, 0.0, 1.0)
	for i: int in frames:
		var t: float = float(i) / RATE
		var env: float = minf(1.0, t * 80.0) * pow(1.0 - float(i) / frames, 2.0)
		var s: float = sin(TAU * freq * t) * (1.0 - noise) + rng.randf_range(-1.0, 1.0) * noise
		data.encode_s16(i * 4, int(s * env * left * 16000.0))
		data.encode_s16(i * 4 + 2, int(s * env * right * 16000.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = true
	wav.mix_rate = RATE
	wav.data = data
	_tones[key] = wav
	return wav


## A CC0 sample by its short name (see assets.lock.json), or null.
static func sample(sample_name: String) -> AudioStream:
	for ext: String in ["ogg", "wav", "mp3"]:
		var path: String = "res://assets/cc0/%s.%s" % [sample_name, ext]
		if ResourceLoader.exists(path):
			return load(path)
	return null


## The concept's procedural music bed, looping, or null if not rendered.
static func music(concept_id: String) -> AudioStreamWAV:
	var path: String = ProjectSettings.globalize_path("res://assets/music/%s.wav" % concept_id)
	if not FileAccess.file_exists(path):
		return null
	var wav: AudioStreamWAV = AudioStreamWAV.load_from_file(path)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = wav.data.size() / (4 if wav.stereo else 2)
	return wav


## Play once (or forever, for a looping stream) under `parent`.
static func play(parent: Node, stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null or not parent.is_inside_tree():
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	parent.add_child(player)
	player.play()
	Wire.link(player.finished, player.queue_free)
