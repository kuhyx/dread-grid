class_name WrongPlaceBot
extends RefCounted
## Wrong Place's test driver. It reads which objects are wrong (hidden state),
## walks to the nearest unflagged one, turns to face it and flags it; with all
## of them flagged it walks out of the back door. Stateless: every beat is
## decided from the game as it is, so a refused action cannot desync it.


static func next_action(game: WrongPlace) -> StringName:
	var walker: GridWalker = game.walker
	var dist: PackedInt32Array = game.grid.distances(walker.cell, game.solid)
	var best: Prop = null
	var best_stand: Vector2i = Vector2i(-1, -1)
	var best_d: int = -1
	for prop: Prop in game.props:
		if not game.is_wrong(prop) or game.flagged.has(prop.id):
			continue
		for stand: Vector2i in game.stand_cells(prop):
			var d: int = dist[stand.y * game.grid.width + stand.x]
			if d >= 0 and (best_d < 0 or d < best_d):
				best = prop
				best_stand = stand
				best_d = d
	if best == null:
		return _step_towards(game, game.back_door)
	if best_d == 0:
		return _face_and_flag(walker, best.cell)
	return _step_towards(game, best_stand)


## One step along the shortest furniture-free path to `goal`.
static func _step_towards(game: WrongPlace, goal: Vector2i) -> StringName:
	var route: Array[Vector2i] = game.grid.path(game.walker.cell, goal, game.solid)
	if route.size() < 2:
		return &""
	return game.walker.action_towards(route[1])


## Turn until the object is straight ahead, then flag it. Never "forward" or
## "back": those would walk into the object and be refused forever.
static func _face_and_flag(walker: GridWalker, object_cell: Vector2i) -> StringName:
	var want: int = CellGrid.DIRS.find(object_cell - walker.cell)
	if want == walker.facing:
		return &"flag"
	if want == (walker.facing + 1) % 4:
		return &"turn_right"
	return &"turn_left"
