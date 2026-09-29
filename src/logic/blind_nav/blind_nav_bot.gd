class_name BlindNavBot
extends RefCounted
## Blind Descent's test driver. It reads the true map: BFS to the nearest
## unlogged waypoint along open water only, so it never collides. It pings
## every few moves and takes a photo now and then, for show (and so an
## autodrive screenshot has something on the instruments).

const PING_EVERY: int = 4
const PHOTO_EVERY: int = 14
const FIRST_PHOTO: int = 7

var _route: Array[Vector2i] = []
var _target: int = -1


func next_action(nav: BlindNav) -> StringName:
	if nav.locked():
		return &""
	var chore: StringName = _instrument(nav)
	if chore != &"":
		return chore
	var step: Vector2i = _next_cell(nav)
	return &"" if step == nav.walker.cell else nav.walker.action_towards(step)


## A ping every few moves, a photo now and then; &"" when neither is due.
func _instrument(nav: BlindNav) -> StringName:
	if nav.pings == 0 or nav.moves - nav.ping_move >= PING_EVERY:
		return &"ping"
	var photo_due: int = FIRST_PHOTO if nav.photos == 0 else PHOTO_EVERY
	return &"photo" if nav.moves - nav.photo_move >= photo_due else &""


## The next cell on the route to the nearest unlogged waypoint; re-planned
## when the target is logged or the sub is off the route.
func _next_cell(nav: BlindNav) -> Vector2i:
	var here: Vector2i = nav.walker.cell
	var at: int = _route.find(here)
	if _target < 0 or nav.visited[_target] or at < 0 or at + 1 >= _route.size():
		_plan(nav)
		at = 0
	return _route[at + 1] if at + 1 < _route.size() else here


func _plan(nav: BlindNav) -> void:
	var here: Vector2i = nav.walker.cell
	var dist: PackedInt32Array = nav.grid.distances(here)
	_target = -1
	var best: int = -1
	for i: int in nav.waypoints.size():
		var w: Vector2i = nav.waypoints[i]
		var d: int = dist[w.y * nav.grid.width + w.x]
		if not nav.visited[i] and d > 0 and (best < 0 or d < best):
			best = d
			_target = i
	_route = [here]
	if _target >= 0:
		_route = nav.grid.path(here, nav.waypoints[_target])
