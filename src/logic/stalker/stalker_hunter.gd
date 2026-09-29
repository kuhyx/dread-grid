class_name StalkerHunter
extends RefCounted
## The stalker itself: walks to random cells at a patrol pace, runs to the
## last place it saw or heard the player, searches there a moment and gives
## up. Pure movement; StalkerGame decides what it sees and whom it catches.

const PATROL_STEP: float = 1.0 / 1.5
const HUNT_STEP: float = 1.0 / 3.0
const SEARCH_TIME: float = 1.5

var grid: CellGrid
var cell: Vector2i
var facing: int = 2
var goal: Vector2i
var hunting: bool = false
var search_left: float = 0.0
## Footfalls so far; views play a thud each time it grows.
var steps: int = 0
## Time banked towards the next footfall.
var clock: float = 0.0
var _floors: Array[Vector2i] = []


func _init(on: CellGrid, at: Vector2i) -> void:
	grid = on
	cell = at
	goal = at
	_floors = on.floor_cells()


func step_time() -> float:
	return HUNT_STEP if hunting else PATROL_STEP


func searching() -> bool:
	return search_left > 0.0


## Chase `at`, the player's cell as last seen or heard.
func hunt(at: Vector2i) -> void:
	hunting = true
	search_left = 0.0
	goal = at


## The next `count` cells on its current route, nearest first.
func upcoming(count: int) -> Array[Vector2i]:
	var route: Array[Vector2i] = grid.path(cell, goal)
	return route.slice(1, count + 1)


## One footfall's worth of time. True when a hunt just ended with nothing
## found (the game says so).
func step(rng: RandomNumberGenerator) -> bool:
	if searching():
		search_left -= PATROL_STEP
		return false
	if cell == goal:
		if hunting:
			hunting = false
			search_left = SEARCH_TIME
			return true
		while goal == cell:
			goal = _floors[rng.randi_range(0, _floors.size() - 1)]
	var route: Array[Vector2i] = grid.path(cell, goal)
	if route.size() > 1:
		facing = CellGrid.DIRS.find(route[1] - cell)
		cell = route[1]
		steps += 1
	return false
