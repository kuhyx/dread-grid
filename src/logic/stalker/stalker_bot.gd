class_name StalkerBot
extends RefCounted
## The stalker concept's test driver (it reads hidden state through
## StalkerThreat). It never walks into a cell the stalker could see or hear
## soon. With no safe route to the goal it leapfrogs: it moves to the safely
## reachable locker nearest the goal and hides there until the stalker has
## wandered off. Caught in the open, it runs - without stepping where it
## would be heard - for a locker the stalker cannot see.

## Path distance the stalker must be at before the bot leaves a locker.
const LEAVE_DISTANCE: int = 6
const GO: Array[StringName] = [&"go_north", &"go_east", &"go_south", &"go_west"]


static func choose(game: StalkerGame) -> StringName:
	var exposed: Dictionary = StalkerThreat.exposure(game)
	var here: Vector2i = game.walker.cell
	if game.hidden:
		var leave: bool = game.seen_hiding or _can_leave(game, exposed)
		return &"hide" if leave else &"wait"
	if exposed.has(here):
		return _escape(game, exposed)
	var next: Vector2i = _plan_step(game, exposed)
	if next == here:
		return _idle(game)
	return go_towards(here, next)


## Nothing to do but wait: in a locker, hide; in the open, face a passage
## rather than a wall (it changes nothing in the rules, but the first-person
## autodrive then looks down a corridor while it waits).
static func _idle(game: StalkerGame) -> StringName:
	var walker: GridWalker = game.walker
	if game.on_locker():
		return &"hide"
	if game.grid.is_open(walker.ahead()):
		return &"wait"
	var right: Vector2i = walker.cell + CellGrid.DIRS[(walker.facing + 1) % 4]
	return &"turn_right" if game.grid.is_open(right) else &"turn_left"


## The nearest remaining key, or the exit once all three are held.
static func goal_of(game: StalkerGame) -> Vector2i:
	if game.keys_left.is_empty():
		return game.level.exit_cell
	var dist: PackedInt32Array = game.grid.distances(game.walker.cell)
	var best: Vector2i = game.keys_left[0]
	for key: Vector2i in game.keys_left:
		if dist[key.y * game.grid.width + key.x] < dist[best.y * game.grid.width + best.x]:
			best = key
	return best


## The compass action that steps from `from` to the adjacent `to`.
static func go_towards(from: Vector2i, to: Vector2i) -> StringName:
	return GO[CellGrid.DIRS.find(to - from)]


## The next cell: along a safe route to the goal if there is one, else
## towards the staging locker, else as far from the stalker as unexposed
## cells go; here means stay (and hide, on a locker).
static func _plan_step(game: StalkerGame, exposed: Dictionary) -> Vector2i:
	var here: Vector2i = game.walker.cell
	var next: Vector2i = _safe_step(game, goal_of(game), exposed)
	if next == here:
		next = _safe_step(game, _staging(game, exposed), exposed)
	if next == here and not game.on_locker():
		next = _safe_step(game, _retreat(game, exposed), exposed)
	return next


## The first cell of a route to `to` through unexposed cells, or here.
static func _safe_step(game: StalkerGame, to: Vector2i, exposed: Dictionary) -> Vector2i:
	var route: Array[Vector2i] = game.grid.path(game.walker.cell, to, exposed)
	if exposed.has(to) or route.size() < 2:
		return game.walker.cell
	return route[1]


## Of the lockers reachable through unexposed cells (this one included), the
## one nearest the goal; nearer to here breaks ties. Here if there is none.
static func _staging(game: StalkerGame, exposed: Dictionary) -> Vector2i:
	var here: Vector2i = game.walker.cell
	var w: int = game.grid.width
	var reach: PackedInt32Array = game.grid.distances(here, exposed)
	var to_goal: PackedInt32Array = game.grid.distances(goal_of(game))
	var best: Vector2i = here
	var best_score: int = 1 << 30
	for locker: Vector2i in game.level.lockers:
		var d: int = reach[locker.y * w + locker.x]
		var score: int = to_goal[locker.y * w + locker.x] * 100 + d
		if d >= 0 and not exposed.has(locker) and score < best_score:
			best = locker
			best_score = score
	return best


## The unexposed cell reachable through unexposed cells that is farthest
## (by path) from the stalker: where to wait when there is no locker.
static func _retreat(game: StalkerGame, exposed: Dictionary) -> Vector2i:
	var w: int = game.grid.width
	var reach: PackedInt32Array = game.grid.distances(game.walker.cell, exposed)
	var away: PackedInt32Array = game.grid.distances(game.hunter.cell)
	var best: Vector2i = game.walker.cell
	for c: Vector2i in game.grid.floor_cells():
		var better: bool = away[c.y * w + c.x] > away[best.y * w + best.x]
		if reach[c.y * w + c.x] > 0 and not exposed.has(c) and better:
			best = c
	return best


static func _can_leave(game: StalkerGame, exposed: Dictionary) -> bool:
	var hunter: StalkerHunter = game.hunter
	return (
		not exposed.has(game.walker.cell)
		and not hunter.hunting
		and not hunter.searching()
		and game.stalker_distance() >= LEAVE_DISTANCE
		and _plan_step(game, exposed) != game.walker.cell
	)


## Exposed in the open: hide if this is a locker it cannot see, else run for
## a refuge without stepping where it would hear or see the move. If there
## is no such route, keep still - unless cornered, then run anyway (never
## next to it).
static func _escape(game: StalkerGame, exposed: Dictionary) -> StringName:
	var here: Vector2i = game.walker.cell
	if game.on_locker() and not game.sees_player():
		return &"hide"
	var blocked: Dictionary = StalkerThreat.detected_now(game)
	blocked.merge(StalkerThreat.contact(game))
	var target: Vector2i = StalkerThreat.refuge(game, exposed, game.grid.distances(here, blocked))
	if target == here and _cornered(game):
		blocked = StalkerThreat.contact(game)
		target = StalkerThreat.refuge(game, exposed, game.grid.distances(here, blocked))
	var route: Array[Vector2i] = game.grid.path(here, target, blocked)
	if route.size() < 2:
		return &"wait"
	return go_towards(here, route[1])


## Staying still is no longer an option: it hunts, is two steps away, or is
## about to walk through this cell.
static func _cornered(game: StalkerGame) -> bool:
	var hunter: StalkerHunter = game.hunter
	return (
		hunter.hunting
		or game.stalker_distance() <= 2
		or hunter.upcoming(StalkerThreat.LOOKAHEAD).has(game.walker.cell)
	)
