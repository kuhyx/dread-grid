class_name GridWalker
extends RefCounted
## A position plus a facing on a CellGrid: the player of every grid concept.
## Facing indexes CellGrid.DIRS (0 north, 1 east, 2 south, 3 west).

const DIR_NAMES: PackedStringArray = ["north", "east", "south", "west"]

var grid: CellGrid
var cell: Vector2i
var facing: int = 0


func _init(on: CellGrid, at: Vector2i, face: int = 0) -> void:
	grid = on
	cell = at
	facing = face


func forward_vector() -> Vector2i:
	return CellGrid.DIRS[facing]


func ahead() -> Vector2i:
	return cell + forward_vector()


## Step one cell forward (or back). False and no move if a wall is there.
func step(forwards: bool = true) -> bool:
	var target: Vector2i = cell + (forward_vector() if forwards else -forward_vector())
	if not grid.is_open(target):
		return false
	cell = target
	return true


func turn(clockwise: bool) -> void:
	facing = (facing + (1 if clockwise else 3)) % 4


func face_towards(target: Vector2i) -> void:
	var d: Vector2i = target - cell
	if absi(d.x) >= absi(d.y) and d.x != 0:
		facing = 1 if d.x > 0 else 3
	elif d.y != 0:
		facing = 2 if d.y > 0 else 0


## The action (&"forward", &"turn_left", &"turn_right") that moves one step
## along a path towards `next`, an adjacent cell.
func action_towards(next: Vector2i) -> StringName:
	var want: int = CellGrid.DIRS.find(next - cell)
	if want == facing:
		return &"forward"
	if want == (facing + 1) % 4:
		return &"turn_right"
	if want == (facing + 2) % 4 and grid.is_open(cell - forward_vector()):
		return &"back"
	return &"turn_left"


## Is `target` within `cone` (cosine) of the facing and in sight?
func sees(target: Vector2i, max_range: int, cone: float = 0.7) -> bool:
	var d: Vector2 = Vector2(target - cell)
	if d == Vector2.ZERO:
		return true
	if d.length() > max_range or d.normalized().dot(Vector2(forward_vector())) < cone:
		return false
	return grid.line_of_sight(cell, target)
