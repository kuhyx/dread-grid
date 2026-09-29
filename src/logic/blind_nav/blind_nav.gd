class_name BlindNav
extends Concept
## Blind Descent, Iron-Lung-style: a submarine with no window in a trench of
## rock. You know your coordinates; sonar pings and slow photos are the only
## way to see. Log all four waypoints to win; four collisions crush the hull.

const MAX_HULL: int = 100
const CRASH_DAMAGE: int = 25
const DEVELOP_TIME: float = 3.0
const PHOTO_TIME: float = 2.0
const RETURN_TIME: float = 2.0
const EYE_PHOTO: int = 4
const HEADINGS: PackedStringArray = ["N", "E", "S", "W"]

var grid: CellGrid
var walker: GridWalker
var start: Vector2i
var waypoints: Array[Vector2i] = []
var visited: Array[bool] = []
var hull: int = MAX_HULL
var crashes: int = 0
var moves: int = 0
## The last ping: where it was sent, the 8 ranges, and how old it is.
var pings: int = 0
var ping_from: Vector2i
var ping_ranges: PackedInt32Array = Wire.sized_ints(8, -1)
var ping_age: float = RETURN_TIME
var ping_move: int = 0
## The photo: taken, then DEVELOP_TIME locked, then shown PHOTO_TIME.
var photos: int = 0
var photo_move: int = 0
var develop_left: float = 0.0
var photo_left: float = 0.0
var photo_cells: Array[Vector2i] = []
var photo_eye: bool = false
## Every cell the sub has been in (the known track).
var track: Dictionary[Vector2i, bool] = {}
var _bot: BlindNavBot = BlindNavBot.new()


func _init(seed_value: int) -> void:
	super(seed_value)
	load_map(BlindTrench.make(rng))


## Put the sub at the trench's start (tests pass a hand-made trench).
func load_map(trench: BlindTrench) -> void:
	grid = trench.grid
	start = trench.start
	waypoints = trench.waypoints
	visited.clear()
	for _w: Vector2i in waypoints:
		visited.append(false)
	walker = GridWalker.new(grid, start, 0)
	track.clear()
	track[start] = true


## True while a photo develops: nothing else can be done.
func locked() -> bool:
	return develop_left > 0.0


func photo_showing() -> bool:
	return photo_left > 0.0


func logged() -> int:
	return visited.count(true)


func actions() -> Array[StringName]:
	return [&"forward", &"back", &"turn_left", &"turn_right", &"ping", &"photo", &"status"]


func hud_line() -> String:
	var marks: Array[String] = []
	for i: int in waypoints.size():
		var w: Vector2i = waypoints[i]
		var mark: String = "x" if visited[i] else " "
		marks.append("%s (%d,%d) [%s]" % [BlindTrench.LABELS[i], w.x, w.y, mark])
	return (
		"X %02d  Y %02d  heading %s  hull %d%%    Space ping   F photo\nWaypoints  %s"
		% [
			walker.cell.x,
			walker.cell.y,
			HEADINGS[walker.facing],
			hull,
			"   ".join(PackedStringArray(marks)),
		]
	)


func bot_action() -> StringName:
	return _bot.next_action(self)


func _on_advance(delta: float) -> void:
	ping_age += delta
	if develop_left > 0.0:
		develop_left -= delta
		if develop_left <= 0.0:
			develop_left = 0.0
			photo_left = PHOTO_TIME
			_say(BlindSonar.summary(grid, photo_cells))
			if photo_eye:
				_say("Something fills the frame. An EYE. It is looking at the camera.")
	elif photo_left > 0.0:
		photo_left = maxf(0.0, photo_left - delta)


func _on_perform(action: StringName) -> bool:
	if locked():
		return false
	match action:
		&"forward", &"back":
			_move(action == &"forward")
		&"turn_left", &"turn_right":
			walker.turn(action == &"turn_right")
		&"ping":
			_ping()
		&"photo":
			_photo()
		&"status":
			_say(_status_report())
		_:
			return false
	return true


func _move(forwards: bool) -> void:
	if not walker.step(forwards):
		crashes += 1
		hull = maxi(0, hull - CRASH_DAMAGE)
		_say("CRUNCH. The hull groans.")
		if hull <= 0:
			_say("The hull gives way. Black water.")
			_finish(false)
		return
	moves += 1
	track[walker.cell] = true
	var index: int = waypoints.find(walker.cell)
	if index >= 0 and not visited[index]:
		_log_waypoint(index)


func _log_waypoint(index: int) -> void:
	visited[index] = true
	var left: int = waypoints.size() - logged()
	_say("WAYPOINT %s logged. %d to go." % [BlindTrench.LABELS[index], left])
	if left == 0:
		_say("Something vast slides past the hull, close enough to hear.")
		_say("The winch engages. You are being pulled up.")
		_finish(true)


func _ping() -> void:
	pings += 1
	ping_move = moves
	ping_from = walker.cell
	ping_ranges = BlindSonar.ping(grid, walker.cell)
	ping_age = 0.0
	_say("SONAR  " + BlindSonar.readout(ping_ranges))


func _photo() -> void:
	photos += 1
	photo_move = moves
	photo_cells = BlindSonar.patch(walker.cell, walker.facing)
	photo_eye = photos == EYE_PHOTO
	photo_left = 0.0
	develop_left = DEVELOP_TIME
	_say("The camera whirs. Developing...")


func _status_report() -> String:
	var todo: Array[String] = []
	for i: int in waypoints.size():
		if not visited[i]:
			var w: Vector2i = waypoints[i]
			todo.append("%s at (%d, %d)" % [BlindTrench.LABELS[i], w.x, w.y])
	return (
		"Position (%d, %d), heading %s. Hull %d%%. Still to log: %s."
		% [
			walker.cell.x,
			walker.cell.y,
			GridWalker.DIR_NAMES[walker.facing],
			hull,
			", ".join(PackedStringArray(todo)),
		]
	)
