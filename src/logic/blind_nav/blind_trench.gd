class_name BlindTrench
extends RefCounted
## The trench floor for one seed: jagged side walls, rock blobs laid by
## random walkers, the start on the south edge and four waypoints. Every
## waypoint is drawn from the cells a BFS reaches from the start, one per
## zone; if a zone has none, the rock is re-laid thinner. At zero density the
## trench is open water between its walls and every zone has reachable cells,
## so generation always ends with all four waypoints reachable.

const SIZE: int = 40
const HALF: int = 20
const ROCK_DENSITY: float = 0.3
const THINNING: float = 0.6
const WALK_STEPS: int = 12
const MIN_START_DISTANCE: int = 10
## Waypoint zones (x, y, width, height): north-west, north-east, then the
## two southern halves above the start lane.
const ZONES: Array[Rect2i] = [
	Rect2i(0, 0, 20, 20),
	Rect2i(20, 0, 20, 20),
	Rect2i(0, 20, 20, 14),
	Rect2i(20, 20, 20, 14),
]
const LABELS: PackedStringArray = ["A", "B", "C", "D"]

var grid: CellGrid
var start: Vector2i
var waypoints: Array[Vector2i] = []


static func make(rng: RandomNumberGenerator) -> BlindTrench:
	var trench: BlindTrench = BlindTrench.new()
	var density: float = ROCK_DENSITY
	trench.lay_rock(rng, density)
	while not trench.place_waypoints(rng):
		density = density * THINNING if density > 0.02 else 0.0
		trench.lay_rock(rng, density)
	return trench


## A hand-made trench for tests: '#' rock, anything else water.
static func from_rows(
	rows: PackedStringArray, at: Vector2i, points: Array[Vector2i]
) -> BlindTrench:
	var trench: BlindTrench = BlindTrench.new()
	trench.grid = CellGrid.from_rows(rows)
	trench.start = at
	trench.waypoints = points
	return trench


func lay_rock(rng: RandomNumberGenerator, density: float) -> void:
	grid = CellGrid.new(SIZE, SIZE, CellGrid.FLOOR)
	_side_walls(rng)
	var walkers: int = int(density * SIZE * SIZE / WALK_STEPS)
	for _i: int in walkers:
		var c: Vector2i = Vector2i(rng.randi_range(0, SIZE - 1), rng.randi_range(0, SIZE - 1))
		for _s: int in WALK_STEPS:
			grid.set_cell(c, CellGrid.WALL)
			if rng.randf() < 0.4:
				grid.set_cell(c + Vector2i(1, 0), CellGrid.WALL)
			c += CellGrid.DIRS[rng.randi_range(0, 3)]
	start = Vector2i(HALF + rng.randi_range(-8, 8), SIZE - 1)
	for y: int in range(SIZE - 5, SIZE):
		for x: int in range(start.x - 1, start.x + 2):
			grid.set_cell(Vector2i(x, y), CellGrid.FLOOR)


## One waypoint per zone, from the cells reachable from the start and not
## too close to it. False when a zone has no such cell.
func place_waypoints(rng: RandomNumberGenerator) -> bool:
	waypoints.clear()
	var dist: PackedInt32Array = grid.distances(start)
	for zone: Rect2i in ZONES:
		var pool: Array[Vector2i] = []
		for y: int in range(zone.position.y, zone.end.y):
			for x: int in range(zone.position.x, zone.end.x):
				if dist[y * SIZE + x] >= MIN_START_DISTANCE:
					pool.append(Vector2i(x, y))
		if pool.is_empty():
			return false
		waypoints.append(pool[rng.randi_range(0, pool.size() - 1)])
	return true


## Jagged trench walls 1..4 cells thick on the west and east.
func _side_walls(rng: RandomNumberGenerator) -> void:
	var west: int = 2
	var east: int = 2
	for y: int in SIZE:
		west = clampi(west + rng.randi_range(-1, 1), 1, 4)
		east = clampi(east + rng.randi_range(-1, 1), 1, 4)
		for x: int in west:
			grid.set_cell(Vector2i(x, y), CellGrid.WALL)
		for x: int in east:
			grid.set_cell(Vector2i(SIZE - 1 - x, y), CellGrid.WALL)
