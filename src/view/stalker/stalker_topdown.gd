extends TopdownView
## Stalker from above: fog of war, a vision cone ahead of you, keys, lockers
## and the exit once seen, the stalker only while it is in sight, and a
## ripple of noise every time you take a step.

const RIPPLE_TIME: float = 0.9
const CONE_HALF: float = 0.55
const KEY_GOLD: Color = Color(0.95, 0.8, 0.2)
const LOCKER_GREY: Color = Color(0.5, 0.52, 0.55)
const EXIT_RED: Color = Color(0.8, 0.1, 0.08)
const MOVES: Array[StringName] = [
	&"forward", &"back", &"go_north", &"go_east", &"go_south", &"go_west"
]

var game: StalkerGame
## Each ripple: x, y = centre on the board, z = game time it started.
var _ripples: Array[Vector3] = []
var _heard_steps: int = 0


func make_concept(seed_value: int) -> Concept:
	game = StalkerGame.new(seed_value)
	return game


func concept_id() -> String:
	return "stalker"


func extra_keys() -> Dictionary:
	return {KEY_E: &"hide", KEY_Q: &"listen", KEY_SPACE: &"wait"}


func build_board() -> void:
	wall_color = Color(0.42, 0.4, 0.36)
	floor_color = Color(0.17, 0.16, 0.15)
	hud.push("Three keys, then the red door. E hides in a locker, Q listens.")


func view_grid() -> CellGrid:
	return game.grid


func viewer() -> GridWalker:
	return game.walker


func refresh() -> void:
	super.refresh()
	_ripples = _ripples.filter(func(r: Vector3) -> bool: return game.elapsed - r.z < RIPPLE_TIME)
	if game.hunter.steps != _heard_steps:
		_heard_steps = game.hunter.steps
		StalkerAudio.thud(self, game)


func on_acted(action: StringName) -> void:
	if action in MOVES:
		var p: Vector2 = center(game.walker.cell)
		_ripples.append(Vector3(p.x, p.y, game.elapsed))
		Sfx.play(self, Sfx.sample("footstep"), -8.0)
	elif action == &"listen":
		StalkerAudio.beep(self, game)


func draw_overlay() -> void:
	_draw_cone()
	for locker: Vector2i in game.level.lockers:
		if seen.has(locker):
			board.draw_rect(cell_rect(locker, 7.0), LOCKER_GREY)
			board.draw_line(
				center(locker) - Vector2(0, 8), center(locker) + Vector2(0, 8), Color.BLACK
			)
	var exit_cell: Vector2i = game.level.exit_cell
	if seen.has(exit_cell):
		board.draw_rect(cell_rect(exit_cell, 3.0), EXIT_RED)
		draw_text_at(exit_cell, "EXIT", Color.WHITE, 10)
	for key: Vector2i in game.keys_left:
		if seen.has(key):
			var p: Vector2 = center(key)
			var diamond: PackedVector2Array = [
				p + Vector2(0, -7), p + Vector2(7, 0), p + Vector2(0, 7), p + Vector2(-7, 0)
			]
			board.draw_colored_polygon(diamond, KEY_GOLD)
	_draw_ripples()
	if is_visible_cell(game.hunter.cell):
		_draw_stalker()
	var me: Color = Color(0.9, 0.85, 0.6, 0.35 if game.hidden else 1.0)
	draw_walker(game.walker, me)


## A translucent wedge ahead of the player: what the flashlight reaches.
func _draw_cone() -> void:
	if game.hidden:
		return
	var p: Vector2 = center(game.walker.cell)
	var ahead: Vector2 = Vector2(game.walker.forward_vector())
	var reach: float = TILE * (SIGHT + 0.5)
	var points: Array[Vector2] = [p]
	for i: int in 9:
		var angle: float = lerpf(-CONE_HALF, CONE_HALF, float(i) / 8.0)
		points.append(p + ahead.rotated(angle) * reach)
	board.draw_colored_polygon(PackedVector2Array(points), Color(1.0, 0.95, 0.7, 0.1))


func _draw_ripples() -> void:
	for r: Vector3 in _ripples:
		var age: float = (game.elapsed - r.z) / RIPPLE_TIME
		var radius: float = lerpf(6.0, TILE * StalkerGame.HEARING, age)
		board.draw_arc(
			Vector2(r.x, r.y), radius, 0.0, TAU, 32, Color(0.7, 0.75, 0.9, 1.0 - age), 1.5
		)


func _draw_stalker() -> void:
	var p: Vector2 = center(game.hunter.cell)
	var eyes: Color = Color(1.0, 0.1, 0.1) if game.hunter.hunting else Color(0.6, 0.1, 0.1)
	board.draw_circle(p, 11.0, Color(0.02, 0.02, 0.02))
	board.draw_arc(p, 11.0, 0.0, TAU, 24, eyes, 1.0)
	var f: Vector2 = Vector2(CellGrid.DIRS[game.hunter.facing])
	var side: Vector2 = Vector2(-f.y, f.x)
	board.draw_circle(p + f * 5.0 + side * 3.0, 1.8, eyes)
	board.draw_circle(p + f * 5.0 - side * 3.0, 1.8, eyes)
