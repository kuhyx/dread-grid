extends FpsView
## Wrong Place, first person: a dim, warm family house in low-poly 3D. Every
## object is built from its Prop row (WrongPlaceProps3D), so wrong states
## show as geometry; flagged objects get a small red marker above them.

const HALF_CELL: float = FpsView.CELL / 2.0
const WALLPAPER: Color = Color(0.55, 0.44, 0.34)
const FLOORBOARDS: Color = Color(0.3, 0.2, 0.12)
const LAMPLIGHT: Color = Color(1.0, 0.72, 0.45)
const DOOR: Color = Color(0.32, 0.2, 0.11)
## One ceiling light per room: GL Compatibility lights an object with at most
## 8 lights and the house is one merged mesh, so 6 rooms + the standing lamp +
## the flashlight is the whole budget; warm ambient does the rest.
const LIGHTS: Dictionary = {
	Vector2i(3, 2): 9.0,
	Vector2i(10, 2): 9.0,
	Vector2i(16, 2): 9.0,
	Vector2i(9, 7): 15.0,
	Vector2i(4, 10): 9.0,
	Vector2i(15, 10): 9.0,
}

var game: WrongPlace
var _props_root: Node3D = Node3D.new()
var _roots: Dictionary = {}
var _marked: Dictionary = {}
var _rocking: Array[Node3D] = []
var _time: float = 0.0
var _last_found: int = 0
var _last_false: int = 0


func make_concept(seed_value: int) -> Concept:
	game = WrongPlace.new(seed_value)
	return game


func concept_id() -> String:
	return "wrong_place"


func extra_keys() -> Dictionary:
	return {KEY_E: &"flag", KEY_SPACE: &"flag", KEY_Q: &"look"}


func build_world() -> void:
	environment.fog_density = 0.06
	environment.fog_light_color = Color(0.05, 0.035, 0.02)
	environment.ambient_light_color = Color(0.3, 0.22, 0.15)
	build_grid(game.grid, WALLPAPER, FLOORBOARDS)
	for c: Vector2i in LIGHTS:
		var reach: float = LIGHTS[c]
		add_light(to_world(c, 2.3), LAMPLIGHT, 1.3, reach)
		add_box(to_world(c, 2.57), Vector3(0.4, 0.05, 0.4), LAMPLIGHT, 2.0)
	_build_doors()
	world.add_child(_props_root)
	var builder: WrongPlaceProps3D = WrongPlaceProps3D.new(self)
	target = _props_root
	for prop: Prop in game.props:
		var root: Node3D = builder.build(prop, WrongPlaceHouse.wall_dir(game.grid, prop.cell))
		_props_root.add_child(root)
		_roots[prop.id] = root
		_rocking.append_array(_find_rocking(root))
	target = world
	place_camera(game.walker.cell, game.walker.facing, true)
	hud.push("Something in this house is wrong. Face it and press E. Q looks.")


func _build_doors() -> void:
	var front: Vector3 = to_world(WrongPlaceHouse.start(), 1.0) + Vector3(0, 0, HALF_CELL - 0.03)
	add_box(front, Vector3(1.1, 2.0, 0.05), DOOR)
	var back: Vector3 = to_world(game.back_door, 1.0) + Vector3(0, 0, HALF_CELL - 0.03)
	add_box(back, Vector3(1.1, 2.0, 0.05), DOOR)
	add_box(back + Vector3(0, 0.45, 0.04), Vector3(0.5, 0.4, 0.02), Color(0.4, 0.5, 0.7), 1.2)


func _find_rocking(root: Node3D) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for child: Node in root.get_children():
		var node: Node3D = child as Node3D
		if node != null and node.has_meta("rock"):
			out.append(node)
	return out


func refresh() -> void:
	super.refresh()
	_time += get_process_delta_time()
	for node: Node3D in _rocking:
		node.rotation.z = sin(_time * 2.2) * 0.3
	for id: String in game.flagged:
		if not _marked.has(id):
			_marked[id] = true
			var root: Node3D = _roots[id]
			var marker: MeshInstance3D = box_node(
				Vector3(0, 2.3, -0.2), Vector3(0.1, 0.1, 0.1), Color(0.9, 0.05, 0.05), 3.0
			)
			root.add_child(marker)


func on_acted(action: StringName) -> void:
	place_camera(game.walker.cell, game.walker.facing)
	if action == &"flag":
		if game.found > _last_found:
			Sfx.play(self, Sfx.sample("heartbeat"), -4.0)
		elif game.false_flags > _last_false:
			Sfx.play(self, Sfx.sample("thud"), -8.0)
		_last_found = game.found
		_last_false = game.false_flags
	elif action != &"look" and not game.bumped:
		Sfx.play(self, Sfx.sample("footstep"), -6.0)
