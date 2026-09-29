extends TopdownView
## Anomaly Loop from above: the corridor as a strip, props drawn as glyphs on
## the walls, only the cells near you lit.

var loop: AnomalyLoop


func make_concept(seed_value: int) -> Concept:
	loop = AnomalyLoop.new(seed_value)
	return loop


func concept_id() -> String:
	return "anomaly"


func build_board() -> void:
	wall_color = Color(0.45, 0.43, 0.38)
	floor_color = Color(0.22, 0.21, 0.19)
	hud.push("Walk on if all is normal. Turn back (S) if anything is wrong.")


func view_grid() -> CellGrid:
	return loop.grid


func viewer() -> GridWalker:
	return loop.walker


func on_acted(_action: StringName) -> void:
	Sfx.play(self, Sfx.sample("footstep"), -8.0)
	if loop.walker.cell == AnomalyLoop.START and loop.walker.facing == 1:
		seen.clear()


func draw_overlay() -> void:
	for prop: Prop in loop.props:
		var c: Vector2i = _cell_of(prop)
		if is_visible_cell(c):
			_draw_prop(prop, c)
	draw_walker(loop.walker, Color(0.9, 0.85, 0.6))


func _cell_of(prop: Prop) -> Vector2i:
	if prop.kind == "sign":
		return Vector2i(AnomalyCatalog.LENGTH - 1, 1)
	return Vector2i(prop.cell.x, 1 + prop.side)


func _draw_prop(prop: Prop, c: Vector2i) -> void:
	var color: Color = AnomalyCatalog.color_of(prop)
	var p: Vector2 = center(c)
	match prop.kind:
		"light":
			var lit: bool = prop.state == "on"
			board.draw_circle(p, TILE * (0.9 if lit else 0.2), Color(color, 0.12 if lit else 0.5))
			board.draw_circle(p, 4.0, color if lit else Color(0.1, 0.1, 0.1))
		"door":
			var r: Rect2 = cell_rect(c, 3.0)
			board.draw_rect(r, Color.BLACK if prop.state == "open" else color)
		"figure":
			board.draw_circle(p, 10.0, Color(0.02, 0.02, 0.02))
			board.draw_circle(p + Vector2(0, 3), 2.0, Color.RED)
		"stain":
			board.draw_circle(p, 11.0, color)
		"extinguisher", "bench":
			board.draw_rect(cell_rect(c, 9.0), color)
		_:
			board.draw_rect(cell_rect(c, 4.0), color)
	if prop.label != "":
		draw_text_at(c + Vector2i(0, 1 if prop.side < 0 else -1), prop.label, color, 11)
