class_name WrongPlaceWall3D
extends RefCounted
## Wall hangings for Wrong Place's first-person view (photo, clock, window,
## portrait, painting, mirror), in the same object frame as WrongPlaceProps3D:
## the wall is the plane z = -1, the room is +z.

const FACE_Z: float = -0.95
const INK: Color = Color(0.08, 0.06, 0.05)
const CREAM: Color = Color(0.9, 0.86, 0.74)

var view: FpsView


func _init(on: FpsView) -> void:
	view = on


## Build `prop` if it hangs on a wall; false leaves it to the furniture builder.
func build(prop: Prop, c: Color) -> bool:
	match prop.kind:
		"photo":
			_photo(prop, c)
		"clock":
			view.add_box(Vector3(0, 1.9, -0.98), Vector3(0.55, 0.55, 0.04), c)
			view.add_label(_at(1.9, FACE_Z + 0.02), prop.label, INK, 0.005)
		"window":
			_window(prop, c)
		"portrait":
			_portrait(prop, c)
		"painting":
			_painting(prop, c)
		"mirror":
			_mirror(prop, c)
		_:
			return false
	return true


func _at(y: float, z: float, x: float = 0.0) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(x, y, z))


## One small figure per name in the caption: an extra name is an extra person.
func _photo(prop: Prop, c: Color) -> void:
	view.add_box(Vector3(0, 1.5, -0.98), Vector3(1.0, 0.65, 0.04), c)
	view.add_box(Vector3(0, 1.5, -0.955), Vector3(0.88, 0.53, 0.01), Color(0.55, 0.62, 0.55))
	var names: PackedStringArray = prop.label.split(" ", false)
	for i: int in names.size():
		var x: float = (i - (names.size() - 1) / 2.0) * 0.2
		var odd: bool = i >= 3
		var head: Color = Color(0.95, 0.95, 0.95) if odd else Color(0.86, 0.72, 0.6)
		view.add_box(Vector3(x, 1.6, -0.945), Vector3(0.1, 0.12, 0.01), head, 1.0 if odd else 0.0)
		view.add_box(Vector3(x, 1.43, -0.945), Vector3(0.14, 0.18, 0.01), INK)
	view.add_label(_at(1.08, FACE_Z), prop.label, CREAM, 0.003)


func _window(prop: Prop, c: Color) -> void:
	view.add_box(Vector3(0, 1.45, -0.99), Vector3(1.3, 1.1, 0.04), CREAM)
	view.add_box(Vector3(0, 1.45, -0.96), Vector3(1.1, 0.9, 0.02), c, 0.4)
	view.add_box(Vector3(0, 1.45, -0.945), Vector3(0.05, 0.9, 0.02), CREAM)
	if prop.state != "handprints":
		return
	var hands: Array[Vector2] = [
		Vector2(-0.35, 1.7),
		Vector2(-0.2, 1.3),
		Vector2(0.25, 1.6),
		Vector2(0.38, 1.2),
		Vector2(-0.4, 1.1),
		Vector2(0.1, 1.82)
	]
	for p: Vector2 in hands:
		view.add_box(
			Vector3(p.x, p.y, -0.94), Vector3(0.12, 0.15, 0.01), Color(0.95, 0.9, 0.85), 1.2
		)


func _portrait(prop: Prop, c: Color) -> void:
	view.add_box(Vector3(0, 1.55, -0.98), Vector3(0.85, 1.05, 0.04), c)
	view.add_box(Vector3(0, 1.55, -0.955), Vector3(0.7, 0.9, 0.01), Color(0.15, 0.25, 0.18))
	view.add_box(Vector3(0, 1.42, -0.95), Vector3(0.4, 0.3, 0.01), INK)
	var scratched: bool = prop.state == "scratched"
	var face: Color = Color(0.1, 0.02, 0.02) if scratched else Color(0.86, 0.72, 0.6)
	view.add_box(Vector3(0, 1.72, -0.945), Vector3(0.26, 0.34, 0.01), face)
	if scratched:
		for i: int in 4:
			var slash: MeshInstance3D = view.box_node(
				Vector3(-0.06 + i * 0.04, 1.72, -0.94), Vector3(0.02, 0.4, 0.01), CREAM, 0.8
			)
			slash.rotation.z = 0.5
			view.target.add_child(slash)
	else:
		for x: float in [-0.05, 0.05]:
			view.add_box(Vector3(x, 1.76, -0.94), Vector3(0.04, 0.03, 0.01), INK)
	view.add_label(_at(0.95, FACE_Z), prop.label, CREAM, 0.003)


## Sky above, grass below, a sun and a house; upside down turns the lot.
func _painting(prop: Prop, c: Color) -> void:
	var canvas: Node3D = Node3D.new()
	canvas.position = Vector3(0, 1.55, -0.97)
	if prop.state == "upside_down":
		canvas.rotation.z = PI
	var keep: Node3D = view.target
	keep.add_child(canvas)
	view.target = canvas
	view.add_box(Vector3.ZERO, Vector3(1.1, 0.8, 0.04), c)
	view.add_box(Vector3(0, 0.15, 0.025), Vector3(0.96, 0.36, 0.01), Color(0.35, 0.5, 0.75))
	view.add_box(Vector3(0, -0.18, 0.025), Vector3(0.96, 0.3, 0.01), Color(0.25, 0.5, 0.2))
	view.add_box(Vector3(0.3, 0.2, 0.035), Vector3(0.12, 0.12, 0.01), Color(0.95, 0.8, 0.2), 1.0)
	view.add_box(Vector3(-0.15, -0.02, 0.035), Vector3(0.22, 0.2, 0.01), Color(0.7, 0.2, 0.15))
	view.add_label(_at(-0.3, 0.05), prop.label, CREAM, 0.003)
	view.target = keep


func _mirror(prop: Prop, c: Color) -> void:
	view.add_box(Vector3(0, 0.8, -0.75), Vector3(0.7, 0.15, 0.45), Color(0.9, 0.9, 0.88))
	view.add_box(Vector3(0, 1.6, -0.98), Vector3(0.75, 0.95, 0.04), c)
	var empty: bool = prop.state == "empty"
	var glass: Color = Color(0.01, 0.01, 0.02) if empty else Color(0.55, 0.62, 0.66)
	view.add_box(Vector3(0, 1.6, -0.955), Vector3(0.62, 0.82, 0.01), glass, 0.0 if empty else 0.5)
	if not empty:
		view.add_box(Vector3(0, 1.45, -0.945), Vector3(0.28, 0.35, 0.01), Color(0.3, 0.28, 0.26))
		view.add_box(Vector3(0, 1.72, -0.945), Vector3(0.14, 0.18, 0.01), Color(0.7, 0.6, 0.5))
	if prop.state == "figure":
		view.add_box(Vector3(0.16, 1.7, -0.94), Vector3(0.2, 0.62, 0.01), Color.BLACK)
		view.add_box(Vector3(0.16, 1.9, -0.935), Vector3(0.12, 0.02, 0.01), Color.RED, 3.0)
