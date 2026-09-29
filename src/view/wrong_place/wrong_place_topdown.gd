extends TopdownView
## Wrong Place from above: the house under fog of war, each object a coloured
## glyph with a short tag once seen. A wrong colour shows in the glyph, a wrong
## state or label in the tag; flagged objects get a red ring.

const INK: Color = Color(0.92, 0.88, 0.78)
const FLAG_RED: Color = Color(0.95, 0.1, 0.1)
const DOOR: Color = Color(0.45, 0.28, 0.14)

var game: WrongPlace
var _centres: Dictionary = WrongPlaceHouse.room_centres()


func make_concept(seed_value: int) -> Concept:
	game = WrongPlace.new(seed_value)
	return game


func concept_id() -> String:
	return "wrong_place"


func extra_keys() -> Dictionary:
	return {KEY_E: &"flag", KEY_SPACE: &"flag", KEY_Q: &"look"}


func build_board() -> void:
	wall_color = Color(0.4, 0.3, 0.22)
	floor_color = Color(0.17, 0.13, 0.1)
	hud.push("Something in this house is wrong. Face it and press E. Q looks.")


func view_grid() -> CellGrid:
	return game.grid


func viewer() -> GridWalker:
	return game.walker


func on_acted(action: StringName) -> void:
	if action == &"flag" or action == &"look":
		return
	if not game.bumped:
		Sfx.play(self, Sfx.sample("footstep"), -8.0)


func draw_overlay() -> void:
	for room: String in _centres:
		var at: Vector2 = _centres[room]
		var c: Vector2i = Vector2i(roundi(at.x), roundi(at.y))
		if seen.has(c):
			_centered(center(c) + Vector2(0, TILE * 0.1), room, Color(0.6, 0.5, 0.4, 0.6), 9)
	_draw_door(game.back_door, "BACK DOOR")
	_draw_door(WrongPlaceHouse.start() + Vector2i(0, 1), "FRONT DOOR")
	for prop: Prop in game.props:
		if seen.has(prop.cell):
			_draw_prop(prop)
	draw_walker(game.walker, Color(0.95, 0.9, 0.65))


func _draw_door(c: Vector2i, text: String) -> void:
	var inside: Vector2i = c + (Vector2i(0, 1) if c.y == 0 else Vector2i(0, -1))
	if not seen.has(inside):
		return
	var edge: Vector2 = (center(c) + center(inside)) / 2.0
	board.draw_rect(Rect2(edge - Vector2(TILE * 0.45, 3), Vector2(TILE * 0.9, 6)), DOOR)
	var label_at: Vector2 = edge + (center(inside) - edge) * 0.5
	_centered(label_at, text, INK, 7)


func _draw_prop(prop: Prop) -> void:
	var lit: bool = is_visible_cell(prop.cell)
	var color: Color = WrongPlaceCatalog.color_of(prop)
	var lines: Array[String] = WrongPlaceCatalog.tag_lines(prop)
	## The glyph widens into a plate under a long tag, so the tag never
	## spills onto the floor in an ink chosen for the glyph.
	var width: float = TILE - 8.0
	for line: String in lines:
		width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 4.0)
	var size: Vector2 = Vector2(width, TILE - 8.0)
	var rect: Rect2 = Rect2(center(prop.cell) - size / 2.0, size)
	board.draw_rect(rect, color if lit else color.darkened(0.5))
	board.draw_rect(rect, Color(0, 0, 0, 0.8), false, 1.5)
	var pale: bool = color.get_luminance() > 0.45
	var ink: Color = (Color(0.05, 0.03, 0.02) if pale else INK).darkened(0.0 if lit else 0.4)
	var top: Vector2 = center(prop.cell) - Vector2(0, (lines.size() - 1) * 4.5)
	for i: int in lines.size():
		_centered(top + Vector2(0, i * 9.0), lines[i], ink, 7)
	if game.flagged.has(prop.id):
		var ring: float = maxf(TILE * 0.55, width / 2.0 + 4.0)
		board.draw_arc(center(prop.cell), ring, 0.0, TAU, 32, FLAG_RED, 2.5)
		board.draw_circle(center(prop.cell) + Vector2(TILE * 0.38, -TILE * 0.38), 4.0, FLAG_RED)


## Text centred on `at` (its baseline a little below), outlined so it reads
## over any glyph colour.
func _centered(at: Vector2, text: String, color: Color, size: int) -> void:
	var width: float = TILE * 3.0
	var pos: Vector2 = at + Vector2(-width / 2.0, size * 0.4)
	var dark: bool = color.get_luminance() < 0.3
	var outline: Color = Color(0.9, 0.85, 0.75, 0.5) if dark else Color(0, 0, 0, color.a)
	board.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, 2, outline)
	board.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)
