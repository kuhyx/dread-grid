extends TextView
## Wrong Place as prose: a walk through the house. Entering a room lists what
## is in it and where; every step says what is ahead. The wrongness is in the
## sentences - learn how a normal house reads.

var game: WrongPlace
var _room: String = ""


func make_concept(seed_value: int) -> Concept:
	game = WrongPlace.new(seed_value)
	return game


func concept_id() -> String:
	return "wrong_place"


func words() -> Dictionary:
	return {
		"forward": &"forward",
		"f": &"forward",
		"back": &"back",
		"left": &"turn_left",
		"right": &"turn_right",
		"around": &"turn_back",
		"north": &"north",
		"n": &"north",
		"east": &"east",
		"e": &"east",
		"south": &"south",
		"s": &"south",
		"west": &"west",
		"w": &"west",
		"flag": &"flag",
		"x": &"flag",
		"look": &"look",
		"l": &"look",
	}


func intro() -> void:
	write("[b]WRONG PLACE[/b]")
	write("You let yourself into the family house by the front door. It is very quiet.")
	write("Eight things in this house are wrong. Face one and type 'flag'.")
	write("Find %d and the back door, in the kitchen, will let you out." % WrongPlace.TO_OPEN)
	write("Walk with forward / back / left / right, or north / east / south / west.")
	_enter_room()


func on_acted(action: StringName) -> void:
	if action == &"flag" or action == &"look" or game.status != Concept.Status.PLAYING:
		return
	if game.bumped:
		write("You cannot go that way.")
		return
	Sfx.play(self, Sfx.sample("footstep"), -8.0)
	var room: String = game.room()
	if room != _room and room != "doorway":
		_enter_room()
	else:
		write("You face %s. %s" % [_facing(), game.look_text()])


func _facing() -> String:
	return GridWalker.DIR_NAMES[game.walker.facing]


func _enter_room() -> void:
	_room = game.room()
	write("\n[color=#c96]The %s.[/color] You face %s." % [_room, _facing()])
	var here: Array[String] = []
	for prop: Prop in game.props:
		if WrongPlaceHouse.room_at(prop.cell) == _room:
			here.append(
				"%s [color=#888](%s)[/color]" % [WrongPlaceCatalog.describe(prop), _where(prop)]
			)
	if here.is_empty():
		write("Nothing here but faded wallpaper.")
	for line: String in here:
		write("  " + line)
	write("Ahead: " + game.look_text())


## Where `prop` is from you, in compass steps ("2 north, 1 east").
func _where(prop: Prop) -> String:
	var d: Vector2i = prop.cell - game.walker.cell
	var parts: Array[String] = []
	if d.y != 0:
		parts.append("%d %s" % [absi(d.y), "north" if d.y < 0 else "south"])
	if d.x != 0:
		parts.append("%d %s" % [absi(d.x), "west" if d.x < 0 else "east"])
	return ", ".join(PackedStringArray(parts))
