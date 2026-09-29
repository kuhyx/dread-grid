class_name FpsView
extends GameView
## First-person, grid-step view (a dungeon crawler's movement). The world
## renders into a quarter-resolution SubViewport shown without filtering,
## with vertex-snapping materials and fog: one PS1 look for every concept.

const CELL: float = 2.0
const EYE: float = 1.1
const STEP_TIME: float = 0.2
const SHRINK: int = 4

var world: Node3D = Node3D.new()
## Where the add_* helpers put new nodes (world unless a subclass swaps it).
var target: Node3D = world
var camera: Camera3D = Camera3D.new()
var flashlight: SpotLight3D = SpotLight3D.new()
var environment: Environment = Environment.new()
var kit: PsxKit = PsxKit.new()
var _from_pos: Vector3
var _to_pos: Vector3
var _from_yaw: float = 0.0
var _to_yaw: float = 0.0
var _anim: float = 1.0


func build() -> void:
	var container: SubViewportContainer = SubViewportContainer.new()
	container.stretch = true
	container.stretch_shrink = SHRINK
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(container)
	var viewport: SubViewport = SubViewport.new()
	container.add_child(viewport)
	viewport.add_child(world)
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.BLACK
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.12, 0.11, 0.13)
	environment.fog_enabled = true
	environment.fog_light_color = Color.BLACK
	environment.fog_density = 0.12
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = environment
	world.add_child(world_env)
	camera.fov = 70.0
	world.add_child(camera)
	flashlight.spot_range = 14.0
	flashlight.spot_angle = 32.0
	flashlight.light_energy = 2.2
	flashlight.light_color = Color(1.0, 0.93, 0.8)
	camera.add_child(flashlight)
	hud = Hud.new()
	add_child(hud)
	build_world()
	Sfx.play(self, Sfx.music(concept_id()), -14.0)


## Subclass hooks ------------------------------------------------------------


func build_world() -> void:
	pass


func concept_id() -> String:
	return ""


## Camera ---------------------------------------------------------------------


func busy() -> bool:
	return _anim < 1.0


static func to_world(c: Vector2i, y: float = 0.0) -> Vector3:
	return Vector3(c.x * CELL, y, c.y * CELL)


## Move the camera to a cell and facing, animated unless `instant`. The
## target yaw is unwrapped next to the current one so turns go the short way.
func place_camera(cell: Vector2i, facing: int, instant: bool = false) -> void:
	_from_pos = camera.position
	_from_yaw = camera.rotation.y
	_to_pos = to_world(cell, EYE)
	_to_yaw = _from_yaw + wrapf(-facing * PI / 2.0 - _from_yaw, -PI, PI)
	_anim = 1.0 if instant else 0.0
	if instant:
		camera.position = _to_pos
		camera.rotation.y = _to_yaw


func _process(delta: float) -> void:
	if _anim < 1.0:
		_anim = minf(1.0, _anim + delta / STEP_TIME)
		var t: float = smoothstep(0.0, 1.0, _anim)
		camera.position = _from_pos.lerp(_to_pos, t)
		camera.rotation.y = lerpf(_from_yaw, _to_yaw, t)
	super(delta)


## Geometry ---------------------------------------------------------------------


func material(color: Color, glow: float = 0.0) -> ShaderMaterial:
	return kit.material(color, glow)


func build_grid(grid: CellGrid, wall: Color, floor_color: Color) -> void:
	target.add_child(kit.grid_mesh(grid, wall, floor_color, CELL))


func box_node(at: Vector3, size: Vector3, color: Color, glow: float = 0.0) -> MeshInstance3D:
	return kit.box(at, size, color, glow)


func add_box(at: Vector3, size: Vector3, color: Color, glow: float = 0.0) -> void:
	target.add_child(kit.box(at, size, color, glow))


## A tall dark silhouette with red eyes, facing `yaw`.
func add_figure(at: Vector3, yaw: float = 0.0) -> void:
	target.add_child(kit.figure(at, yaw))


## Text on a surface; `xf` places and turns it (Label3D faces +Z).
func add_label(xf: Transform3D, text: String, color: Color, px: float = 0.0025) -> void:
	target.add_child(kit.label(xf, text, color, px))


func add_light(at: Vector3, color: Color, energy: float = 1.0, reach: float = 6.0) -> void:
	var light: OmniLight3D = OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	target.add_child(light)
