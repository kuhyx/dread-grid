extends GutTest


func _walk_out(loop: AnomalyLoop, back: bool) -> void:
	var index: int = loop.loop_index
	if back:
		assert_true(loop.perform(&"turn_back"))
	while loop.loop_index == index and loop.status == Concept.Status.PLAYING:
		assert_true(loop.perform(&"forward"))


func test_first_loop_is_always_normal() -> void:
	for seed_value: int in range(1, 20):
		assert_false(AnomalyLoop.new(seed_value).has_anomaly())


func test_right_call_counts_and_wrong_call_resets() -> void:
	var loop: AnomalyLoop = AnomalyLoop.new(4)
	_walk_out(loop, false)
	assert_eq(loop.streak, 1)
	_walk_out(loop, not loop.has_anomaly())
	assert_eq(loop.streak, 0)
	assert_eq(loop.mistakes, 1)


func test_every_anomaly_changes_the_props() -> void:
	var normal: String = _signature(AnomalyCatalog.props_for(-1))
	for i: int in AnomalyCatalog.ANOMALIES.size():
		assert_ne(_signature(AnomalyCatalog.props_for(i)), normal, "anomaly %d is visible" % i)


func test_every_anomaly_changes_the_prose() -> void:
	var normal: String = _prose(AnomalyCatalog.props_for(-1))
	for i: int in AnomalyCatalog.ANOMALIES.size():
		assert_ne(_prose(AnomalyCatalog.props_for(i)), normal, "anomaly %d is readable" % i)


func test_anomalies_appear_about_half_the_time() -> void:
	var seen: int = 0
	var loops: int = 0
	for seed_value: int in range(1, 60):
		var loop: AnomalyLoop = AnomalyLoop.new(seed_value)
		while loop.status == Concept.Status.PLAYING:
			_walk_out(loop, loop.has_anomaly())
			if loop.status == Concept.Status.PLAYING:
				loops += 1
				seen += 1 if loop.has_anomaly() else 0
	assert_between(float(seen) / loops, 0.35, 0.65)


func test_bot_escapes_on_many_seeds() -> void:
	for seed_value: int in range(1, 30):
		assert_eq(
			BotRunner.play(AnomalyLoop.new(seed_value)), Concept.Status.WON, "seed %d" % seed_value
		)


func _signature(props: Array[Prop]) -> String:
	var parts: Array[String] = []
	for p: Prop in props:
		parts.append("%s|%s|%s|%s|%s" % [p.id, p.kind, p.color, p.state, p.label])
	return ";".join(PackedStringArray(parts))


func _prose(props: Array[Prop]) -> String:
	var parts: Array[String] = []
	for p: Prop in props:
		parts.append(AnomalyCatalog.describe(p, false))
	return " ".join(PackedStringArray(parts))
