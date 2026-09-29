class_name StalkerLevel
extends RefCounted
## One stalker maze and where things are in it. The exit is the cell farthest
## from the start; keys go in the far half of the dead ends, spread apart by
## farthest-point sampling on path distance. Lockers are a covering set: no
## floor cell is more than COVER steps from one, whatever the seed.

const SIZE: int = 15
const LOOPS: float = 0.08
const KEY_COUNT: int = 3
const LOCKER_COUNT: int = 6
## No floor cell is further than this from a locker (or the start).
const COVER: int = 8
const START: Vector2i = Vector2i(1, 1)
## The stalker starts at least this share of the longest path away.
const STALKER_FAR: float = 0.6

var grid: CellGrid
var exit_cell: Vector2i
var keys: Array[Vector2i] = []
var lockers: Array[Vector2i] = []
var stalker_start: Vector2i
var _from_start: PackedInt32Array


func _init(rng: RandomNumberGenerator) -> void:
	grid = MazeGen.generate(SIZE, SIZE, rng, LOOPS)
	_from_start = grid.distances(START)
	exit_cell = _farthest_from_start(grid.floor_cells())
	_place_keys()
	var taken: Array[Vector2i] = [START, exit_cell]
	taken.append_array(keys)
	var floors: Array[Vector2i] = _free(grid.floor_cells(), taken)
	_place_lockers(floors.filter(func(c: Vector2i) -> bool: return _has_wall(c)))
	_place_stalker(rng, _free(floors, lockers))


func start_distance(c: Vector2i) -> int:
	return _from_start[c.y * grid.width + c.x]


func _place_keys() -> void:
	var ends: Array[Vector2i] = _free(MazeGen.dead_ends(grid), [START, exit_cell])
	if ends.size() < KEY_COUNT * 2:
		ends = _free(grid.floor_cells(), [START, exit_cell])
	ends.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return _further(a, b))
	var far_half: Array[Vector2i] = ends.slice(0, maxi(KEY_COUNT, ends.size() / 2))
	var taken: Array[Vector2i] = [START, exit_cell]
	for _i: int in KEY_COUNT:
		var key: Vector2i = _spread_pick(far_half, taken)
		keys.append(key)
		taken.append(key)
		far_half.erase(key)


## Greedy k-centre: each locker goes where the walk to the nearest one is
## longest (the first is the free cell nearest the top-left start), until LOCKER_COUNT
## are placed and no floor cell is more than COVER steps from one.
func _place_lockers(floors: Array[Vector2i]) -> void:
	var anchors: Array[Vector2i] = []
	var cells: Array[Vector2i] = grid.floor_cells()
	while (
		not floors.is_empty()
		and (lockers.size() < LOCKER_COUNT or _spread_gap(cells, anchors) > COVER)
	):
		var locker: Vector2i = _spread_pick(floors, anchors)
		lockers.append(locker)
		anchors.append(locker)
		floors.erase(locker)


func _place_stalker(rng: RandomNumberGenerator, floors: Array[Vector2i]) -> void:
	var longest: int = start_distance(exit_cell)
	var far: Array[Vector2i] = floors.filter(
		func(c: Vector2i) -> bool: return start_distance(c) >= longest * STALKER_FAR
	)
	if far.is_empty():
		far = floors
	stalker_start = far[rng.randi_range(0, far.size() - 1)]


## A locker stands against a wall, so crossroads cannot hold one.
func _has_wall(c: Vector2i) -> bool:
	return grid.open_neighbors(c).size() < CellGrid.DIRS.size()


func _further(a: Vector2i, b: Vector2i) -> bool:
	return start_distance(a) > start_distance(b)


func _farthest_from_start(cells: Array[Vector2i]) -> Vector2i:
	var best: Vector2i = START
	for c: Vector2i in cells:
		if start_distance(c) > start_distance(best):
			best = c
	return best


## The candidate whose nearest `taken` cell (by path) is farthest away.
func _spread_pick(candidates: Array[Vector2i], taken: Array[Vector2i]) -> Vector2i:
	var nearest: PackedInt32Array = _nearest_field(taken)
	var best: Vector2i = candidates[0]
	for c: Vector2i in candidates:
		if nearest[c.y * grid.width + c.x] > nearest[best.y * grid.width + best.x]:
			best = c
	return best


## The longest walk from any of `cells` to its nearest `taken` cell.
func _spread_gap(cells: Array[Vector2i], taken: Array[Vector2i]) -> int:
	var nearest: PackedInt32Array = _nearest_field(taken)
	var gap: int = 0
	for c: Vector2i in cells:
		gap = maxi(gap, nearest[c.y * grid.width + c.x])
	return gap


func _nearest_field(taken: Array[Vector2i]) -> PackedInt32Array:
	var nearest: PackedInt32Array = Wire.sized_ints(grid.width * grid.height, 1 << 30)
	for t: Vector2i in taken:
		var dist: PackedInt32Array = grid.distances(t)
		for i: int in dist.size():
			if dist[i] >= 0:
				nearest[i] = mini(nearest[i], dist[i])
	return nearest


static func _free(cells: Array[Vector2i], taken: Array[Vector2i]) -> Array[Vector2i]:
	return cells.filter(func(c: Vector2i) -> bool: return not taken.has(c))
