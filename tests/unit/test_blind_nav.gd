extends GutTest

const BOX: PackedStringArray = ["#####", "#...#", "#...#", "#####"]
const STRIP: PackedStringArray = ["#######", "#.....#", "#######"]


func _nav_on(rows: PackedStringArray, at: Vector2i, points: Array[Vector2i]) -> BlindNav:
	var nav: BlindNav = BlindNav.new(1)
	nav.load_map(BlindTrench.from_rows(rows, at, points))
	return nav


## A 20x20 open square with the given rock cells.
func _open_grid(rocks: Array[Vector2i]) -> CellGrid:
	var grid: CellGrid = CellGrid.new(20, 20, CellGrid.FLOOR)
	for c: Vector2i in rocks:
		grid.set_cell(c, CellGrid.WALL)
	return grid


func test_collision_costs_hull_and_does_not_move() -> void:
	var nav: BlindNav = _nav_on(BOX, Vector2i(1, 1), [Vector2i(3, 2)])
	assert_true(nav.perform(&"forward"), "a collision is still an action taken")
	assert_eq(nav.walker.cell, Vector2i(1, 1))
	assert_eq(nav.hull, BlindNav.MAX_HULL - BlindNav.CRASH_DAMAGE)
	assert_eq(nav.crashes, 1)
	assert_true(nav.perform(&"back"))
	assert_eq(nav.walker.cell, Vector2i(1, 2), "back into open water moves")
	assert_eq(nav.hull, 75)


func test_hull_at_zero_loses() -> void:
	var nav: BlindNav = _nav_on(BOX, Vector2i(1, 1), [Vector2i(3, 2)])
	for _i: int in 4:
		assert_true(nav.perform(&"forward"))
	assert_eq(nav.hull, 0)
	assert_eq(nav.status, Concept.Status.LOST)
	assert_false(nav.perform(&"turn_left"), "no actions after the end")


func test_logging_all_waypoints_wins() -> void:
	var points: Array[Vector2i] = [Vector2i(5, 1), Vector2i(3, 1), Vector2i(2, 1), Vector2i(4, 1)]
	var nav: BlindNav = _nav_on(STRIP, Vector2i(1, 1), points)
	assert_true(nav.perform(&"turn_right"))
	for _i: int in 3:
		assert_true(nav.perform(&"forward"))
	assert_eq(nav.logged(), 3)
	assert_eq(nav.status, Concept.Status.PLAYING)
	assert_true(nav.perform(&"forward"))
	assert_eq(nav.status, Concept.Status.WON)


func test_ping_ranges_on_a_hand_made_grid() -> void:
	var rocks: Array[Vector2i] = [Vector2i(10, 7), Vector2i(13, 7), Vector2i(10, 15)]
	var ranges: PackedInt32Array = BlindSonar.ping(_open_grid(rocks), Vector2i(10, 10))
	# N, NE, E, SE, S, SW, W, NW
	assert_eq(ranges, PackedInt32Array([3, 3, -1, -1, 5, -1, -1, -1]))
	var edge: PackedInt32Array = BlindSonar.ping(_open_grid([]), Vector2i(1, 10))
	assert_eq(edge[6], 2, "outside the map is rock")
	var readout: String = BlindSonar.readout(ranges)
	assert_string_contains(readout, "N 3  NE 3  E clear")


func test_ping_through_the_concept_records_the_returns() -> void:
	var nav: BlindNav = _nav_on(BOX, Vector2i(1, 1), [Vector2i(3, 2)])
	assert_true(nav.perform(&"ping"))
	assert_eq(nav.pings, 1)
	assert_eq(nav.ping_from, Vector2i(1, 1))
	assert_eq(nav.ping_ranges[0], 1, "rock right to the north")
	assert_eq(nav.ping_ranges[2], 3, "two open cells east, then the wall")


func test_photo_develops_then_shows_for_two_seconds() -> void:
	var nav: BlindNav = BlindNav.new(3)
	assert_true(nav.perform(&"photo"))
	assert_true(nav.locked())
	assert_false(nav.perform(&"forward"), "no moving while it develops")
	nav.advance(2.9)
	assert_true(nav.locked())
	assert_false(nav.photo_showing())
	nav.advance(0.2)
	assert_false(nav.locked())
	assert_true(nav.photo_showing())
	nav.advance(1.9)
	assert_true(nav.photo_showing())
	nav.advance(0.2)
	assert_false(nav.photo_showing())


func test_photo_is_the_five_by_five_patch_ahead() -> void:
	var cells: Array[Vector2i] = BlindSonar.patch(Vector2i(10, 10), 0)
	assert_eq(cells.size(), 25)
	assert_eq(cells[0], Vector2i(8, 5), "far left, facing north")
	assert_eq(cells[24], Vector2i(12, 9), "near right")
	var east: Array[Vector2i] = BlindSonar.patch(Vector2i(10, 10), 1)
	assert_eq(east[0], Vector2i(15, 8), "far left, facing east is north-east")


func test_fourth_photo_shows_the_eye() -> void:
	var nav: BlindNav = BlindNav.new(5)
	for i: int in 4:
		assert_true(nav.perform(&"photo"))
		assert_eq(nav.photo_eye, i == 3)
		nav.advance(BlindNav.DEVELOP_TIME + 0.1)


func test_every_waypoint_is_reachable_on_many_seeds() -> void:
	for seed_value: int in range(1, 80):
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = seed_value
		var trench: BlindTrench = BlindTrench.make(rng)
		var dist: PackedInt32Array = trench.grid.distances(trench.start)
		assert_eq(trench.start.y, BlindTrench.SIZE - 1, "starts on the south edge")
		assert_eq(trench.waypoints.size(), 4)
		for w: Vector2i in trench.waypoints:
			assert_gte(dist[w.y * BlindTrench.SIZE + w.x], BlindTrench.MIN_START_DISTANCE)


func test_the_same_seed_makes_the_same_trench() -> void:
	var a: BlindNav = BlindNav.new(11)
	var b: BlindNav = BlindNav.new(11)
	assert_eq(a.grid.cells, b.grid.cells)
	assert_eq(a.waypoints, b.waypoints)
	assert_ne(a.grid.cells, BlindNav.new(12).grid.cells)


func test_bot_wins_without_a_scratch_on_many_seeds() -> void:
	for seed_value: int in range(1, 21):
		var nav: BlindNav = BlindNav.new(seed_value)
		assert_eq(BotRunner.play(nav), Concept.Status.WON, "seed %d" % seed_value)
		assert_eq(nav.hull, BlindNav.MAX_HULL, "seed %d never collided" % seed_value)
		assert_gt(nav.photos, 0, "seed %d took photos" % seed_value)
