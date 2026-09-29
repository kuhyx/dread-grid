class_name Launcher
extends Control
## The 5 x 3 menu. Each row is a concept, each column a perspective.

signal chosen(game: String)


func _ready() -> void:
	# The parent is a plain Node, so anchors have nothing to fill: paint the
	# clear colour instead of a full-rect background.
	RenderingServer.set_default_clear_color(Color(0.05, 0.04, 0.05))
	var box: VBoxContainer = VBoxContainer.new()
	box.position = Vector2(120, 60)
	box.add_theme_constant_override("separation", 18)
	add_child(box)
	var title: Label = Label.new()
	title.text = "DREAD GRID\nfive fears, three ways to see them"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.75, 0.1, 0.1))
	box.add_child(title)
	box.add_child(_grid())
	var hint: Label = Label.new()
	hint.text = "WASD / arrows move and turn.  Each game shows its own keys.  Esc: back."
	box.add_child(hint)


func _grid() -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = Registry.PERSPECTIVES.size() + 1
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	var first: Button = null
	for concept: String in Registry.CONCEPTS:
		var name_label: Label = Label.new()
		name_label.text = Registry.CONCEPT_TITLES[concept]
		name_label.custom_minimum_size = Vector2(240, 0)
		name_label.add_theme_font_size_override("font_size", 24)
		grid.add_child(name_label)
		for perspective: String in Registry.PERSPECTIVES:
			var game: String = "%s/%s" % [concept, perspective]
			var button: Button = Button.new()
			button.text = Registry.PERSPECTIVE_TITLES[perspective]
			button.custom_minimum_size = Vector2(200, 48)
			Wire.link(button.pressed, chosen.emit.bind(game))
			grid.add_child(button)
			if first == null:
				first = button
	first.call_deferred("grab_focus")
	return grid
