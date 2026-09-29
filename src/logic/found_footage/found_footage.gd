class_name FoundFootage
extends Concept
## Found Footage: an abandoned sanatorium, a camcorder and seven things that
## happen exactly once. Each plays for a few seconds when you come near; it is
## on tape only if you are recording and it is in view (facing, range, line of
## sight). Tape five before the battery dies or too few are left to film.

signal event_started(event: FootageEvent)
signal event_captured(event: FootageEvent)

const TO_WIN: int = 5
const VIEW_RANGE: int = 6
const VIEW_CONE: float = 0.6
## Six minutes of continuous recording empties the battery; idle, thirty.
const RECORD_DRAIN: float = 100.0 / 360.0
const IDLE_DRAIN: float = 100.0 / 1800.0
const FACE_ACTIONS: Array[StringName] = [&"face_north", &"face_east", &"face_south", &"face_west"]
const GO_ACTIONS: Array[StringName] = [&"go_north", &"go_east", &"go_south", &"go_west"]

var flip: Vector2i
var grid: CellGrid
var walker: GridWalker
var events: Array[FootageEvent] = []
var battery: float = 100.0
var recording: bool = false
var captured: int = 0


func _init(seed_value: int) -> void:
	super(seed_value)
	flip = Vector2i(rng.randi_range(0, 1), rng.randi_range(0, 1))
	grid = CellGrid.from_rows(FootageData.rows_for(flip))
	var start: Vector2i = FootageData.flipped(FootageData.START, flip)
	walker = GridWalker.new(grid, start, FootageData.flipped_facing(FootageData.START_FACING, flip))
	for row: Array in FootageData.EVENTS:
		events.append(FootageEvent.from_row(row, grid, flip))
	_deal()


func actions() -> Array[StringName]:
	var out: Array[StringName] = [
		&"forward", &"back", &"turn_left", &"turn_right", &"record", &"rec_start", &"rec_stop"
	]
	out.append_array(FACE_ACTIONS)
	out.append_array(GO_ACTIONS)
	out.append(&"wait")
	out.append(&"look")
	return out


func hud_line() -> String:
	return (
		"%s   BAT %d%%   %s   captured %d/%d   Space record"
		% ["REC" if recording else "STBY", ceili(battery), timecode(), captured, TO_WIN]
	)


func bot_action() -> StringName:
	return FootageBot.next_action(self)


## Is the event in the camcorder's frame right now?
func in_view(event: FootageEvent) -> bool:
	return walker.sees(event.cell, VIEW_RANGE, VIEW_CONE)


## The playing event nobody has filmed yet, or null.
func live_event() -> FootageEvent:
	for event: FootageEvent in events:
		if event.is_live():
			return event
	return null


## Events that can still end up on tape: untriggered or playing unfilmed.
func still_possible() -> int:
	var count: int = 0
	for event: FootageEvent in events:
		if event.phase == FootageEvent.Phase.WAITING or event.is_live():
			count += 1
	return count


func timecode() -> String:
	return FootageProse.timecode(elapsed, true)


func room_name() -> String:
	return FootageData.room_at(FootageData.flipped(walker.cell, flip))


func _on_perform(action: StringName) -> bool:
	var done: bool = _move(action) or _camera(action)
	if done:
		_update_events()
		_judge()
	return done


## Trigger, film, count down, then settle the game - in that order, so an
## event filmed on its last frame still counts and a win beats a flat battery.
func _on_advance(delta: float) -> void:
	battery = maxf(0.0, battery - (RECORD_DRAIN if recording else IDLE_DRAIN) * delta)
	_update_events()
	for event: FootageEvent in events:
		if event.tick(delta) and not event.captured:
			_say("It is gone. You missed %s." % event.label)
	_judge()


## Shuffle the spots within each FootageData.SWAPS group (Fisher-Yates on
## the concept's rng, so a seed always deals the same building).
func _deal() -> void:
	for group: Array in FootageData.SWAPS:
		var members: Array[FootageEvent] = events.filter(
			func(e: FootageEvent) -> bool: return group.has(e.id)
		)
		var spots: Array[Vector2i] = []
		for event: FootageEvent in members:
			spots.append(event.cell)
		for i: int in range(spots.size() - 1, 0, -1):
			var j: int = rng.randi_range(0, i)
			var spot: Vector2i = spots[i]
			spots[i] = spots[j]
			spots[j] = spot
		for i: int in members.size():
			members[i].place(spots[i])


func _move(action: StringName) -> bool:
	var dir: int = maxi(FACE_ACTIONS.find(action), GO_ACTIONS.find(action))
	if dir >= 0:
		return _face(dir, GO_ACTIONS.has(action))
	match action:
		&"turn_left", &"turn_right":
			walker.turn(action == &"turn_right")
		&"forward", &"back":
			return walker.step(action == &"forward")
		_:
			return false
	return true


## Face a compass direction and, if `step`, walk one cell that way.
func _face(dir: int, step: bool) -> bool:
	if step and not grid.is_open(walker.cell + CellGrid.DIRS[dir]):
		return false
	walker.facing = dir
	return not step or walker.step()


func _camera(action: StringName) -> bool:
	match action:
		&"record":
			recording = not recording
		&"rec_start":
			recording = true
		&"rec_stop":
			recording = false
		&"wait", &"look":
			pass
		_:
			return false
	return true


func _update_events() -> void:
	for event: FootageEvent in events:
		if event.phase == FootageEvent.Phase.WAITING and event.in_ring(walker.cell):
			event.start()
			_say(event.text % FootageProse.where(walker, event.cell))
			event_started.emit(event)
	for event: FootageEvent in events:
		if event.is_live() and recording and in_view(event):
			event.captured = true
			captured += 1
			_say("Got it on tape: %s. %d/%d." % [event.label, captured, TO_WIN])
			event_captured.emit(event)


func _judge() -> void:
	if captured >= TO_WIN:
		_say("Five on tape. Nobody can say you made it up.")
		_finish(true)
	elif battery <= 0.0:
		_say("The battery dies. The tape is useless now.")
		_finish(false)
	elif captured + still_possible() < TO_WIN:
		_say("Too few left to film. The tape is useless now.")
		_finish(false)
