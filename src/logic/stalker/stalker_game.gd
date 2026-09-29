class_name StalkerGame
extends Concept
## Stalker: three keys, then the red exit door, in a looping maze with
## something in it. It patrols, hunts what it sees (6 cells, line of sight)
## or hears (you walking within 3 cells of path) and catches you on its cell
## or the next one - unless you are hidden in a locker and it did not see
## you get in.

const SIGHT: float = 6.0
const HEARING: int = 3
const GO_ACTIONS: Dictionary = {&"go_north": 0, &"go_east": 1, &"go_south": 2, &"go_west": 3}

var level: StalkerLevel
var grid: CellGrid
var walker: GridWalker
var hunter: StalkerHunter
var keys_left: Array[Vector2i] = []
var hidden: bool = false
var seen_hiding: bool = false
## Game time of the player's last footstep (views draw a noise ripple).
var noise_at: float = -100.0


func _init(seed_value: int) -> void:
	super(seed_value)
	level = StalkerLevel.new(rng)
	grid = level.grid
	walker = GridWalker.new(grid, StalkerLevel.START)
	walker.face_towards(grid.open_neighbors(StalkerLevel.START)[0])
	hunter = StalkerHunter.new(grid, level.stalker_start)
	keys_left = level.keys.duplicate()


func keys_held() -> int:
	return StalkerLevel.KEY_COUNT - keys_left.size()


func on_locker() -> bool:
	return level.lockers.has(walker.cell)


## Whether the stalker has the player in sight, hidden or not.
func sees_player() -> bool:
	return (
		Vector2(hunter.cell - walker.cell).length() <= SIGHT
		and grid.line_of_sight(hunter.cell, walker.cell)
	)


func stalker_distance() -> int:
	return grid.distance(walker.cell, hunter.cell)


func actions() -> Array[StringName]:
	return [
		&"forward",
		&"back",
		&"turn_left",
		&"turn_right",
		&"go_north",
		&"go_east",
		&"go_south",
		&"go_west",
		&"hide",
		&"listen",
		&"wait",
		&"look"
	]


func hud_line() -> String:
	var keys: String = "Keys %d/%d" % [keys_held(), StalkerLevel.KEY_COUNT]
	var goal: String = "find the red door" if keys_left.is_empty() else "find the keys"
	var hide: String = "HIDDEN - E to get out" if hidden else "E hide in a locker"
	return "%s - %s    %s    Q listen" % [keys, goal, hide]


func bot_action() -> StringName:
	return StalkerBot.choose(self)


func _on_perform(action: StringName) -> bool:
	var done: bool = true
	match action:
		&"forward", &"back":
			done = _move(action == &"forward")
		&"turn_left", &"turn_right":
			walker.turn(action == &"turn_right")
		&"go_north", &"go_east", &"go_south", &"go_west":
			var dir: int = GO_ACTIONS[action]
			done = _go(dir)
		&"hide":
			done = _toggle_hide()
		&"listen":
			_say(StalkerSense.listen(self))
		&"wait", &"look":
			pass
		_:
			done = false
	return done


func _on_advance(delta: float) -> void:
	_sense()
	hunter.clock += delta
	while status == Status.PLAYING and hunter.clock >= hunter.step_time():
		hunter.clock -= hunter.step_time()
		if hunter.step(rng):
			_say("It stops, sniffs the air, and turns away.")
		_sense()


func _go(dir: int) -> bool:
	if hidden or not grid.is_open(walker.cell + CellGrid.DIRS[dir]):
		return false
	walker.facing = dir
	return _move(true)


func _move(forwards: bool) -> bool:
	if hidden or not walker.step(forwards):
		return false
	noise_at = elapsed
	if stalker_distance() <= HEARING:
		if not hunter.hunting:
			_say("Your footstep echoes. It heard you.")
		hunter.hunt(walker.cell)
	_sense()
	if status == Status.PLAYING:
		_arrive()
	return true


func _arrive() -> void:
	var here: Vector2i = walker.cell
	if keys_left.has(here):
		keys_left.erase(here)
		_say("You pick up a key. %d/%d." % [keys_held(), StalkerLevel.KEY_COUNT])
	if here != level.exit_cell:
		return
	if keys_left.is_empty():
		_say("The red door gives. You are out.")
		_finish(true)
	else:
		_say("The red door is locked. %d keys still missing." % keys_left.size())


func _toggle_hide() -> bool:
	if hidden:
		hidden = false
		seen_hiding = false
		_say("You ease the locker open and step out.")
		_sense()
		return true
	if not on_locker():
		_say("There is nothing to hide in here.")
		return false
	hidden = true
	seen_hiding = sees_player()
	_say("It saw you get in." if seen_hiding else "You pull the locker shut and hold your breath.")
	_sense()
	return true


## What the stalker notices now: sight starts or steers a hunt; then the
## catch rule (same or adjacent cell, unless hidden unseen).
func _sense() -> void:
	if status != Status.PLAYING:
		return
	if seen_hiding or (not hidden and sees_player()):
		if not hunter.hunting:
			_say("It has seen you. RUN.")
		hunter.hunt(walker.cell)
	var gap: Vector2i = hunter.cell - walker.cell
	if absi(gap.x) + absi(gap.y) <= 1 and (not hidden or seen_hiding):
		_say("It has you.")
		_finish(false)
