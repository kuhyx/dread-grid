class_name WrongPlace
extends Concept
## Wrong Place: walk through a family home and flag what is wrong in it. Eight
## of its objects are wrong each seed; flag six and the back door opens. There
## is no way to lose - time taken and false flags are the score.

const WRONG_COUNT: int = 8
const TO_OPEN: int = 6
const COMPASS: Array[StringName] = [&"north", &"east", &"south", &"west"]

var grid: CellGrid = WrongPlaceHouse.grid()
var walker: GridWalker = GridWalker.new(grid, WrongPlaceHouse.start(), 0)
var back_door: Vector2i = WrongPlaceHouse.back_door()
var props: Array[Prop] = WrongPlaceHouse.props()
## Object cell -> Prop; objects are furniture, you cannot walk through them.
var solid: Dictionary = {}
## Prop id -> the VARIANTS index that made it wrong.
var wrong: Dictionary = {}
var flagged: Dictionary = {}
var found: int = 0
var false_flags: int = 0
## True when the last move was refused (wall, furniture or the locked door).
var bumped: bool = false


func _init(seed_value: int) -> void:
	super(seed_value)
	for prop: Prop in props:
		solid[prop.cell] = prop
	_pick_wrong()


func is_wrong(prop: Prop) -> bool:
	return wrong.has(prop.id)


func door_open() -> bool:
	return found >= TO_OPEN


func can_enter(c: Vector2i) -> bool:
	return grid.is_open(c) and not solid.has(c) and (c != back_door or door_open())


## The object in the cell you face, else the one you stand on, else null.
func facing_prop() -> Prop:
	var hit: Prop = solid.get(walker.ahead(), null)
	if hit == null:
		hit = solid.get(walker.cell, null)
	return hit


## Free cells next to `prop` from which it can be faced and flagged.
func stand_cells(prop: Prop) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d: Vector2i in CellGrid.DIRS:
		if can_enter(prop.cell + d) and prop.cell + d != back_door:
			out.append(prop.cell + d)
	return out


func room() -> String:
	return WrongPlaceHouse.room_at(walker.cell)


## What is straight ahead, in a sentence.
func look_text() -> String:
	var prop: Prop = facing_prop()
	var ahead: Vector2i = walker.ahead()
	var text: String = "The %s goes on ahead." % WrongPlaceHouse.room_at(ahead)
	if prop != null:
		text = WrongPlaceCatalog.describe(prop)
		if flagged.has(prop.id):
			text += " You have marked it."
	elif ahead == back_door:
		text = "The back door. Night air seeps under it."
	elif not grid.is_open(ahead):
		text = "A wall, papered in faded roses."
	elif WrongPlaceHouse.room_at(ahead) == "doorway":
		text = "A doorway into the %s." % WrongPlaceHouse.room_at(ahead + walker.forward_vector())
	return text


func actions() -> Array[StringName]:
	var out: Array[StringName] = [
		&"forward", &"back", &"turn_left", &"turn_right", &"turn_back", &"flag", &"look"
	]
	out.append_array(COMPASS)
	return out


func hud_line() -> String:
	var secs: int = int(elapsed)
	return (
		"Found %d of %d (door opens at %d)   false flags %d   %d:%02d   E flag, Q look"
		% [found, WRONG_COUNT, TO_OPEN, false_flags, floori(elapsed / 60.0), secs % 60]
	)


func bot_action() -> StringName:
	return WrongPlaceBot.next_action(self)


func _on_perform(action: StringName) -> bool:
	bumped = false
	match action:
		&"forward":
			_move(walker.facing)
		&"back":
			_move((walker.facing + 2) % 4)
		&"turn_left", &"turn_right":
			walker.turn(action == &"turn_right")
		&"turn_back":
			walker.turn(true)
			walker.turn(true)
		&"north", &"east", &"south", &"west":
			walker.facing = COMPASS.find(action)
			_move(walker.facing)
		&"flag":
			_flag()
		&"look":
			_say(look_text())
		_:
			return false
	return true


func _move(dir: int) -> void:
	var target: Vector2i = walker.cell + CellGrid.DIRS[dir]
	if can_enter(target):
		walker.cell = target
		if target == back_door:
			_say("The back door swings open onto cold night air. You are out.")
			_finish(true)
		return
	bumped = true
	if target == back_door:
		_say("The door will not open. Something is still wrong here.")


func _flag() -> void:
	var prop: Prop = facing_prop()
	if prop == null:
		_say("There is nothing there to flag.")
	elif flagged.has(prop.id):
		_say("You already marked the %s." % prop.kind)
	elif is_wrong(prop):
		flagged[prop.id] = true
		found += 1
		var index: int = wrong[prop.id]
		_say("%s  (%d/%d)" % [WrongPlaceCatalog.confirmation(index), found, TO_OPEN])
		if found == TO_OPEN:
			_say("Far at the back of the house, a lock clicks open.")
	else:
		flagged[prop.id] = true
		false_flags += 1
		_say("Nothing is wrong with it. ...or is there?")


## Eight distinct objects, one variant each, in a seeded order (Array.shuffle
## would use the global RNG and break seed reproducibility).
func _pick_wrong() -> void:
	var order: Array[int] = []
	for i: int in WrongPlaceCatalog.VARIANTS.size():
		order.append(i)
	for i: int in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: int = order[i]
		order[i] = order[j]
		order[j] = swap
	for index: int in order:
		var target: String = WrongPlaceCatalog.target_of(index)
		if wrong.size() < WRONG_COUNT and not wrong.has(target):
			wrong[target] = index
			WrongPlaceCatalog.apply(props, index)
