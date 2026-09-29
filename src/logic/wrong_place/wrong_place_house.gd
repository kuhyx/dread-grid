class_name WrongPlaceHouse
extends RefCounted
## The one hand-authored house of Wrong Place, as data. Only '#' is wall; every
## other letter names the room the floor cell belongs to, so room names come
## from the same strings as the walls. S is the front door (the start), X the
## back door in the kitchen, the far end of the house.

const ROWS: PackedStringArray = [
	"################X###",
	"#bbbbb#kkkkkk#ccccc#",
	"#bbbbb#kkkkkk#ccccc#",
	"#bbbbb#kkkkkk#ccccc#",
	"#bbbbb#kkkkkk#ccccc#",
	"###d#####d#######d##",
	"#hhhhhhhhhhhhhhhhhh#",
	"#hhhhhhhhhhhhhhhhhh#",
	"####d####hh####d####",
	"#lllllll#hh#rrrrrrr#",
	"#lllllll#hh#rrrrrrr#",
	"#lllllll#hh#rrrrrrr#",
	"#lllllll#hh#rrrrrrr#",
	"#########Sh#########",
]
const ROOMS: Dictionary = {
	"h": "hallway",
	"S": "hallway",
	"l": "living room",
	"r": "bedroom",
	"b": "bathroom",
	"k": "kid's room",
	"c": "kitchen",
	"d": "doorway",
	"X": "back door",
}
## Row: [id, kind, x, y, colour, state, label]. Every object stands on a floor
## cell against exactly one wall, never in a doorway, and blocks movement.
const OBJECTS: Array = [
	["photo", "photo", 6, 6, "brown", "hung", "MUM DAD ANNA"],
	["clock", "clock", 13, 6, "cream", "ticking", "10:10"],
	["plant", "plant", 17, 7, "green", "potted", ""],
	["tv", "tv", 1, 10, "grey", "off", ""],
	["bookshelf", "bookshelf", 2, 9, "brown", "tidy", "ATLAS BIBLE RECIPES"],
	["lamp", "lamp", 6, 9, "yellow", "on", ""],
	["portrait", "portrait", 7, 11, "brown", "smiling", "GRANDMA"],
	["window", "window", 4, 12, "blue", "clean", ""],
	["bed", "bed", 18, 10, "white", "made", ""],
	["painting", "painting", 12, 11, "brown", "upright", "HOME"],
	["bathtub", "bathtub", 1, 2, "blue", "full", ""],
	["mirror", "mirror", 3, 1, "grey", "clear", ""],
	["crib", "crib", 7, 2, "cream", "still", ""],
	["doll", "doll", 12, 2, "pink", "facing_room", ""],
	["fridge", "fridge", 18, 2, "cream", "closed", ""],
	["table", "table", 14, 3, "brown", "set", ""],
	["chair", "chair", 15, 4, "brown", "floor", ""],
]


static func grid() -> CellGrid:
	return CellGrid.from_rows(ROWS)


## The first cell holding `marker` (a room letter, S or X).
static func find(marker: String) -> Vector2i:
	for y: int in ROWS.size():
		var x: int = ROWS[y].find(marker)
		if x >= 0:
			return Vector2i(x, y)
	return Vector2i(-1, -1)


static func start() -> Vector2i:
	return find("S")


static func back_door() -> Vector2i:
	return find("X")


## The room name of a floor cell, or "" for walls and outside.
static func room_at(c: Vector2i) -> String:
	if c.y < 0 or c.y >= ROWS.size() or c.x < 0 or c.x >= ROWS[c.y].length():
		return ""
	return ROOMS.get(ROWS[c.y][c.x], "")


## Fresh props for every object, all normal.
static func props() -> Array[Prop]:
	var out: Array[Prop] = []
	for row: Array in OBJECTS:
		out.append(Prop.from_row(row))
	return out


## The DIRS index of the wall `c` stands against (first one found), or -1.
static func wall_dir(grid_ref: CellGrid, c: Vector2i) -> int:
	for i: int in CellGrid.DIRS.size():
		if not grid_ref.is_open(c + CellGrid.DIRS[i]):
			return i
	return -1


## Average cell of every room, for lights and labels.
static func room_centres() -> Dictionary:
	var sums: Dictionary = {}
	var counts: Dictionary = {}
	for y: int in ROWS.size():
		for x: int in ROWS[y].length():
			var room: String = room_at(Vector2i(x, y))
			if room == "" or room == "doorway" or room == "back door":
				continue
			var sum: Vector2 = sums.get(room, Vector2.ZERO)
			sums[room] = sum + Vector2(x, y)
			var count: int = counts.get(room, 0)
			counts[room] = count + 1
	var out: Dictionary = {}
	for room: String in sums:
		var total: Vector2 = sums[room]
		var count: int = counts[room]
		out[room] = total / float(count)
	return out
