extends GutTest


## Put the player on a free cell next to `prop`, facing it.
func _face(game: WrongPlace, prop: Prop) -> void:
	var stands: Array[Vector2i] = game.stand_cells(prop)
	assert_false(stands.is_empty(), "%s has a free side" % prop.id)
	game.walker.cell = stands[0]
	game.walker.face_towards(prop.cell)


func _first(game: WrongPlace, wrong_one: bool) -> Prop:
	for prop: Prop in game.props:
		if game.is_wrong(prop) == wrong_one:
			return prop
	return null


func test_bot_wins_on_seeds_1_to_20() -> void:
	for seed_value: int in range(1, 21):
		var game: WrongPlace = WrongPlace.new(seed_value)
		assert_eq(BotRunner.play(game), Concept.Status.WON, "seed %d" % seed_value)
		assert_eq(game.false_flags, 0, "seed %d bot never guesses" % seed_value)


func test_eight_distinct_wrong_objects_per_seed() -> void:
	var sets: Dictionary = {}
	for seed_value: int in range(1, 21):
		var game: WrongPlace = WrongPlace.new(seed_value)
		assert_eq(game.wrong.size(), WrongPlace.WRONG_COUNT, "seed %d" % seed_value)
		var normal: Array[Prop] = WrongPlaceHouse.props()
		var changed: int = 0
		for i: int in game.props.size():
			if _signature(game.props[i]) != _signature(normal[i]):
				changed += 1
		assert_eq(changed, WrongPlace.WRONG_COUNT, "seed %d edits 8 objects" % seed_value)
		var ids: Array = game.wrong.keys()
		ids.sort()
		sets[str(ids)] = true
	assert_gt(sets.size(), 10, "seeds pick different objects")


func test_same_seed_same_house() -> void:
	assert_eq(str(WrongPlace.new(7).wrong), str(WrongPlace.new(7).wrong))


func test_flag_wrong_counts_once() -> void:
	var game: WrongPlace = WrongPlace.new(3)
	_face(game, _first(game, true))
	assert_true(game.perform(&"flag"))
	assert_eq(game.found, 1)
	assert_true(game.perform(&"flag"))
	assert_eq(game.found, 1, "flagging twice does not count twice")
	assert_eq(game.false_flags, 0)


func test_flag_normal_is_a_false_flag_once() -> void:
	var game: WrongPlace = WrongPlace.new(3)
	_face(game, _first(game, false))
	assert_true(game.perform(&"flag"))
	assert_eq(game.false_flags, 1)
	assert_true(game.perform(&"flag"))
	assert_eq(game.false_flags, 1)
	assert_eq(game.found, 0)


func test_flag_facing_nothing_changes_nothing() -> void:
	var game: WrongPlace = WrongPlace.new(3)
	assert_true(game.perform(&"flag"))
	assert_eq(game.found + game.false_flags, 0)


func test_back_door_locked_below_six() -> void:
	var game: WrongPlace = WrongPlace.new(5)
	var inside: Vector2i = game.back_door + Vector2i(0, 1)
	game.walker.cell = inside
	game.walker.facing = 0
	game.found = WrongPlace.TO_OPEN - 1
	assert_true(game.perform(&"forward"))
	assert_eq(game.walker.cell, inside, "the door does not let you through")
	assert_eq(game.status, Concept.Status.PLAYING)
	game.found = WrongPlace.TO_OPEN
	assert_true(game.perform(&"forward"))
	assert_eq(game.status, Concept.Status.WON)


func test_furniture_blocks_movement() -> void:
	var game: WrongPlace = WrongPlace.new(1)
	var prop: Prop = game.props[0]
	_face(game, prop)
	var at: Vector2i = game.walker.cell
	assert_true(game.perform(&"forward"))
	assert_eq(game.walker.cell, at)
	assert_true(game.bumped)


func test_compass_words_face_then_step() -> void:
	var game: WrongPlace = WrongPlace.new(1)
	var start: Vector2i = game.walker.cell
	assert_true(game.perform(&"east"))
	assert_eq(game.walker.facing, 1)
	assert_eq(game.walker.cell, start + Vector2i(1, 0))


func _signature(p: Prop) -> String:
	return "%s|%s|%s|%s|%s" % [p.id, p.kind, p.color, p.state, p.label]
