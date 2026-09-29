class_name WrongPlaceProps3D
extends RefCounted
## Low-poly furniture for Wrong Place's first-person view, built from Prop
## data. Each object is built in its own frame: origin at the cell's floor
## centre, the wall it stands against at local z = -1, the room at +z. Wall
## hangings live in WrongPlaceWall3D. Wrong states change geometry here.

const SKIN: Color = Color(0.86, 0.72, 0.6)
const DARK_WOOD: Color = Color(0.2, 0.12, 0.07)
const PALE: Color = Color(0.9, 0.88, 0.82)

var view: FpsView
var wall: WrongPlaceWall3D


func _init(on: FpsView) -> void:
	view = on
	wall = WrongPlaceWall3D.new(on)


## The object's root node, facing away from wall `dir` (a CellGrid.DIRS index).
func build(prop: Prop, dir: int) -> Node3D:
	var root: Node3D = Node3D.new()
	root.position = FpsView.to_world(prop.cell)
	var d: Vector2i = CellGrid.DIRS[dir]
	root.rotation.y = atan2(-float(d.x), -float(d.y))
	var keep: Node3D = view.target
	view.target = root
	var c: Color = WrongPlaceCatalog.color_of(prop)
	if not wall.build(prop, c):
		_furniture(prop, c)
	view.target = keep
	return root


## Parts that move together (a crib that rocks, a chair on the ceiling).
func group(at: Vector3) -> Node3D:
	var node: Node3D = Node3D.new()
	node.position = at
	view.target.add_child(node)
	view.target = node
	return node


func _furniture(prop: Prop, c: Color) -> void:
	var parent: Node3D = view.target
	match prop.kind:
		"plant":
			view.add_box(Vector3(0, 0.22, -0.6), Vector3(0.4, 0.44, 0.4), Color(0.55, 0.28, 0.16))
			view.add_box(Vector3(0, 0.8, -0.6), Vector3(0.7, 0.75, 0.7), c)
		"tv":
			_tv(prop, c)
		"bookshelf":
			_bookshelf(prop, c)
		"lamp":
			view.add_box(Vector3(0, 0.8, -0.7), Vector3(0.06, 1.6, 0.06), DARK_WOOD)
			view.add_box(Vector3(0, 1.65, -0.7), Vector3(0.5, 0.35, 0.5), c, 1.6)
			view.add_light(Vector3(0, 1.45, -0.3), c, 1.2, 5.0)
		"bed":
			view.add_box(Vector3(0, 0.2, -0.05), Vector3(1.4, 0.4, 1.85), DARK_WOOD)
			view.add_box(Vector3(0, 0.46, 0.0), Vector3(1.3, 0.14, 1.7), c)
			view.add_box(Vector3(0, 0.58, -0.68), Vector3(0.9, 0.12, 0.32), PALE)
			view.add_box(Vector3(0, 0.75, -0.95), Vector3(1.4, 1.0, 0.08), DARK_WOOD)
		"bathtub":
			view.add_box(Vector3(0, 0.3, -0.5), Vector3(1.6, 0.6, 0.9), PALE)
			view.add_box(Vector3(0, 0.61, -0.5), Vector3(1.4, 0.03, 0.7), c, 0.3)
		"crib":
			_crib(prop, c)
		"doll":
			_doll(prop, c)
		"fridge":
			_fridge(prop, c)
		"table":
			_table(prop, c)
		"chair":
			_chair(prop, c)
		_:
			view.add_box(Vector3(0, 0.5, -0.5), Vector3(0.8, 1.0, 0.8), c)
			view.add_label(_front(1.2, -0.05), WrongPlaceCatalog.tag(prop), PALE)
	view.target = parent


func _front(y: float, z: float) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(0, y, z))


func _tv(prop: Prop, c: Color) -> void:
	view.add_box(Vector3(0, 0.3, -0.6), Vector3(1.1, 0.6, 0.6), DARK_WOOD)
	view.add_box(Vector3(0, 0.88, -0.62), Vector3(0.85, 0.6, 0.5), c)
	var face: bool = prop.state == "face"
	var screen: Color = Color(0.85, 0.87, 0.9) if face else Color(0.04, 0.05, 0.05)
	view.add_box(Vector3(0, 0.88, -0.36), Vector3(0.7, 0.46, 0.02), screen, 1.5 if face else 0.0)
	if face:
		for i: int in 14:
			var p: Vector2 = Vector2(fposmod(i * 0.37, 0.6) - 0.3, fposmod(i * 0.23, 0.38) + 0.69)
			view.add_box(
				Vector3(p.x, p.y, -0.348), Vector3(0.05, 0.02, 0.01), Color(0.35, 0.35, 0.4)
			)
		for x: float in [-0.1, 0.1]:
			view.add_box(Vector3(x, 0.95, -0.345), Vector3(0.07, 0.05, 0.01), Color.BLACK)
		view.add_box(Vector3(0, 0.78, -0.345), Vector3(0.14, 0.08, 0.01), Color.BLACK)


func _bookshelf(prop: Prop, c: Color) -> void:
	view.add_box(Vector3(0, 1.0, -0.8), Vector3(1.3, 2.0, 0.4), c)
	var spines: Array[Color] = [Color(0.45, 0.1, 0.08), Color(0.12, 0.3, 0.2), Color(0.5, 0.4, 0.2)]
	for row: int in 3:
		var y: float = 0.4 + row * 0.55
		view.add_box(Vector3(0, y, -0.62), Vector3(1.1, 0.36, 0.06), spines[row])
	view.add_label(_front(1.25, -0.57), prop.label, PALE, 0.004)


func _crib(prop: Prop, c: Color) -> void:
	var body: Node3D = group(Vector3(0, 0, -0.45))
	if prop.state == "rocking":
		body.rotation.z = 0.25
		body.set_meta("rock", true)
	view.add_box(Vector3(0, 0.1, 0), Vector3(1.3, 0.08, 0.5), DARK_WOOD)
	view.add_box(Vector3(0, 0.45, 0), Vector3(1.1, 0.1, 0.6), c)
	for z: float in [-0.28, 0.28]:
		view.add_box(Vector3(0, 0.9, z), Vector3(1.1, 0.05, 0.04), c)
		for i: int in 6:
			view.add_box(Vector3(-0.5 + i * 0.2, 0.68, z), Vector3(0.04, 0.45, 0.03), c)


func _doll(prop: Prop, c: Color) -> void:
	var body: Node3D = group(Vector3(0, 0, -0.6))
	if prop.state == "facing_wall":
		body.rotation.y = PI
		body.position.z = -0.8
	view.add_box(Vector3(0, 0.2, 0), Vector3(0.3, 0.4, 0.22), c)
	view.add_box(Vector3(0, 0.52, 0), Vector3(0.24, 0.24, 0.22), Color(0.95, 0.9, 0.86))
	view.add_box(Vector3(0, 0.57, -0.08), Vector3(0.28, 0.24, 0.1), Color(0.3, 0.18, 0.08))
	for x: float in [-0.055, 0.055]:
		view.add_box(Vector3(x, 0.54, 0.115), Vector3(0.05, 0.05, 0.01), Color(0.1, 0.2, 0.5), 1.0)


func _fridge(prop: Prop, c: Color) -> void:
	view.add_box(Vector3(0, 0.95, -0.62), Vector3(0.85, 1.9, 0.7), c)
	if prop.state != "open":
		view.add_box(Vector3(0, 0.95, -0.25), Vector3(0.85, 1.88, 0.05), c.lightened(0.1))
		view.add_box(Vector3(0.33, 1.1, -0.21), Vector3(0.04, 0.4, 0.04), Color(0.5, 0.5, 0.5))
		return
	view.add_box(Vector3(0, 0.95, -0.27), Vector3(0.75, 1.75, 0.02), Color(1.0, 0.95, 0.75), 1.5)
	view.add_box(Vector3(0.45, 0.95, 0.12), Vector3(0.05, 1.88, 0.8), c.lightened(0.1))
	var blood: Color = WrongPlaceCatalog.COLORS["darkred"]
	view.add_box(Vector3(0, 0.01, 0.2), Vector3(0.7, 0.02, 0.6), blood)
	view.add_box(Vector3(0, 0.45, -0.26), Vector3(0.6, 0.3, 0.01), blood.lightened(0.2))


func _table(prop: Prop, c: Color) -> void:
	view.add_box(Vector3(0, 0.75, -0.4), Vector3(1.5, 0.07, 0.95), c)
	for x: float in [-0.65, 0.65]:
		for z: float in [-0.8, 0.0]:
			view.add_box(Vector3(x, 0.37, z), Vector3(0.07, 0.74, 0.07), c)
	for x: float in [-0.45, 0.0, 0.45]:
		view.add_box(Vector3(x, 0.8, -0.35), Vector3(0.26, 0.02, 0.26), PALE)
	if prop.state == "knife":
		view.add_box(Vector3(0, 0.98, -0.3), Vector3(0.04, 0.42, 0.12), Color(0.8, 0.82, 0.85), 0.6)
		view.add_box(Vector3(0, 1.26, -0.3), Vector3(0.06, 0.16, 0.06), Color.BLACK)


func _chair(prop: Prop, c: Color) -> void:
	var body: Node3D = group(Vector3(0, 0, -0.45))
	if prop.state == "ceiling":
		body.position.y = PsxKit.WALL_HEIGHT
		body.rotation.z = PI
	view.add_box(Vector3(0, 0.45, 0), Vector3(0.5, 0.05, 0.5), c)
	view.add_box(Vector3(0, 0.78, -0.23), Vector3(0.5, 0.6, 0.05), c)
	for x: float in [-0.22, 0.22]:
		for z: float in [-0.22, 0.22]:
			view.add_box(Vector3(x, 0.22, z), Vector3(0.05, 0.45, 0.05), c)
