extends TopdownView
## Found Footage from above: fog of war, the camcorder's view cone (faint on
## standby, green and brighter while recording, the cells it really sees
## tinted) and events drawn while they play and can be seen. The camcorder's
## REC, timecode and battery bar sit on screen.

const CONE_STEPS: int = 12
const DARK: Color = Color(0.02, 0.02, 0.02)
const PALE: Color = Color(0.85, 0.83, 0.75)
const WOOD: Color = Color(0.45, 0.3, 0.16)

var tape: FoundFootage
var overlay: FootageCamOverlay = FootageCamOverlay.new(false)


func make_concept(seed_value: int) -> Concept:
	tape = FoundFootage.new(seed_value)
	return tape


func concept_id() -> String:
	return "found_footage"


func extra_keys() -> Dictionary:
	return {KEY_SPACE: &"record"}


func build_board() -> void:
	wall_color = Color(0.4, 0.38, 0.33)
	floor_color = Color(0.16, 0.15, 0.13)
	add_child(overlay)
	Wire.link(tape.event_started, _on_event_started)
	hud.push("Something happens in here. Get five of it on tape. Space records.")


func view_grid() -> CellGrid:
	return tape.grid


func viewer() -> GridWalker:
	return tape.walker


func refresh() -> void:
	super.refresh()
	overlay.show_state(tape)


func on_acted(action: StringName) -> void:
	if action == &"forward" or action == &"back":
		Sfx.play(self, Sfx.sample("footstep"), -8.0)


func draw_overlay() -> void:
	_draw_cone()
	for event: FootageEvent in tape.events:
		var shown: bool = is_visible_cell(event.cell) or tape.in_view(event)
		if event.phase == FootageEvent.Phase.ACTIVE and shown:
			_draw_event(event)
	draw_walker(tape.walker, Color(0.9, 0.85, 0.6))


func _draw_cone() -> void:
	var walker: GridWalker = tape.walker
	var rec: bool = tape.recording
	var reach: int = FoundFootage.VIEW_RANGE
	for dy: int in range(-reach, reach + 1):
		for dx: int in range(-reach, reach + 1):
			var c: Vector2i = walker.cell + Vector2i(dx, dy)
			if tape.grid.is_open(c) and walker.sees(c, reach, FoundFootage.VIEW_CONE):
				board.draw_rect(cell_rect(c), Color(0.35, 1.0, 0.4, 0.16 if rec else 0.04))
	var p: Vector2 = center(walker.cell)
	var half: float = acos(FoundFootage.VIEW_CONE)
	var ahead: float = Vector2(walker.forward_vector()).angle()
	var points: Array[Vector2] = [p]
	for i: int in CONE_STEPS + 1:
		var angle: float = ahead - half + 2.0 * half * float(i) / CONE_STEPS
		points.append(p + Vector2.from_angle(angle) * reach * TILE)
	var tint: Color = Color(0.35, 1.0, 0.4, 0.14) if rec else Color(0.9, 0.9, 0.8, 0.05)
	board.draw_colored_polygon(PackedVector2Array(points), tint)


func _draw_event(event: FootageEvent) -> void:
	var p: Vector2 = center(event.cell)
	var t: float = event.progress()
	var across: Vector2 = (
		Vector2(0, 1) if tape.grid.is_open(event.cell + Vector2i.LEFT) else Vector2(1, 0)
	)
	var to_player: Vector2 = (center(tape.walker.cell) - p).normalized()
	board.draw_arc(p, TILE * (0.6 + 0.15 * sin(t * 30.0)), 0.0, TAU, 20, Color(0.9, 0.2, 0.15), 2.0)
	match event.kind:
		"shadow":
			board.draw_circle(p + across * lerpf(-0.45, 0.45, minf(1.0, t * 2.0)) * TILE, 9.0, DARK)
		"door":
			var swing: Vector2 = across.rotated(PI / 2.0 * (1.0 - smoothstep(0.08, 0.16, t)))
			var hinge: Vector2 = p - across * TILE * 0.5
			board.draw_line(hinge, hinge + swing * TILE, WOOD, 5.0)
		"face":
			if fposmod(t * 23.0, 1.0) > 0.45:
				board.draw_circle(p, TILE * 1.4, Color(0.8, 0.85, 1.0, 0.18))
			board.draw_circle(p, 9.0, PALE)
			board.draw_circle(p + Vector2(-3, -2), 2.0, DARK)
			board.draw_circle(p + Vector2(3, -2), 2.0, DARK)
		"chair":
			var at: Vector2 = p + Vector2(lerpf(-0.35, 0.35, smoothstep(0.1, 0.5, t)) * TILE, 0)
			board.draw_rect(Rect2(at - Vector2(7, 7), Vector2(14, 14)), WOOD)
		"hanging":
			var sway: Vector2 = Vector2(sin(t * TAU * 1.5) * 4.0, 0)
			board.draw_circle(p + sway, 10.0, DARK)
			board.draw_circle(p + sway, 4.0, PALE.darkened(0.5))
		"crawler":
			var head: Vector2 = p + to_player * lerpf(-0.3, 0.45, t) * TILE
			board.draw_line(head - to_player * 16.0, head, DARK, 9.0)
			board.draw_circle(head, 2.5, Color.RED)
		_:
			board.draw_circle(p, 10.0, DARK)
			board.draw_circle(p + to_player * 4.0, 2.0, Color.RED)


func _on_event_started(event: FootageEvent) -> void:
	Sfx.play(self, Sfx.tone(70.0, 1.2, FootageProse.pan(tape.walker, event.cell), 0.5), -2.0)
	Sfx.play(self, Sfx.sample("static"), -8.0)
