class_name BlindSonar
extends RefCounted
## The sub's two instruments as pure functions over the true map, so every
## view and the tests share one definition. Ping: absolute compass
## directions; a range is the number of steps to the first rock (outside the
## map counts as rock), -1 when nothing is within RANGE. Photo: the 5x5 patch
## ahead, rows 1..5 cells in front of the bow, columns 2 left .. 2 right.

const RANGE: int = 8
const PATCH: int = 5
const MID: int = 2
const DIRS8: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(1, 1),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(-1, -1),
]
const NAMES8: PackedStringArray = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]


static func ping(grid: CellGrid, from: Vector2i) -> PackedInt32Array:
	var ranges: PackedInt32Array = Wire.sized_ints(DIRS8.size(), -1)
	for i: int in DIRS8.size():
		for k: int in range(1, RANGE + 1):
			if not grid.is_open(from + DIRS8[i] * k):
				ranges[i] = k
				break
	return ranges


## "N 3  NE 5  E clear ..." - the sonar readout every view shows.
static func readout(ranges: PackedInt32Array) -> String:
	var parts: Array[String] = []
	for i: int in ranges.size():
		var reach: String = "clear" if ranges[i] < 0 else str(ranges[i])
		parts.append("%s %s" % [NAMES8[i], reach])
	return "  ".join(PackedStringArray(parts))


## Stereo position of a ping direction: -1 west .. 1 east.
static func pan_of(index: int) -> float:
	var d: Vector2 = Vector2(DIRS8[index]).normalized()
	return d.x


## The patch cells, row-major: row 0 is farthest (5 ahead), column 0 is
## leftmost as seen from the helm.
static func patch(cell: Vector2i, facing: int) -> Array[Vector2i]:
	var fwd: Vector2i = CellGrid.DIRS[facing]
	var right: Vector2i = Vector2i(-fwd.y, fwd.x)
	var out: Array[Vector2i] = []
	for row: int in PATCH:
		for col: int in PATCH:
			out.append(cell + fwd * (PATCH - row) + right * (col - MID))
	return out


## Five text rows for the photo: '#' rock, '~' open water, '^' the bow
## position under the middle column.
static func sketch(grid: CellGrid, cells: Array[Vector2i]) -> Array[String]:
	var rows: Array[String] = []
	for row: int in PATCH:
		var line: String = ""
		for col: int in PATCH:
			line += " # " if not grid.is_open(cells[row * PATCH + col]) else " ~ "
		rows.append(line)
	rows.append(" ".repeat(MID * 3) + " ^ ")
	return rows


## One short sentence for the message log.
static func summary(grid: CellGrid, cells: Array[Vector2i]) -> String:
	var clear: int = 0
	for row: int in range(PATCH - 1, -1, -1):
		if not grid.is_open(cells[row * PATCH + MID]):
			break
		clear += 1
	var left: int = _rock_count(grid, cells, 0)
	var right: int = _rock_count(grid, cells, PATCH - 1)
	var head: String = "Rock right at the bow." if clear == 0 else "Open water %d ahead." % clear
	var sides: String = "Rock to the left." if left > right else "Rock to the right."
	if left == right:
		sides = "Rock on both sides." if left > 0 else "Nothing either side."
	return "PHOTO  %s %s" % [head, sides]


static func _rock_count(grid: CellGrid, cells: Array[Vector2i], col: int) -> int:
	var count: int = 0
	for row: int in PATCH:
		if not grid.is_open(cells[row * PATCH + col]):
			count += 1
	return count
