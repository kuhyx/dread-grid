extends GutTest


## Put the stalker at `at`, calm: not hunting, not searching, going nowhere.
func _park(game: StalkerGame, at: Vector2i) -> void:
	game.hunter.cell = at
	game.hunter.goal = at
	game.hunter.hunting = false
	game.hunter.search_left = 0.0


## A floor cell well out of sight and earshot of `from`.
func _far_from(game: StalkerGame, from: Vector2i) -> Vector2i:
	for c: Vector2i in game.grid.floor_cells():
		if game.grid.distance(from, c) >= 8 and not game.grid.line_of_sight(from, c):
			return c
	return from


func _messages(game: StalkerGame) -> Array[String]:
	var out: Array[String] = []
	Wire.link(game.message, func(text: String) -> void: out.append(text))
	return out


func test_level_places_keys_lockers_and_exit_apart() -> void:
	for seed_value: int in range(1, 20):
		var level: StalkerLevel = StalkerGame.new(seed_value).level
		assert_eq(level.keys.size(), StalkerLevel.KEY_COUNT)
		assert_true(level.lockers.size() >= StalkerLevel.LOCKER_COUNT)
		var cells: Dictionary = {StalkerLevel.START: true, level.exit_cell: true}
		var placed: Array[Vector2i] = level.keys.duplicate()
		placed.append_array(level.lockers)
		for c: Vector2i in placed:
			assert_false(cells.has(c), "seed %d: %s is used twice" % [seed_value, c])
			cells[c] = true
		var longest: int = level.start_distance(level.exit_cell)
		for c: Vector2i in level.grid.floor_cells():
			assert_true(level.start_distance(c) <= longest, "the exit is the farthest cell")
		assert_true(level.start_distance(level.stalker_start) >= longest * StalkerLevel.STALKER_FAR)


func test_every_cell_is_near_a_locker() -> void:
	for seed_value: int in range(1, 20):
		var level: StalkerLevel = StalkerGame.new(seed_value).level
		for c: Vector2i in level.grid.floor_cells():
			var near: bool = level.lockers.any(
				func(l: Vector2i) -> bool: return level.grid.distance(c, l) <= StalkerLevel.COVER
			)
			assert_true(near, "seed %d: %s has no locker in reach" % [seed_value, c])


func test_caught_when_it_is_next_to_you_in_the_open() -> void:
	var game: StalkerGame = StalkerGame.new(3)
	_park(game, game.grid.open_neighbors(game.walker.cell)[0])
	game.advance(0.01)
	assert_eq(game.status, Concept.Status.LOST)


func test_hidden_unseen_is_safe_even_next_to_it() -> void:
	var game: StalkerGame = StalkerGame.new(5)
	var locker: Vector2i = game.level.lockers[0]
	game.walker.cell = locker
	_park(game, _far_from(game, locker))
	assert_true(game.perform(&"hide"))
	assert_false(game.seen_hiding)
	assert_false(game.perform(&"forward"), "no walking while hidden")
	_park(game, game.grid.open_neighbors(locker)[0])
	game.advance(0.01)
	assert_eq(game.status, Concept.Status.PLAYING)


func test_hiding_in_its_sight_gets_you_caught() -> void:
	for seed_value: int in range(1, 20):
		var game: StalkerGame = StalkerGame.new(seed_value)
		for locker: Vector2i in game.level.lockers:
			for c: Vector2i in game.grid.floor_cells():
				var gap: float = Vector2(c - locker).length()
				if gap >= 2.0 and gap <= StalkerGame.SIGHT and game.grid.line_of_sight(c, locker):
					game.walker.cell = locker
					_park(game, c)
					assert_true(game.perform(&"hide"))
					assert_true(game.seen_hiding)
					game.advance(4.0)
					assert_eq(game.status, Concept.Status.LOST)
					return
	fail_test("no locker with a line of sight to it")


func test_walking_onto_a_key_picks_it_up() -> void:
	var game: StalkerGame = StalkerGame.new(7)
	var key: Vector2i = game.level.keys[0]
	var from: Vector2i = game.grid.open_neighbors(key)[0]
	game.walker.cell = from
	_park(game, _far_from(game, from))
	assert_true(game.perform(StalkerBot.go_towards(from, key)))
	assert_eq(game.keys_held(), 1)
	assert_false(game.keys_left.has(key))


func test_exit_stays_locked_until_all_keys_are_held() -> void:
	var game: StalkerGame = StalkerGame.new(9)
	var door: Vector2i = game.level.exit_cell
	var from: Vector2i = game.grid.open_neighbors(door)[0]
	game.walker.cell = from
	_park(game, _far_from(game, from))
	var said: Array[String] = _messages(game)
	assert_true(game.perform(StalkerBot.go_towards(from, door)))
	assert_eq(game.status, Concept.Status.PLAYING)
	var last: String = said.back()
	assert_string_contains(last, "locked")
	game.keys_left.clear()
	assert_true(game.perform(StalkerBot.go_towards(door, from)))
	assert_true(game.perform(StalkerBot.go_towards(from, door)))
	assert_eq(game.status, Concept.Status.WON)


func test_it_hears_footsteps_within_three_cells_around_a_corner() -> void:
	var game: StalkerGame = StalkerGame.new(11)
	for c: Vector2i in game.grid.floor_cells():
		for step: Vector2i in game.grid.open_neighbors(c):
			for h: Vector2i in game.grid.floor_cells():
				var d: int = game.grid.distance(h, step)
				if d >= 2 and d <= StalkerGame.HEARING and not _in_sight(game, h, c, step):
					game.walker.cell = c
					_park(game, h)
					assert_true(game.perform(StalkerBot.go_towards(c, step)))
					assert_true(game.hunter.hunting, "it heard the step")
					assert_eq(game.hunter.goal, step)
					return
	fail_test("no corner to test hearing around")


func test_quiet_steps_far_away_go_unheard() -> void:
	var game: StalkerGame = StalkerGame.new(11)
	var from: Vector2i = game.walker.cell
	_park(game, _far_from(game, from))
	var step: Vector2i = game.grid.open_neighbors(from)[0]
	assert_true(game.perform(StalkerBot.go_towards(from, step)))
	assert_false(game.hunter.hunting)


func test_listen_names_distance_and_direction() -> void:
	var game: StalkerGame = StalkerGame.new(2)
	var far: Vector2i = _far_from(game, game.walker.cell)
	_park(game, far)
	var said: Array[String] = _messages(game)
	assert_true(game.perform(&"listen"))
	var last: String = said.back()
	assert_string_contains(last, "to the %s." % StalkerSense.compass(far - game.walker.cell))
	assert_string_contains(last, StalkerSense.distance_word(game.stalker_distance()))


func test_bot_escapes_on_many_seeds() -> void:
	for seed_value: int in range(1, 31):
		assert_eq(
			BotRunner.play(StalkerGame.new(seed_value)), Concept.Status.WON, "seed %d" % seed_value
		)


## The first-person view acts about every 0.53 s (step animation + beat).
func test_bot_escapes_at_first_person_pace() -> void:
	for seed_value: int in range(1, 21):
		assert_eq(
			BotRunner.play(StalkerGame.new(seed_value), 0.53),
			Concept.Status.WON,
			"seed %d" % seed_value
		)


func _in_sight(game: StalkerGame, h: Vector2i, a: Vector2i, b: Vector2i) -> bool:
	var cells: Array[Vector2i] = [a, b]
	for c: Vector2i in cells:
		if Vector2(c - h).length() <= StalkerGame.SIGHT and game.grid.line_of_sight(h, c):
			return true
	return false
