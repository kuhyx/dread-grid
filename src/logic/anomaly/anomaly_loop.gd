class_name AnomalyLoop
extends Concept
## Exit-8-style loop. Walk the corridor. If nothing is wrong, go through the
## far door; if anything is wrong, turn back and leave by the way you came.
## Eight correct calls in a row escape; one wrong call resets the count.

const TO_WIN: int = 8
const ANOMALY_CHANCE: float = 0.5
const NOTICE_AT: int = 3
const START: Vector2i = Vector2i(0, 1)

var grid: CellGrid = CellGrid.from_rows(["########", "........", "########"])
var walker: GridWalker = GridWalker.new(grid, START, 1)
var streak: int = 0
var loop_index: int = 0
var anomaly: int = -1
var props: Array[Prop] = []
var mistakes: int = 0
var _last_anomaly: int = -1


func _init(seed_value: int) -> void:
	super(seed_value)
	_start_loop(true)


func has_anomaly() -> bool:
	return anomaly >= 0


func walking_back() -> bool:
	return walker.facing == 3


func props_in(segment: int) -> Array[Prop]:
	return props.filter(func(p: Prop) -> bool: return p.cell.x == segment)


func actions() -> Array[StringName]:
	return [&"forward", &"turn_back"]


func hud_line() -> String:
	return "Loop %d   streak %d/%d   W forward, S turn back" % [loop_index + 1, streak, TO_WIN]


func bot_action() -> StringName:
	if has_anomaly() and not walking_back() and walker.cell.x >= NOTICE_AT:
		return &"turn_back"
	return &"forward"


func _on_perform(action: StringName) -> bool:
	match action:
		&"forward":
			if not walker.step():
				_resolve(walking_back())
		&"turn_back", &"turn_left", &"turn_right", &"back":
			walker.turn(true)
			walker.turn(true)
		&"look":
			pass
		_:
			return false
	return true


## The player left the corridor; `went_back` is their call "it was wrong".
func _resolve(went_back: bool) -> void:
	if went_back == has_anomaly():
		streak += 1
		_say("Correct. %d/%d." % [streak, TO_WIN] if streak < TO_WIN else "The exit opens.")
	else:
		streak = 0
		mistakes += 1
		_say("Wrong. The count resets. The corridor is the same again.")
	if streak >= TO_WIN:
		_finish(true)
		return
	loop_index += 1
	_start_loop(false)


func _start_loop(first: bool) -> void:
	walker.cell = START
	walker.facing = 1
	anomaly = -1
	if not first and rng.randf() < ANOMALY_CHANCE:
		while anomaly < 0 or anomaly == _last_anomaly:
			anomaly = rng.randi_range(0, AnomalyCatalog.ANOMALIES.size() - 1)
		_last_anomaly = anomaly
	props = AnomalyCatalog.props_for(anomaly)
