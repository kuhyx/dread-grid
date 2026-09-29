class_name PsxKit
extends RefCounted
## Node factories for the PS1 look: cached vertex-snapping materials, the
## merged grid mesh, boxes, figures and labels. Returns unparented nodes.

const PSX: Shader = preload("res://src/view/common/psx.gdshader")
const WALL_HEIGHT: float = 2.6

var _materials: Dictionary = {}


func material(color: Color, glow: float = 0.0) -> ShaderMaterial:
	var key: String = "%s|%s" % [color.to_html(), glow]
	if not _materials.has(key):
		var mat: ShaderMaterial = ShaderMaterial.new()
		mat.shader = PSX
		mat.set_shader_parameter("albedo", color)
		mat.set_shader_parameter("emission", glow)
		_materials[key] = mat
	return _materials[key]


## Floors, ceilings and inward-facing walls for every open cell, one mesh.
func grid_mesh(grid: CellGrid, wall: Color, floor_color: Color, cell: float) -> MeshInstance3D:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h: float = cell / 2.0
	var up: Vector3 = Vector3(0, WALL_HEIGHT, 0)
	for c: Vector2i in grid.floor_cells():
		var o: Vector3 = Vector3(c.x * cell, 0, c.y * cell)
		var a: Vector3 = Vector3(-h, 0, -h)
		var b: Vector3 = Vector3(h, 0, -h)
		var d: Vector3 = Vector3(-h, 0, h)
		var e: Vector3 = Vector3(h, 0, h)
		_quad(st, o, [a, b, e, d], floor_color)
		_quad(st, o, [d + up, e + up, b + up, a + up], floor_color.darkened(0.4))
		for dir: Vector2i in CellGrid.DIRS:
			if not grid.is_open(c + dir):
				var n: Vector3 = Vector3(dir.x, 0, dir.y) * h
				var side: Vector3 = Vector3(-n.z, 0, n.x)
				_quad(st, o, [n - side, n + side, n + side + up, n - side + up], wall)
	st.generate_normals()
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = st.commit()
	mesh.material_override = material(Color.WHITE)
	return mesh


func box(at: Vector3, size: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var shape: BoxMesh = BoxMesh.new()
	shape.size = size
	var node: MeshInstance3D = MeshInstance3D.new()
	node.mesh = shape
	node.material_override = material(color, glow)
	node.position = at
	return node


func figure(at: Vector3, yaw: float) -> Node3D:
	var root: Node3D = Node3D.new()
	root.position = at
	root.rotation.y = yaw
	var dark: Color = Color(0.03, 0.03, 0.03)
	root.add_child(box(Vector3(0, 0.85, 0), Vector3(0.5, 1.7, 0.3), dark))
	root.add_child(box(Vector3(0, 1.95, 0), Vector3(0.32, 0.4, 0.32), dark))
	root.add_child(box(Vector3(0, 2.0, 0.17), Vector3(0.22, 0.05, 0.02), Color(0.9, 0.1, 0.1), 3.0))
	return root


func label(xf: Transform3D, text: String, color: Color, px: float) -> Label3D:
	var node: Label3D = Label3D.new()
	node.text = text
	node.modulate = color
	node.pixel_size = px
	node.font_size = 48
	node.transform = xf
	node.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return node


func _quad(st: SurfaceTool, o: Vector3, corners: Array[Vector3], color: Color) -> void:
	for i: int in [0, 1, 2, 0, 2, 3]:
		st.set_color(color)
		st.add_vertex(o + corners[i])
