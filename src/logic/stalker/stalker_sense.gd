class_name StalkerSense
extends RefCounted
## Words for what the player hears and sees, shared by the listen action and
## the text view: compass directions, distances, passages around a cell.

## Indexed by the angle of a grid offset in eighths of a turn (y points south).
const COMPASS: PackedStringArray = [
	"east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"
]


static func compass(offset: Vector2i) -> String:
	if offset == Vector2i.ZERO:
		return "here"
	return COMPASS[posmod(roundi(Vector2(offset).angle() / (PI / 4.0)), 8)]


static func distance_word(steps: int) -> String:
	if steps <= 2:
		return "very close"
	if steps <= 5:
		return "close"
	if steps <= 9:
		return "not far"
	return "far off"


## The listen action's report on the stalker.
static func listen(game: StalkerGame) -> String:
	var hunter: StalkerHunter = game.hunter
	var sound: String = "Footsteps"
	if hunter.hunting:
		sound = "Running footsteps"
	elif hunter.searching():
		sound = "Heavy breathing"
	var offset: Vector2i = hunter.cell - game.walker.cell
	if offset == Vector2i.ZERO:
		return "%s, right outside the locker door." % sound
	return "%s, %s, to the %s." % [sound, distance_word(game.stalker_distance()), compass(offset)]


## "Passages: north, east." for the open sides of `c`.
static func passages(grid: CellGrid, c: Vector2i) -> String:
	var open: Array[String] = []
	for i: int in CellGrid.DIRS.size():
		if grid.is_open(c + CellGrid.DIRS[i]):
			open.append(GridWalker.DIR_NAMES[i])
	return "Passages: %s." % ", ".join(PackedStringArray(open))


## A line about how close it is, or "" when it is out of earshot.
static func presence(game: StalkerGame) -> String:
	var steps: int = game.stalker_distance()
	if steps <= StalkerGame.HEARING:
		return "Heavy breathing, right nearby."
	if steps <= 7:
		return "Somewhere close, something shifts its weight."
	return ""
