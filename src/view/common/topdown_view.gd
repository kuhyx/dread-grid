class_name TopdownView
extends GameView
## Top-down view over the shared grid: fog of war (a sight radius with line of
## sight, remembered cells drawn dim) and a camera that follows the player.
## Subclasses draw their own entities in draw_overlay().

const TILE: float = 32.0
const SIGHT: int = 4

var board: Node2D = Node2D.new()
var cam: Camera2D = Camera2D.new()
var font: Font = ThemeDB.fallback_font
var seen: Dictionary = {}
var visible_now: Dictionary = {}
var wall_color: Color = Color(0.22, 0.2, 0.2)
var floor_color: Color = Color(0.1, 0.09, 0.09)


func build() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	add_child(board)
	Wire.link(board.draw, _on_draw)
	cam.zoom = Vector2(2.5, 2.5)
	board.add_child(cam)
	hud = Hud.new()
	add_child(hud)
	build_board()
	Sfx.play(self, Sfx.music(concept_id()), -14.0)


## Subclass hooks --------------------------------------------------------------


func build_board() -> void:
	pass


func concept_id() -> String:
	return ""


## The grid and the viewer; null grid means the subclass draws everything.
func view_grid() -> CellGrid:
	return null


func viewer() -> GridWalker:
	return null


func draw_overlay() -> void:
	pass


## Plumbing ---------------------------------------------------------------------


func refresh() -> void:
	super.refresh()
	var walker: GridWalker = viewer()
	if walker != null:
		_update_sight(walker)
		cam.position = cam.position.lerp(center(walker.cell), 0.25)
	board.queue_redraw()


func center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * TILE


func cell_rect(c: Vector2i, inset: float = 0.0) -> Rect2:
	return Rect2(
		Vector2(c) * TILE + Vector2(inset, inset), Vector2(TILE, TILE) - Vector2(inset, inset) * 2.0
	)


func is_visible_cell(c: Vector2i) -> bool:
	return visible_now.has(c)


func draw_walker(walker: GridWalker, color: Color) -> void:
	var p: Vector2 = center(walker.cell)
	var f: Vector2 = Vector2(walker.forward_vector())
	var side: Vector2 = Vector2(-f.y, f.x)
	var tip: PackedVector2Array = [p + f * 12.0, p - f * 9.0 + side * 9.0, p - f * 9.0 - side * 9.0]
	board.draw_colored_polygon(tip, color)


func draw_text_at(c: Vector2i, text: String, color: Color, size: int = 12) -> void:
	board.draw_string(
		font,
		Vector2(c) * TILE + Vector2(2, TILE * 0.6),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		TILE * 3.0,
		size,
		color
	)


func _update_sight(walker: GridWalker) -> void:
	visible_now.clear()
	var grid: CellGrid = view_grid()
	if grid == null:
		return
	for dy: int in range(-SIGHT, SIGHT + 1):
		for dx: int in range(-SIGHT, SIGHT + 1):
			var c: Vector2i = walker.cell + Vector2i(dx, dy)
			if Vector2(dx, dy).length() <= SIGHT + 0.5 and grid.in_bounds(c):
				if (
					grid.line_of_sight(walker.cell, c)
					or not grid.is_open(c) and _near_open(grid, walker.cell, c)
				):
					visible_now[c] = true
					seen[c] = true


func _near_open(grid: CellGrid, from: Vector2i, wall: Vector2i) -> bool:
	for n: Vector2i in grid.open_neighbors(wall):
		if grid.line_of_sight(from, n):
			return true
	return false


func _on_draw() -> void:
	var grid: CellGrid = view_grid()
	if grid != null:
		for c: Vector2i in seen:
			var base: Color = floor_color if grid.is_open(c) else wall_color
			board.draw_rect(cell_rect(c), base if visible_now.has(c) else base.darkened(0.6))
	draw_overlay()
