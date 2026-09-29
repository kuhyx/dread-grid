class_name StalkerThreat
extends RefCounted
## What the stalker bot fears, as cell sets. `exposure` is every cell the
## stalker could see or hear soon; `detected_now` is every cell where a step
## would be seen or heard right away. Both read hidden state (its route).

const LOOKAHEAD: int = 5
## It may turn any way at a junction or pick a new patrol goal, so every cell
## this close to it counts as somewhere it may be next.
const ANY_WAY: int = 2
## Extra cells of sight and hearing the bot keeps clear of.
const MARGIN: int = 1


## Every cell the stalker could see or hear from anywhere within ANY_WAY
## steps of it or along its route for the next few footfalls (twice as many
## while it runs).
static func exposure(game: StalkerGame) -> Dictionary:
	var hunter: StalkerHunter = game.hunter
	var floors: Array[Vector2i] = game.grid.floor_cells()
	var around: PackedInt32Array = game.grid.distances(hunter.cell)
	var threats: Array[Vector2i] = floors.filter(
		func(c: Vector2i) -> bool: return around[c.y * game.grid.width + c.x] <= ANY_WAY
	)
	threats.append_array(hunter.upcoming(LOOKAHEAD * (2 if hunter.hunting else 1)))
	var out: Dictionary = {}
	for t: Vector2i in threats:
		var dist: PackedInt32Array = game.grid.distances(t)
		for c: Vector2i in floors:
			var d: int = dist[c.y * game.grid.width + c.x]
			var heard: bool = d >= 0 and d <= StalkerGame.HEARING + MARGIN
			if not out.has(c) and (heard or could_see(game, t, c, MARGIN)):
				out[c] = true
	return out


## Cells a step into would be heard, or (before a hunt) seen, from where
## the stalker stands or from any cell next to it; never the player's own.
static func detected_now(game: StalkerGame) -> Dictionary:
	var hunter: StalkerHunter = game.hunter
	var near: PackedInt32Array = game.grid.distances(hunter.cell)
	var eyes: Array[Vector2i] = [hunter.cell]
	eyes.append_array(game.grid.open_neighbors(hunter.cell))
	var out: Dictionary = {}
	for c: Vector2i in game.grid.floor_cells():
		var heard: bool = near[c.y * game.grid.width + c.x] <= StalkerGame.HEARING + MARGIN
		var seen: bool = (
			not hunter.hunting
			and eyes.any(func(e: Vector2i) -> bool: return could_see(game, e, c, 0))
		)
		if c != game.walker.cell and (heard or seen):
			out[c] = true
	return out


## The stalker's cell and the cells next to it: never step there.
static func contact(game: StalkerGame) -> Dictionary:
	var out: Dictionary = {game.hunter.cell: true}
	for n: Vector2i in game.grid.open_neighbors(game.hunter.cell):
		out[n] = true
	return out


static func could_see(game: StalkerGame, from: Vector2i, c: Vector2i, margin: int) -> bool:
	return (
		Vector2(c - from).length() <= StalkerGame.SIGHT + margin
		and game.grid.line_of_sight(from, c)
	)


## Where to run from `here`, given reach distances `dist` that avoid the
## blocked cells: the cheapest unexposed cell or unseen locker (lockers
## count as closer, much closer while it hunts). Returns here if none.
static func refuge(game: StalkerGame, exposed: Dictionary, dist: PackedInt32Array) -> Vector2i:
	var hunter: StalkerHunter = game.hunter
	var bonus: int = 6 if hunter.hunting else 3
	var best: Vector2i = game.walker.cell
	var best_score: int = 1 << 30
	for c: Vector2i in game.grid.floor_cells():
		var d: int = dist[c.y * game.grid.width + c.x]
		var locker: bool = game.level.lockers.has(c) and not could_see(game, hunter.cell, c, 0)
		var score: int = d * 2 - (bonus if locker else 0)
		if d > 0 and score < best_score and (locker or not exposed.has(c)):
			best = c
			best_score = score
	return best
