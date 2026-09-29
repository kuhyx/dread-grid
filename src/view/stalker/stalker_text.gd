extends TextView
## Stalker as commands and sound. Every command is about a third of a
## second, so a running stalker closes about one cell per command. You hear
## its footfalls thud louder as it nears; `listen` names where it is and
## beeps from its side.

const LOOK_RANGE: float = 4.0

var game: StalkerGame
var _heard_steps: int = 0


func make_concept(seed_value: int) -> Concept:
	game = StalkerGame.new(seed_value)
	return game


func concept_id() -> String:
	return "stalker"


func tick_seconds() -> float:
	return 0.33


func words() -> Dictionary:
	return {
		"forward": &"forward",
		"f": &"forward",
		"w": &"forward",
		"back": &"back",
		"b": &"back",
		"s": &"back",
		"left": &"turn_left",
		"l": &"turn_left",
		"a": &"turn_left",
		"right": &"turn_right",
		"r": &"turn_right",
		"d": &"turn_right",
		"north": &"go_north",
		"east": &"go_east",
		"south": &"go_south",
		"west": &"go_west",
		"hide": &"hide",
		"h": &"hide",
		"listen": &"listen",
		"q": &"listen",
		"wait": &"wait",
		"z": &"wait",
		"look": &"look",
	}


func intro() -> void:
	write("[b]STALKER[/b]")
	write("A maze of cold corridors. Three keys, then the red door. Something walks here too.")
	write("It sees six paces down a straight line and hears you walk within three.")
	write("'hide' in a locker, 'listen' for it, north/east/south/west to walk that way.")
	_describe()


func on_acted(action: StringName) -> void:
	if game.hunter.steps != _heard_steps:
		_heard_steps = game.hunter.steps
		StalkerAudio.thud(self, game)
	if game.status != Concept.Status.PLAYING:
		return
	match action:
		&"listen":
			StalkerAudio.beep(self, game)
		&"hide", &"wait":
			_presence()
		_:
			_describe()


func _describe() -> void:
	var cell: Vector2i = game.walker.cell
	var lines: Array[String] = []
	if game.hidden:
		lines.append("You are inside the locker, peering through the vents.")
	else:
		lines.append("You face %s." % GridWalker.DIR_NAMES[game.walker.facing])
		lines.append(StalkerSense.passages(game.grid, cell))
	if game.on_locker() and not game.hidden:
		lines.append("A dented locker stands here.")
	for key: Vector2i in game.keys_left:
		if _in_view(key):
			lines.append("Something glints to the %s." % StalkerSense.compass(key - cell))
	var exit_cell: Vector2i = game.level.exit_cell
	if exit_cell != cell and _in_view(exit_cell):
		var where: String = StalkerSense.compass(exit_cell - cell)
		lines.append("A red light burns to the %s: the exit door." % where)
	write(" ".join(PackedStringArray(lines)))
	_presence()


func _presence() -> void:
	var line: String = StalkerSense.presence(game)
	if line != "":
		write("[color=#b33]%s[/color]" % line)


func _in_view(c: Vector2i) -> bool:
	var cell: Vector2i = game.walker.cell
	return Vector2(c - cell).length() <= LOOK_RANGE and game.grid.line_of_sight(cell, c)
