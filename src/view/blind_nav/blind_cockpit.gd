class_name BlindCockpit
extends Node3D
## The inside of the sub, for the first-person view: a cramped steel room
## around a fixed camera looking at -Z. Centre: the camera monitor. Left: the
## sonar scope. Right: coordinates, hull dial. Overhead: the alarm lamp.

const STEEL: Color = Color(0.2, 0.21, 0.2)
const DARK: Color = Color(0.07, 0.07, 0.08)
const FACE: Color = Color(0.32, 0.3, 0.24)
const AMBER: Color = Color(1.0, 0.72, 0.3)
const SIDE_YAW: float = 0.55

var sonar_img: Image = BlindScreens.blank(BlindScreens.SONAR_PX)
var photo_img: Image = BlindScreens.blank(BlindScreens.PHOTO_PX)
var sonar_tex: ImageTexture = ImageTexture.create_from_image(sonar_img)
var photo_tex: ImageTexture = ImageTexture.create_from_image(photo_img)
var coords: Label3D
var hull_label: Label3D
var waypoint_label: Label3D
var photo_caption: Label3D
var needle: Node3D = Node3D.new()
var alarm_lens: MeshInstance3D
var alarm_light: OmniLight3D = OmniLight3D.new()
var _kit: PsxKit


func build(kit: PsxKit) -> void:
	_kit = kit
	_shell()
	_centre()
	_left()
	_right()
	alarm_lens = kit.box(Vector3(0, 2.15, -1.3), Vector3(0.26, 0.12, 0.08), Color.RED, 3.0)
	add_child(kit.box(Vector3(0, 2.15, -1.33), Vector3(0.34, 0.18, 0.06), DARK))
	add_child(alarm_lens)
	alarm_light.position = Vector3(0, 1.9, -1.0)
	alarm_light.light_color = Color(1.0, 0.1, 0.05)
	alarm_light.light_energy = 3.0
	alarm_light.omni_range = 4.0
	add_child(alarm_light)
	set_alarm(false)


func set_alarm(on: bool) -> void:
	alarm_lens.visible = on
	alarm_light.visible = on


## 100 % hull points the needle up-left, 0 % up-right.
func set_hull(hull: int) -> void:
	needle.rotation.z = lerpf(-1.1, 1.1, 1.0 - hull / 100.0)
	hull_label.text = "HULL %d%%" % hull
	hull_label.modulate = AMBER if hull > 25 else Color.RED


func _shell() -> void:
	add_child(_kit.box(Vector3(0, 1.2, -1.45), Vector3(3.6, 2.6, 0.1), STEEL))
	add_child(_kit.box(Vector3(0, -0.05, -0.2), Vector3(3.6, 0.1, 3.0), DARK))
	add_child(_kit.box(Vector3(0, 2.4, -0.2), Vector3(3.6, 0.1, 3.0), STEEL.darkened(0.3)))
	for side: float in [-1.0, 1.0]:
		add_child(_kit.box(Vector3(side * 1.75, 1.2, -0.2), Vector3(0.1, 2.6, 3.0), STEEL))
		add_child(_kit.box(Vector3(side * 0.6, 2.25, -0.4), Vector3(0.08, 0.08, 2.4), DARK))
	add_child(_kit.box(Vector3(0, 0.55, -1.05), Vector3(3.2, 0.1, 0.7), STEEL.lightened(0.1)))
	add_child(_kit.box(Vector3(0, 0.27, -1.3), Vector3(3.2, 0.5, 0.1), DARK))
	for x: float in [-0.7, -0.35, 0.35, 0.7]:
		add_child(_kit.box(Vector3(x, 0.63, -1.1), Vector3(0.08, 0.05, 0.08), AMBER, 1.5))
	var lamp: OmniLight3D = OmniLight3D.new()
	lamp.position = Vector3(0, 2.0, -0.3)
	lamp.light_color = AMBER
	lamp.light_energy = 0.7
	lamp.omni_range = 4.5
	add_child(lamp)


func _centre() -> void:
	add_child(_kit.box(Vector3(0, 1.4, -1.38), Vector3(0.95, 0.9, 0.06), DARK))
	add_child(_screen(Vector3(0, 1.4, -1.34), 0.0, 0.72, photo_tex))
	photo_caption = _text(Transform3D(Basis(), Vector3(0, 1.4, -1.33)), "", 0.004)
	photo_caption.modulate = Color(0.8, 0.9, 0.8)
	_caption(Transform3D(Basis(), Vector3(0, 1.94, -1.39)), "CAMERA")
	waypoint_label = _text(Transform3D(Basis(), Vector3(0, 0.8, -1.39)), "", 0.0026)


func _left() -> void:
	var basis: Basis = Basis(Vector3.UP, SIDE_YAW)
	var at: Vector3 = Vector3(-1.05, 1.3, -1.1)
	var bezel: MeshInstance3D = _kit.box(at, Vector3(0.75, 0.75, 0.06), DARK)
	bezel.basis = basis
	add_child(bezel)
	add_child(_screen(at + basis.z * 0.04, SIDE_YAW, 0.64, sonar_tex))
	_caption(Transform3D(basis, at + basis.z * 0.04 + Vector3(0, 0.45, 0)), "SONAR")


func _right() -> void:
	var basis: Basis = Basis(Vector3.UP, -SIDE_YAW)
	var at: Vector3 = Vector3(1.05, 1.3, -1.1)
	var plate: MeshInstance3D = _kit.box(at, Vector3(0.8, 1.1, 0.06), DARK)
	plate.basis = basis
	add_child(plate)
	var face: Vector3 = at + basis.z * 0.04
	coords = _text(Transform3D(basis, face + Vector3(0, 0.3, 0)), "", 0.0032)
	coords.modulate = Color(0.5, 1.0, 0.6)
	var dial: MeshInstance3D = _kit.box(face + Vector3(0, -0.12, 0), Vector3(0.3, 0.3, 0.01), FACE)
	dial.basis = basis
	add_child(dial)
	needle.transform = Transform3D(basis, face + Vector3(0, -0.2, 0) + basis.z * 0.01)
	needle.add_child(_kit.box(Vector3(0, 0.1, 0), Vector3(0.02, 0.2, 0.01), AMBER, 2.0))
	add_child(needle)
	hull_label = _text(Transform3D(basis, face + Vector3(0, -0.4, 0)), "", 0.0026)


## A label added to the cockpit, returned for the ones that change.
func _text(xf: Transform3D, text: String, px: float) -> Label3D:
	var label: Label3D = _kit.label(xf, text, AMBER, px)
	add_child(label)
	return label


func _caption(xf: Transform3D, text: String) -> void:
	add_child(_kit.label(xf, text, AMBER.darkened(0.3), 0.0025))


func _screen(at: Vector3, yaw: float, size: float, tex: ImageTexture) -> MeshInstance3D:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.disable_fog = true
	var node: MeshInstance3D = MeshInstance3D.new()
	node.mesh = quad
	node.material_override = mat
	node.position = at
	node.rotation.y = yaw
	return node
