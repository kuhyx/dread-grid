class_name MazeGen
extends RefCounted
## Recursive-backtracker mazes on odd-sized grids, plus a pass that knocks out
## extra walls so the maze has loops (a stalker you can only flee down a
## corridor with one exit is not scary, it is unfair).


static func generate(w: int, h: int, rng: RandomNumberGenerator, loops: float) -> CellGrid:
	var grid: CellGrid = CellGrid.new(w, h)
	var start: Vector2i = Vector2i(1, 1)
	grid.set_cell(start, CellGrid.FLOOR)
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var c: Vector2i = stack.back()
		var options: Array[Vector2i] = []
		for d: Vector2i in CellGrid.DIRS:
			var n: Vector2i = c + d * 2
			if n.x > 0 and n.y > 0 and n.x < w - 1 and n.y < h - 1 and not grid.is_open(n):
				options.append(d)
		if options.is_empty():
			stack.pop_back()
			continue
		var pick: Vector2i = options[rng.randi_range(0, options.size() - 1)]
		grid.set_cell(c + pick, CellGrid.FLOOR)
		grid.set_cell(c + pick * 2, CellGrid.FLOOR)
		stack.append(c + pick * 2)
	_add_loops(grid, rng, loops)
	return grid


static func _add_loops(grid: CellGrid, rng: RandomNumberGenerator, chance: float) -> void:
	for y: int in range(1, grid.height - 1):
		for x: int in range(1, grid.width - 1):
			var c: Vector2i = Vector2i(x, y)
			if grid.is_open(c) or rng.randf() >= chance:
				continue
			var horizontal: bool = (
				grid.is_open(c + Vector2i.LEFT) and grid.is_open(c + Vector2i.RIGHT)
			)
			var vertical: bool = grid.is_open(c + Vector2i.UP) and grid.is_open(c + Vector2i.DOWN)
			if horizontal != vertical:
				grid.set_cell(c, CellGrid.FLOOR)


## Open cells with exactly one open neighbour.
static func dead_ends(grid: CellGrid) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Vector2i in grid.floor_cells():
		if grid.open_neighbors(c).size() == 1:
			out.append(c)
	return out
