class_name FootageBot
extends RefCounted
## Found Footage's test driver; it reads the hidden event table. It walks,
## never crossing an untriggered event's ring, to the edge cell whose next
## step in puts that event in frame; rolls tape; steps in; films; stops the
## tape again to save battery.

const FAR: int = 1 << 30


static func next_action(tape: FoundFootage) -> StringName:
	var live: FootageEvent = tape.live_event()
	if live != null:
		return _film(tape, live)
	return _go_to_next(tape)


## Head for the cheapest way into a waiting event's ring (cross other rings
## only if there is no other way).
static func _go_to_next(tape: FoundFootage) -> StringName:
	var rings: Dictionary = _rings(tape)
	var plan: Array[Vector2i] = _plan(tape, rings)
	if plan.is_empty():
		rings.clear()
		plan = _plan(tape, rings)
	if plan.is_empty():
		return &"rec_stop" if tape.recording else &"wait"
	return _step_in(tape, plan, rings)


## A facing from which a walker on `cell` has `target` in frame (the current
## facing first), or -1 if there is none.
static func seeing_facing(tape: FoundFootage, cell: Vector2i, target: Vector2i) -> int:
	for turn: int in 4:
		var dir: int = (tape.walker.facing + turn) % 4
		var probe: GridWalker = GridWalker.new(tape.grid, cell, dir)
		if probe.sees(target, FoundFootage.VIEW_RANGE, FoundFootage.VIEW_CONE):
			return dir
	return -1


## Something is playing: roll tape, turn to it, or close in until in frame.
static func _film(tape: FoundFootage, event: FootageEvent) -> StringName:
	if not tape.recording:
		return &"rec_start"
	var dir: int = seeing_facing(tape, tape.walker.cell, event.cell)
	if dir >= 0:
		return FoundFootage.FACE_ACTIONS[dir]
	var route: Array[Vector2i] = tape.grid.path(tape.walker.cell, event.cell)
	return tape.walker.action_towards(route[1]) if route.size() > 1 else &"wait"


## plan = [edge, inside]: walk to the edge with the tape stopped, roll it
## there, face the inside cell and step in.
static func _step_in(tape: FoundFootage, plan: Array[Vector2i], rings: Dictionary) -> StringName:
	var walker: GridWalker = tape.walker
	var at_edge: bool = walker.cell == plan[0]
	if tape.recording != at_edge:
		return &"rec_start" if at_edge else &"rec_stop"
	if at_edge:
		var dir: int = CellGrid.DIRS.find(plan[1] - plan[0])
		return &"forward" if walker.facing == dir else FoundFootage.FACE_ACTIONS[dir]
	var route: Array[Vector2i] = tape.grid.path(walker.cell, plan[0], rings)
	return walker.action_towards(route[1])


## Every cell that would set off an event that has not happened yet.
static func _rings(tape: FoundFootage) -> Dictionary:
	var out: Dictionary = {}
	for c: Vector2i in tape.grid.floor_cells():
		for event: FootageEvent in tape.events:
			if event.phase == FootageEvent.Phase.WAITING and event.in_ring(c):
				out[c] = true
	return out


## The cheapest [edge, inside] over all waiting events, or [] if none.
static func _plan(tape: FoundFootage, rings: Dictionary) -> Array[Vector2i]:
	var dist: PackedInt32Array = tape.grid.distances(tape.walker.cell, rings)
	var best: Array[Vector2i] = []
	var best_cost: int = FAR
	for event: FootageEvent in tape.events:
		if event.phase != FootageEvent.Phase.WAITING:
			continue
		for inside: Vector2i in tape.grid.floor_cells():
			if not event.in_ring(inside):
				continue
			for edge: Vector2i in tape.grid.open_neighbors(inside):
				var pair: Array[Vector2i] = [edge, inside]
				var cost: int = _entry_cost(tape, event, pair, dist)
				if cost < best_cost:
					best_cost = cost
					best = pair
	return best


## Steps to reach `pair[0]` plus one if stepping into `pair[1]` leaves the
## event out of frame and a turn is needed; FAR if the entry is unusable.
static func _entry_cost(
	tape: FoundFootage, event: FootageEvent, pair: Array[Vector2i], dist: PackedInt32Array
) -> int:
	var edge: Vector2i = pair[0]
	var steps: int = dist[edge.y * tape.grid.width + edge.x]
	if steps < 0 or event.in_ring(edge):
		return FAR
	var dir: int = CellGrid.DIRS.find(pair[1] - edge)
	var probe: GridWalker = GridWalker.new(tape.grid, pair[1], dir)
	if probe.sees(event.cell, FoundFootage.VIEW_RANGE, FoundFootage.VIEW_CONE):
		return steps
	return steps + 1 if seeing_facing(tape, pair[1], event.cell) >= 0 else FAR
