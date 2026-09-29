class_name CellGrid
extends RefCounted
## A walls-and-floors grid: the one world model every concept and every
## perspective shares. Cells outside the grid count as walls.

const FLOOR: int = 0
const WALL: int = 1
const DIRS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

var width: int
var height: int
var cells: PackedByteArray = PackedByteArray()


func _init(w: int, h: int, fill: int = WALL) -> void:
	width = w
	height = h
	cells = Wire.sized_bytes(w * h)
	cells.fill(fill)


## Build from rows of text: '#' is wall, anything else floor.
static func from_rows(rows: PackedStringArray) -> CellGrid:
	var grid: CellGrid = CellGrid.new(rows[0].length(), rows.size())
	for y: int in rows.size():
		for x: int in rows[y].length():
			grid.set_cell(Vector2i(x, y), WALL if rows[y][x] == "#" else FLOOR)
	return grid


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func is_open(c: Vector2i) -> bool:
	return in_bounds(c) and cells[c.y * width + c.x] == FLOOR


func set_cell(c: Vector2i, value: int) -> void:
	if in_bounds(c):
		cells[c.y * width + c.x] = value


func open_neighbors(c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d: Vector2i in DIRS:
		if is_open(c + d):
			out.append(c + d)
	return out


func floor_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in height:
		for x: int in width:
			if cells[y * width + x] == FLOOR:
				out.append(Vector2i(x, y))
	return out


## Breadth-first distances from `from` over open cells; -1 = unreachable.
## `blocked` cells are treated as walls (the start never is).
func distances(from: Vector2i, blocked: Dictionary = {}) -> PackedInt32Array:
	var dist: PackedInt32Array = Wire.sized_ints(width * height, -1)
	if not is_open(from):
		return dist
	dist[from.y * width + from.x] = 0
	var queue: Array[Vector2i] = [from]
	var head: int = 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		for n: Vector2i in open_neighbors(c):
			if dist[n.y * width + n.x] == -1 and not blocked.has(n):
				dist[n.y * width + n.x] = dist[c.y * width + c.x] + 1
				queue.append(n)
	return dist


func distance(a: Vector2i, b: Vector2i) -> int:
	return distances(a)[b.y * width + b.x] if in_bounds(b) else -1


## Shortest path from `from` to `to` (both included), or [] if none.
func path(from: Vector2i, to: Vector2i, blocked: Dictionary = {}) -> Array[Vector2i]:
	var dist: PackedInt32Array = distances(to, blocked)
	var out: Array[Vector2i] = []
	if not in_bounds(from) or dist[from.y * width + from.x] < 0:
		return out
	var c: Vector2i = from
	out.append(c)
	while c != to:
		for n: Vector2i in open_neighbors(c):
			if dist[n.y * width + n.x] == dist[c.y * width + c.x] - 1:
				c = n
				break
		out.append(c)
	return out


## Straight-line visibility between cell centres; walls block.
func line_of_sight(a: Vector2i, b: Vector2i) -> bool:
	var steps: int = maxi(absi(b.x - a.x), absi(b.y - a.y)) * 2
	for i: int in range(1, steps):
		var t: float = float(i) / float(steps)
		var p: Vector2 = Vector2(a).lerp(Vector2(b), t)
		if not is_open(Vector2i(roundi(p.x), roundi(p.y))):
			return false
	return true
