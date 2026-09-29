class_name FootageData
extends RefCounted
## The abandoned sanatorium and its seven scripted events, as data. Rules and
## views read these rows; a new event is a row plus a builder in each view.

const ROWS: PackedStringArray = [
	"#####################",
	"#.....#.......#.....#",
	"#.....#.......#.....#",
	"#.............#.....#",
	"#.....#.......#.....#",
	"###.#####.#######.###",
	"#...................#",
	"###.#####.#####.#####",
	"#.....#.....#.......#",
	"#.....#.....#.......#",
	"#...........#.......#",
	"#.....#.....#.......#",
	"#.....#.....#.......#",
	"#.....#.....#.......#",
	"#####################",
]
const START: Vector2i = Vector2i(19, 6)
const START_FACING: int = 3
## [name, x0, y0, x1, y1] - inclusive rectangles; anything else is a doorway.
const ROOMS: Array = [
	["the nurses' station", 1, 1, 5, 4],
	["the day room", 7, 1, 13, 4],
	["the chapel", 15, 1, 19, 4],
	["the long corridor", 1, 6, 19, 6],
	["the old ward", 1, 8, 5, 13],
	["the kitchen", 7, 8, 11, 13],
	["the cold room", 13, 8, 19, 13],
]
## [id, kind, x, y, trigger radius (path steps), label, prose (%s = where,
## relative to the player)]. Rings are disjoint and the start is outside all
## of them (tests/unit/test_found_footage.gd checks both).
const EVENTS: Array = [
	[
		"hanging",
		"hanging",
		17,
		2,
		3,
		"the hanging shape",
		"Whispers %s. Something hangs from the ceiling, turning slowly."
	],
	[
		"face",
		"face",
		12,
		1,
		3,
		"the face in the dark",
		"The lights stutter %s - between flashes, a pale face in the dark."
	],
	["door", "door", 6, 3, 3, "the slamming door", "A door slams shut %s. Nobody touched it."],
	[
		"figure",
		"figure",
		1,
		6,
		4,
		"the figure in the corridor",
		"Someone stands at the end of the corridor %s. Not moving."
	],
	[
		"shadow",
		"shadow",
		6,
		10,
		3,
		"the shadow in the doorway",
		"A shadow slides across the doorway %s."
	],
	[
		"chair",
		"chair",
		11,
		12,
		3,
		"the sliding chair",
		"A chair scrapes across the floor %s, all by itself."
	],
	[
		"crawler",
		"crawler",
		18,
		12,
		3,
		"the crawling thing",
		"Something crawls along the floor %s. Too many joints."
	],
]

## Events whose kinds suit each other's spots (same radius, so the rings stay
## as validated); the seed deals the spots out within each group.
const SWAPS: Array = [["shadow", "door"], ["hanging", "face", "chair", "crawler"]]


## The map, mirrored left-right and/or top-bottom: the seed picks one of four
## buildings with identical distances, so every validated property holds.
static func rows_for(flip: Vector2i) -> PackedStringArray:
	var out: Array[String] = []
	for y: int in ROWS.size():
		var row: String = ROWS[ROWS.size() - 1 - y if flip.y != 0 else y]
		out.append(row.reverse() if flip.x != 0 else row)
	return PackedStringArray(out)


## A cell of the authored map in the mirrored building (and back again).
static func flipped(c: Vector2i, flip: Vector2i) -> Vector2i:
	var w: int = ROWS[0].length()
	return Vector2i(
		w - 1 - c.x if flip.x != 0 else c.x, ROWS.size() - 1 - c.y if flip.y != 0 else c.y
	)


## A facing in the mirrored building: a flip swaps east/west or north/south.
static func flipped_facing(facing: int, flip: Vector2i) -> int:
	if facing % 2 == 1 and flip.x != 0 or facing % 2 == 0 and flip.y != 0:
		return (facing + 2) % 4
	return facing


## The room a cell belongs to, or "a doorway".
static func room_at(c: Vector2i) -> String:
	for row: Array in ROOMS:
		var x0: int = row[1]
		var y0: int = row[2]
		var x1: int = row[3]
		var y1: int = row[4]
		if c.x >= x0 and c.x <= x1 and c.y >= y0 and c.y <= y1:
			var room: String = row[0]
			return room
	return "a doorway"
