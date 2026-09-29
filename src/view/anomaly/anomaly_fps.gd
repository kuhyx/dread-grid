extends FpsView
## Anomaly Loop, first person: the corridor in 3D, props rebuilt every loop.
## Walking out, the left wall (side -1) is -Z and the right wall +Z.

const HALF: float = FpsView.CELL / 2.0
const DOOR_GREY: Color = Color(0.3, 0.3, 0.32)

var loop: AnomalyLoop
var _props_root: Node3D = Node3D.new()
var _shown_loop: int = -1


func make_concept(seed_value: int) -> Concept:
	loop = AnomalyLoop.new(seed_value)
	return loop


func concept_id() -> String:
	return "anomaly"


func build_world() -> void:
	environment.fog_density = 0.06
	build_grid(loop.grid, Color(0.72, 0.7, 0.62), Color(0.35, 0.33, 0.3))
	world.add_child(_props_root)
	var far_x: float = (AnomalyCatalog.LENGTH - 0.5) * CELL - 0.03
	add_box(Vector3(far_x, 1.0, CELL), Vector3(0.04, 2.0, 1.1), DOOR_GREY)
	add_box(Vector3(-HALF + 0.03, 1.0, CELL), Vector3(0.04, 2.0, 1.1), DOOR_GREY)
	hud.push("Walk on if all is normal. Turn back (S) if anything is wrong.")


func refresh() -> void:
	super.refresh()
	if _shown_loop != loop.loop_index:
		_shown_loop = loop.loop_index
		_rebuild_props()
		place_camera(loop.walker.cell, loop.walker.facing, true)


func on_acted(_action: StringName) -> void:
	if _shown_loop == loop.loop_index:
		place_camera(loop.walker.cell, loop.walker.facing)
		Sfx.play(self, Sfx.sample("footstep"), -6.0)


func _rebuild_props() -> void:
	for child: Node in _props_root.get_children():
		child.queue_free()
	target = _props_root
	for prop: Prop in loop.props:
		_build_prop(prop)
	target = world


## A transform on the wall at `side`, facing into the corridor.
func _on_wall(x: float, side: int, y: float, inset: float) -> Transform3D:
	var z: float = CELL + side * (HALF - inset)
	return Transform3D(Basis(Vector3.UP, 0.0 if side < 0 else PI), Vector3(x, y, z))


func _build_prop(prop: Prop) -> void:
	var x: float = float(prop.cell.x) * CELL
	var side: int = prop.side
	var color: Color = AnomalyCatalog.color_of(prop)
	var wall: Vector3 = _on_wall(x, side, 0.0, 0.05).origin
	match prop.kind:
		"light":
			var on: bool = prop.state == "on"
			add_box(Vector3(x, 2.55, CELL), Vector3(0.7, 0.06, 0.4), color, 2.0 if on else 0.0)
			if on:
				add_light(Vector3(x, 2.2, CELL), color, 1.2, 5.0)
		"poster":
			add_box(wall + Vector3(0, 1.5, 0), Vector3(1.0, 0.9, 0.02), color)
			add_label(_on_wall(x, side, 1.5, 0.08), prop.label, Color.BLACK)
		"door":
			add_box(wall + Vector3(0, 1.0, 0), Vector3(1.0, 2.0, 0.02), Color.BLACK)
			var panel: MeshInstance3D = box_node(
				wall + Vector3(0, 1.0, -side * 0.05), Vector3(1.0, 2.0, 0.05), color
			)
			if prop.state == "open":
				panel.position += Vector3(-0.45, 0, -side * 0.45)
				panel.rotation.y = PI / 2.0
			target.add_child(panel)
		"extinguisher":
			add_box(wall + Vector3(0, 0.9, -side * 0.12), Vector3(0.2, 0.5, 0.2), color)
		"clock":
			add_box(wall + Vector3(0, 2.0, 0), Vector3(0.5, 0.5, 0.02), color)
			add_label(_on_wall(x, side, 2.0, 0.08), prop.label, Color.BLACK)
		"bench":
			add_box(wall + Vector3(0, 0.25, -side * 0.25), Vector3(1.4, 0.45, 0.4), color)
		"sign":
			var sx: float = (AnomalyCatalog.LENGTH - 0.5) * CELL - 0.06
			add_box(Vector3(sx, 2.25, CELL), Vector3(0.04, 0.3, 0.9), color, 1.5)
			var face: Basis = Basis(Vector3.UP, -PI / 2.0)
			add_label(
				Transform3D(face, Vector3(sx - 0.03, 2.25, CELL)), prop.label, Color.WHITE, 0.004
			)
		"figure":
			add_figure(wall + Vector3(0, 0, -side * 0.3), -PI / 2.0)
		"stain":
			add_box(Vector3(x, 0.01, CELL), Vector3(1.3, 0.01, 0.9), color)
