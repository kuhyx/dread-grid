extends GutTest


func _event(tape: FoundFootage, id: String) -> FootageEvent:
	for event: FootageEvent in tape.events:
		if event.id == id:
			return event
	return null


## A cell or facing of the authored map, in this seed's mirrored building.
func _at(tape: FoundFootage, x: int, y: int) -> Vector2i:
	return FootageData.flipped(Vector2i(x, y), tape.flip)


func test_rings_are_disjoint_and_the_start_is_outside_them() -> void:
	for seed_value: int in range(1, 21):
		var tape: FoundFootage = FoundFootage.new(seed_value)
		for event: FootageEvent in tape.events:
			var start: int = event.steps_from(tape.walker.cell)
			assert_gt(start, event.radius + 1, "%s is clear of the start" % event.id)
			for other: FootageEvent in tape.events:
				if other != event:
					assert_gt(event.steps_from(other.cell), event.radius + other.radius)


func test_capture_needs_recording_facing_and_line_of_sight() -> void:
	var tape: FoundFootage = FoundFootage.new(3)
	var figure: FootageEvent = _event(tape, "figure")
	figure.start()
	tape.walker.cell = _at(tape, 3, 4)
	tape.walker.facing = FootageData.flipped_facing(2, tape.flip)
	assert_true(tape.perform(&"rec_start"))
	assert_false(figure.captured, "in the cone but a wall is in the way")
	tape.walker.cell = _at(tape, 3, 6)
	tape.walker.facing = FootageData.flipped_facing(1, tape.flip)
	assert_true(tape.perform(&"wait"))
	assert_false(figure.captured, "facing away")
	assert_true(tape.perform(&"rec_stop"))
	tape.walker.facing = FootageData.flipped_facing(3, tape.flip)
	assert_true(tape.perform(&"wait"))
	assert_false(figure.captured, "facing it, but the tape is not rolling")
	assert_true(tape.perform(&"record"))
	assert_true(figure.captured)
	assert_eq(tape.captured, 1)


func test_battery_drains_six_minutes_recording_thirty_idle() -> void:
	var tape: FoundFootage = FoundFootage.new(1)
	tape.advance(18.0)
	assert_almost_eq(tape.battery, 99.0, 0.001)
	assert_true(tape.perform(&"rec_start"))
	tape.advance(36.0)
	assert_almost_eq(tape.battery, 89.0, 0.001)


func test_an_empty_battery_loses() -> void:
	var tape: FoundFootage = FoundFootage.new(1)
	assert_true(tape.perform(&"record"))
	tape.advance(359.0)
	assert_eq(tape.status, Concept.Status.PLAYING)
	tape.advance(2.0)
	assert_eq(tape.battery, 0.0)
	assert_eq(tape.status, Concept.Status.LOST)


func test_losing_when_too_few_events_are_left() -> void:
	var tape: FoundFootage = FoundFootage.new(1)
	for i: int in 2:
		tape.events[i].phase = FootageEvent.Phase.OVER
	tape.advance(0.1)
	assert_eq(tape.status, Concept.Status.PLAYING, "five of five still possible")
	tape.events[2].phase = FootageEvent.Phase.OVER
	tape.advance(0.1)
	assert_eq(tape.status, Concept.Status.LOST)


func test_an_event_triggers_once_and_then_is_gone() -> void:
	var tape: FoundFootage = FoundFootage.new(2)
	watch_signals(tape)
	var hanging: FootageEvent = _event(tape, "hanging")
	tape.walker.cell = hanging.cell
	tape.advance(0.1)
	assert_eq(hanging.phase, FootageEvent.Phase.ACTIVE)
	tape.advance(FootageEvent.DURATION)
	assert_eq(hanging.phase, FootageEvent.Phase.OVER)
	assert_false(hanging.captured)
	tape.walker.cell = tape.grid.open_neighbors(hanging.cell)[0]
	tape.advance(0.1)
	tape.walker.cell = hanging.cell
	tape.advance(0.1)
	assert_eq(hanging.phase, FootageEvent.Phase.OVER)
	assert_signal_emit_count(tape, "event_started", 1)


func test_timecode_counts_hours_minutes_seconds_frames() -> void:
	assert_eq(FootageProse.timecode(3723.5, true), "01:02:03:12")
	assert_eq(FootageProse.timecode(192.0, false), "00:03:12")


func test_bot_tapes_five_on_many_seeds() -> void:
	for seed_value: int in range(1, 21):
		var tape: FoundFootage = FoundFootage.new(seed_value)
		assert_eq(BotRunner.play(tape), Concept.Status.WON, "seed %d" % seed_value)


func test_bot_tapes_five_at_text_pace() -> void:
	for seed_value: int in range(1, 21):
		var tape: FoundFootage = FoundFootage.new(seed_value)
		assert_eq(BotRunner.play(tape, 2.0), Concept.Status.WON, "seed %d" % seed_value)
