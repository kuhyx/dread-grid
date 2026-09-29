extends FpsView
## Stalker, first person: a dark industrial maze, glowing keys, grey lockers,
## a red-lit exit door and the thing itself, eased from cell to cell. Its
## footfalls thud louder as it nears; inside a locker the view is a slit.

const WALL: Color = Color(0.5, 0.48, 0.42)
const FLOOR: Color = Color(0.27, 0.26, 0.24)
const KEY_GOLD: Color = Color(0.95, 0.8, 0.2)
const LOCKER_GREY: Color = Color(0.42, 0.44, 0.47)
const EXIT_RED: Color = Color(0.75, 0.08, 0.06)
const FOLLOW: float = 8.0
const SLIT: float = 0.08
## The PSX grime hashes floor(world position * 5); walls and floors of a
## 2 m grid sit exactly on those boundaries and shimmer into stripes. A 1 cm
## nudge of the whole level keeps every surface inside one grime block.
const GRIME_OFFSET: Vector3 = Vector3(0.01, 0.01, 0.01)

var game: StalkerGame
var _figure: Node3D
var _keys: Dictionary = {}
var _slit: CanvasLayer = CanvasLayer.new()
var _heard_steps: int = 0


func make_concept(seed_value: int) -> Concept:
	game = StalkerGame.new(seed_value)
	return game


func concept_id() -> String:
	return "stalker"


func extra_keys() -> Dictionary:
	return {KEY_E: &"hide", KEY_Q: &"listen", KEY_SPACE: &"wait"}


func build_world() -> void:
	environment.fog_density = 0.09
	environment.ambient_light_color = Color(0.17, 0.16, 0.17)
	var level_root: Node3D = Node3D.new()
	level_root.position = GRIME_OFFSET
	world.add_child(level_root)
	target = level_root
	build_grid(game.grid, WALL, FLOOR)
	for key: Vector2i in game.level.keys:
		var node: MeshInstance3D = box_node(
			to_world(key, 0.6), Vector3(0.3, 0.12, 0.12), KEY_GOLD, 3.0
		)
		target.add_child(node)
		_keys[key] = node
		add_light(to_world(key, 0.9), KEY_GOLD, 0.6, 3.0)
	for locker: Vector2i in game.level.lockers:
		_add_locker(locker)
	_add_exit()
	_figure = kit.figure(to_world(game.hunter.cell), _yaw_of(game.hunter.facing))
	target.add_child(_figure)
	_build_slit()
	place_camera(game.walker.cell, game.walker.facing, true)
	hud.push("Three keys, then the red door. E hides in a locker, Q listens.")


func refresh() -> void:
	super.refresh()
	for key: Vector2i in _keys:
		var node: MeshInstance3D = _keys[key]
		node.visible = game.keys_left.has(key)
	_slit.visible = game.hidden
	camera.fov = 50.0 if game.hidden else 70.0
	flashlight.visible = not game.hidden
	if game.hunter.steps != _heard_steps:
		_heard_steps = game.hunter.steps
		StalkerAudio.thud(self, game)


func on_acted(action: StringName) -> void:
	place_camera(game.walker.cell, game.walker.facing)
	if action == &"listen":
		StalkerAudio.beep(self, game)
	elif action in [&"forward", &"back", &"go_north", &"go_east", &"go_south", &"go_west"]:
		Sfx.play(self, Sfx.sample("footstep"), -8.0)


func _process(delta: float) -> void:
	if _figure != null:
		var t: float = minf(1.0, FOLLOW * delta)
		_figure.position = _figure.position.lerp(to_world(game.hunter.cell), t)
		_figure.rotation.y = lerp_angle(_figure.rotation.y, _yaw_of(game.hunter.facing), t)
		for key: Vector2i in _keys:
			var node: MeshInstance3D = _keys[key]
			node.rotate_y(delta * 2.0)
	super(delta)


## Yaw that turns a figure (eyes on +Z) to face grid direction `facing`.
static func _yaw_of(facing: int) -> float:
	var d: Vector2i = CellGrid.DIRS[facing]
	return atan2(float(d.x), float(d.y))


## The first walled side of `c` (lockers and the door stand against it).
func _wall_side(c: Vector2i) -> Vector2i:
	for d: Vector2i in CellGrid.DIRS:
		if not game.grid.is_open(c + d):
			return d
	return CellGrid.DIRS[0]


## A position against the wall `side` of cell `c`, `inset` from it.
func _against(c: Vector2i, side: Vector2i, inset: float, y: float) -> Vector3:
	return to_world(c, y) + Vector3(side.x, 0, side.y) * (CELL / 2.0 - inset)


func _add_locker(c: Vector2i) -> void:
	var side: Vector2i = _wall_side(c)
	var size: Vector3 = Vector3(0.5, 2.0, 0.9) if side.x != 0 else Vector3(0.9, 2.0, 0.5)
	add_box(_against(c, side, 0.27, 1.0), size, LOCKER_GREY)
	var vent: Vector3 = Vector3(0.02, 0.05, 0.6) if side.x != 0 else Vector3(0.6, 0.05, 0.02)
	for y: float in [1.55, 1.65, 1.75]:
		add_box(_against(c, side, 0.53, y), vent, Color(0.05, 0.05, 0.05))


func _add_exit() -> void:
	var c: Vector2i = game.level.exit_cell
	var side: Vector2i = _wall_side(c)
	var size: Vector3 = Vector3(0.06, 2.1, 1.1) if side.x != 0 else Vector3(1.1, 2.1, 0.06)
	add_box(_against(c, side, 0.04, 1.05), size, EXIT_RED, 0.6)
	add_light(to_world(c, 2.2), Color(1.0, 0.15, 0.1), 1.6, 5.0)
	var face: Basis = Basis(Vector3.UP, atan2(float(-side.x), float(-side.y)))
	add_label(Transform3D(face, _against(c, side, 0.1, 2.35)), "EXIT", Color(1.0, 0.3, 0.25), 0.006)


## Two black bars that leave a thin slit: the view through locker vents.
func _build_slit() -> void:
	_slit.layer = 5
	_slit.visible = false
	add_child(_slit)
	for top: bool in [true, false]:
		var bar: ColorRect = ColorRect.new()
		bar.color = Color(0.0, 0.0, 0.0, 0.97)
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 0.5 + SLIT
		bar.anchor_bottom = 0.5 - SLIT if top else 1.0
		_slit.add_child(bar)
