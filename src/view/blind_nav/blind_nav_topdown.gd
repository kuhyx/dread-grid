extends TopdownView
## Blind Descent from above - a black chart, not a window. Only what the
## instruments return is drawn: your own track, ping returns that fade in
## 2 s, the photo patch while it lasts, and the waypoints as coordinate
## crosses. No fog-of-war grid: view_grid() is null and all of it is overlay.

const SONAR: Color = Color(0.35, 0.95, 0.6)
const TRACK: Color = Color(0.25, 0.38, 0.45)
const CHART: Color = Color(0.07, 0.12, 0.13)
const TODO: Color = Color(0.95, 0.7, 0.25)
const DONE: Color = Color(0.35, 0.55, 0.4)
const ROCK: Color = Color(0.55, 0.53, 0.5)
const WATER: Color = Color(0.03, 0.08, 0.09)

var nav: BlindNav
var _flash: float = 0.0
var _seen_crashes: int = 0
var _tint: ColorRect = ColorRect.new()


func make_concept(seed_value: int) -> Concept:
	nav = BlindNav.new(seed_value)
	return nav


func concept_id() -> String:
	return "blind_nav"


func extra_keys() -> Dictionary:
	return {KEY_SPACE: &"ping", KEY_F: &"photo"}


func view_grid() -> CellGrid:
	return null


func viewer() -> GridWalker:
	return nav.walker


func build_board() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.color = Color(0.8, 0.0, 0.0, 0.0)
	layer.add_child(_tint)
	cam.zoom = Vector2(1.7, 1.7)
	cam.position = center(nav.walker.cell)
	hud.push("No window. Coordinates, sonar (Space) and a slow camera (F).")
	hud.push("Log all four waypoints. Every collision costs a quarter of the hull.")


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_tint.color.a = _flash * 0.35
	super(delta)


func on_acted(action: StringName) -> void:
	if nav.crashes > _seen_crashes:
		_seen_crashes = nav.crashes
		_crash()
	elif action == &"ping":
		Sfx.play(self, Sfx.tone(880.0, 0.5), -8.0)
	elif action == &"photo":
		Sfx.play(self, Sfx.tone(140.0, 0.4, 0.0, 0.7), -12.0)


func draw_overlay() -> void:
	_draw_chart()
	for c: Vector2i in nav.track:
		board.draw_circle(center(c), 2.5, TRACK)
	_draw_photo()
	_draw_ping()
	for i: int in nav.waypoints.size():
		_draw_waypoint(i)
	draw_walker(nav.walker, Color(0.95, 0.2, 0.15) if _flash > 0.0 else Color(0.95, 0.9, 0.7))


func _crash() -> void:
	_flash = 1.0
	Sfx.play(self, Sfx.sample("crunch"), -2.0)
	Sfx.play(self, Sfx.tone(55.0, 0.8, 0.0, 0.8), -4.0)


## A faint coordinate grid every 5 cells over the whole trench.
func _draw_chart() -> void:
	var size: float = BlindTrench.SIZE * TILE
	for i: int in range(0, BlindTrench.SIZE + 1, 5):
		var at: float = i * TILE
		board.draw_line(Vector2(at, 0), Vector2(at, size), CHART, 1.0)
		board.draw_line(Vector2(0, at), Vector2(size, at), CHART, 1.0)
		draw_text_at(Vector2i(i, -1), str(i), CHART.lightened(0.3), 10)
		draw_text_at(Vector2i(-1, i), str(i), CHART.lightened(0.3), 10)


func _draw_ping() -> void:
	if nav.pings == 0 or nav.ping_age >= BlindNav.RETURN_TIME:
		return
	var fade: float = 1.0 - nav.ping_age / BlindNav.RETURN_TIME
	var origin: Vector2 = center(nav.ping_from)
	var reach: float = BlindSonar.RANGE * TILE
	board.draw_arc(origin, reach * (1.0 - fade), 0.0, TAU, 48, Color(SONAR, fade * 0.5), 1.5)
	for i: int in BlindSonar.DIRS8.size():
		var d: Vector2 = Vector2(BlindSonar.DIRS8[i])
		var k: int = nav.ping_ranges[i]
		var tip: Vector2 = origin + d * TILE * (k if k > 0 else BlindSonar.RANGE)
		board.draw_line(origin, tip, Color(SONAR, fade * 0.18), 1.0)
		if k > 0:
			board.draw_circle(tip - d * TILE * 0.35, 5.0, Color(SONAR, fade))


func _draw_photo() -> void:
	if nav.photo_cells.is_empty() or not (nav.photo_showing() or nav.locked()):
		return
	if nav.locked():
		var blink: float = 0.25 + 0.2 * sin(nav.elapsed * 12.0)
		for c: Vector2i in nav.photo_cells:
			board.draw_rect(cell_rect(c, 2.0), Color(SONAR, blink), false, 1.0)
		return
	var fade: float = minf(1.0, nav.photo_left / 0.5)
	for c: Vector2i in nav.photo_cells:
		var grain: float = float(absi(hash(c)) % 100) / 400.0
		var base: Color = WATER if nav.grid.is_open(c) else ROCK.darkened(grain)
		board.draw_rect(cell_rect(c), Color(base.lightened(grain * 0.3), fade))
	if nav.photo_eye:
		_draw_eye(fade)


## The fourth photo: something enormous across the far rows, looking back.
func _draw_eye(fade: float) -> void:
	var far: Vector2i = nav.photo_cells[BlindSonar.MID]
	var near: Vector2i = nav.photo_cells[BlindSonar.PATCH * (BlindSonar.PATCH - 1) + BlindSonar.MID]
	var fwd: Vector2 = Vector2(far - near).normalized()
	var at: Vector2 = center(far) - fwd * TILE * 0.6
	var turn: float = fwd.angle() + PI / 2.0
	board.draw_set_transform(at, turn, Vector2(2.2, 1.0))
	board.draw_circle(Vector2.ZERO, TILE * 1.1, Color(0.75, 0.7, 0.55, fade))
	board.draw_set_transform(at, turn, Vector2.ONE)
	board.draw_circle(Vector2.ZERO, TILE * 0.8, Color(0.45, 0.05, 0.03, fade))
	board.draw_set_transform(at, turn, Vector2(0.2, 1.0))
	board.draw_circle(Vector2.ZERO, TILE * 0.75, Color(0.0, 0.0, 0.0, fade))
	board.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_waypoint(i: int) -> void:
	var w: Vector2i = nav.waypoints[i]
	var color: Color = DONE if nav.visited[i] else TODO
	var p: Vector2 = center(w)
	var arm: float = TILE * 0.45
	board.draw_line(p - Vector2(arm, arm), p + Vector2(arm, arm), color, 2.0)
	board.draw_line(p - Vector2(arm, -arm), p + Vector2(arm, -arm), color, 2.0)
	var label: String = "%s %d,%d" % [BlindTrench.LABELS[i], w.x, w.y]
	draw_text_at(w + Vector2i(1, 0), label, color, 11)
