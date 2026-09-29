extends GutTest
## install.sh put the assets in place and Godot can load them: every CC0
## sample pinned in assets.lock.json and every concept's music bed, looping.


func test_every_pinned_sample_loads() -> void:
	var text: String = FileAccess.get_file_as_string("res://assets.lock.json")
	var lock: Dictionary = JSON.parse_string(text)
	var samples: Array = lock["samples"]
	assert_gt(samples.size(), 0)
	for entry: Dictionary in samples:
		var sample_name: String = entry["name"]
		assert_not_null(Sfx.sample(sample_name), "sample %s (run ./install.sh)" % sample_name)


func test_every_concept_has_a_looping_music_bed() -> void:
	for concept: String in Registry.CONCEPTS:
		var bed: AudioStreamWAV = Sfx.music(concept)
		assert_not_null(bed, "music bed %s (run ./install.sh)" % concept)
		if bed != null:
			assert_eq(bed.loop_mode, AudioStreamWAV.LOOP_FORWARD)
			assert_gt(bed.get_length(), 20.0)


func test_procedural_tone_is_stereo_and_panned() -> void:
	var left: AudioStreamWAV = Sfx.tone(440.0, 0.1, -1.0)
	var bytes: PackedByteArray = left.data
	var quiet_right: bool = true
	for i: int in range(0, bytes.size(), 4):
		quiet_right = quiet_right and bytes.decode_s16(i + 2) == 0
	assert_true(left.stereo)
	assert_true(quiet_right, "pan -1 leaves the right channel silent")
