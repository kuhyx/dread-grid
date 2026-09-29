extends GutTest

const ROWS: PackedStringArray = ["#####", "#...#", "#.#.#", "#...#", "#####"]


func test_from_rows_marks_walls_and_floors() -> void:
	var grid: CellGrid = CellGrid.from_rows(ROWS)
	assert_eq(grid.width, 5)
	assert_true(grid.is_open(Vector2i(1, 1)))
	assert_false(grid.is_open(Vector2i(2, 2)))
	assert_false(grid.is_open(Vector2i(-1, 0)), "outside the grid is wall")


func test_path_goes_around_the_pillar() -> void:
	var grid: CellGrid = CellGrid.from_rows(ROWS)
	var route: Array[Vector2i] = grid.path(Vector2i(1, 1), Vector2i(3, 3))
	assert_eq(route.size(), 5)
	assert_eq(route[0], Vector2i(1, 1))
	assert_eq(route[-1], Vector2i(3, 3))


func test_blocked_cells_cut_the_route() -> void:
	var grid: CellGrid = CellGrid.from_rows(ROWS)
	var blocked: Dictionary = {Vector2i(2, 1): true, Vector2i(1, 2): true}
	assert_eq(grid.path(Vector2i(1, 1), Vector2i(3, 3), blocked).size(), 0)


func test_line_of_sight_is_blocked_by_walls() -> void:
	var grid: CellGrid = CellGrid.from_rows(ROWS)
	assert_true(grid.line_of_sight(Vector2i(1, 1), Vector2i(3, 1)))
	assert_false(grid.line_of_sight(Vector2i(1, 2), Vector2i(3, 2)))


func test_walker_steps_turns_and_stops_at_walls() -> void:
	var walker: GridWalker = GridWalker.new(CellGrid.from_rows(ROWS), Vector2i(1, 1), 1)
	assert_true(walker.step())
	assert_eq(walker.cell, Vector2i(2, 1))
	walker.turn(true)
	assert_false(walker.step(), "the pillar is south")
	assert_eq(walker.action_towards(Vector2i(3, 1)), &"turn_left")


func test_maze_is_connected() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var grid: CellGrid = MazeGen.generate(15, 15, rng, 0.1)
	var dist: PackedInt32Array = grid.distances(Vector2i(1, 1))
	for c: Vector2i in grid.floor_cells():
		assert_gt(dist[c.y * grid.width + c.x], -1, "cell %s reachable" % c)
