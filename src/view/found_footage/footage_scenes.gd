class_name FootageScenes
extends RefCounted
## The seven events in 3D for the first-person view, built from PsxKit parts
## while an event plays and freed when it is over. Every scene is a base node
## on the event's cell holding one "mover"; pose() moves it from the event's
## progress (0 when it starts, 1 when it is gone). Doorway scenes are built
## for an east-west passage and turned when the passage runs north-south.

const DARK: Color = Color(0.03, 0.03, 0.03)
const WOOD: Color = Color(0.36, 0.23, 0.13)
const PALE: Color = Color(0.82, 0.8, 0.72)
const EYE_RED: Color = Color(0.9, 0.1, 0.1)

var kit: PsxKit
var root: Node3D
var grid: CellGrid
var _built: Dictionary = {}


func _init(parts: PsxKit, parent: Node3D, on: CellGrid) -> void:
	kit = parts
	root = parent
	grid = on


## Build, pose or free every event's scene; `eye` is where the camera is.
func sync(events: Array[FootageEvent], eye: Vector3) -> void:
	for event: FootageEvent in events:
		var node: Node3D = _built.get(event.id, null)
		var live: bool = event.phase == FootageEvent.Phase.ACTIVE
		if live and node == null:
			node = _build(event)
			root.add_child(node)
			_built[event.id] = node
		elif not live and node != null:
			node.queue_free()
			_built[event.id] = null
			node = null
		if node != null:
			pose(event, node.get_child(0) as Node3D, eye - node.position)


func pose(event: FootageEvent, mover: Node3D, to_eye: Vector3) -> void:
	var p: float = event.progress()
	match event.kind:
		"shadow":
			mover.position.z = lerpf(-0.95, 0.95, smoothstep(0.05, 0.45, p))
			mover.visible = p < 0.5
		"door":
			mover.rotation.y = PI / 2.0 * (1.0 - smoothstep(0.08, 0.16, p))
		"face":
			var flash: bool = fposmod(p * 23.0, 1.0) > 0.45 or p > 0.8
			(mover.get_child(0) as OmniLight3D).light_energy = 2.4 if flash else 0.05
			(mover.get_child(1) as Node3D).visible = p > 0.3
			mover.rotation.y = atan2(to_eye.x, to_eye.z)
		"chair":
			mover.position.x = lerpf(-0.7, 0.7, smoothstep(0.1, 0.5, p))
			mover.rotation.y = p * 0.8
		"hanging":
			mover.rotation.z = sin(p * TAU * 1.5) * 0.12
			mover.rotation.y = p * 2.5
		"crawler":
			mover.rotation.y = atan2(to_eye.x, to_eye.z)
			mover.position = Vector3(to_eye.x, 0.0, to_eye.z).normalized() * lerpf(-0.6, 0.9, p)
		_:
			mover.rotation.y = atan2(to_eye.x, to_eye.z)


func _build(event: FootageEvent) -> Node3D:
	var base: Node3D = Node3D.new()
	base.position = FpsView.to_world(event.cell)
	var doorway: bool = event.kind == "shadow" or event.kind == "door"
	if doorway and not grid.is_open(event.cell + Vector2i.LEFT):
		base.rotation.y = PI / 2.0
	var mover: Node3D = Node3D.new()
	base.add_child(mover)
	match event.kind:
		"shadow":
			_shadow(mover)
		"door":
			_door(mover)
		"face":
			_face(mover)
		"chair":
			_chair(mover)
		"hanging":
			_hanging(mover)
		"crawler":
			_crawler(mover)
		_:
			mover.add_child(kit.figure(Vector3.ZERO, 0.0))
	return base


## A man-shaped hole in the light: no eyes, just dark.
func _shadow(mover: Node3D) -> void:
	mover.add_child(kit.box(Vector3(0, 0.9, 0), Vector3(0.28, 1.8, 0.55), DARK))
	mover.add_child(kit.box(Vector3(0, 2.0, 0), Vector3(0.3, 0.36, 0.3), DARK))


## A panel hinged on the north jamb; pose() swings it shut.
func _door(mover: Node3D) -> void:
	mover.position = Vector3(0, 0, -FpsView.CELL / 2.0 + 0.04)
	mover.add_child(kit.box(Vector3(0, 1.1, 0.92), Vector3(0.08, 2.2, 1.84), WOOD.darkened(0.3)))
	mover.add_child(kit.box(Vector3(0.07, 1.05, 1.6), Vector3(0.06, 0.08, 0.14), PALE))


## A flickering bulb and, once it has flickered, a face where none should be.
func _face(mover: Node3D) -> void:
	var bulb: OmniLight3D = OmniLight3D.new()
	bulb.position = Vector3(0, 2.3, 0)
	bulb.light_color = Color(0.85, 0.9, 1.0)
	bulb.omni_range = 7.0
	mover.add_child(bulb)
	var face: Node3D = Node3D.new()
	face.add_child(kit.box(Vector3(0, 1.7, 0), Vector3(0.55, 0.7, 0.4), PALE, 1.6))
	face.add_child(kit.box(Vector3(-0.13, 1.82, 0.21), Vector3(0.13, 0.07, 0.02), Color.BLACK))
	face.add_child(kit.box(Vector3(0.13, 1.82, 0.21), Vector3(0.13, 0.07, 0.02), Color.BLACK))
	face.add_child(kit.box(Vector3(0, 1.52, 0.21), Vector3(0.12, 0.3, 0.02), Color.BLACK))
	mover.add_child(face)


func _chair(mover: Node3D) -> void:
	var wood: Color = WOOD.darkened(0.35)
	mover.add_child(kit.box(Vector3(0, 0.5, 0), Vector3(0.6, 0.08, 0.6), wood))
	mover.add_child(kit.box(Vector3(0, 0.9, -0.27), Vector3(0.6, 0.75, 0.07), wood))
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var leg: Vector3 = Vector3(corner.x * 0.26, 0.25, corner.y * 0.26)
		mover.add_child(kit.box(leg, Vector3(0.07, 0.5, 0.07), wood))


## Hung from the ceiling by a rope: head, then a long dark body.
func _hanging(mover: Node3D) -> void:
	mover.position = Vector3(0, PsxKit.WALL_HEIGHT, 0)
	mover.add_child(kit.box(Vector3(0, -0.35, 0), Vector3(0.03, 0.7, 0.03), WOOD))
	mover.add_child(kit.box(Vector3(0, -0.84, 0), Vector3(0.26, 0.3, 0.26), PALE.darkened(0.5)))
	mover.add_child(kit.box(Vector3(0, -1.55, 0), Vector3(0.4, 1.1, 0.26), DARK))


## Low and long, head first (+Z), limbs splayed, two red points for eyes.
func _crawler(mover: Node3D) -> void:
	mover.add_child(kit.box(Vector3(0, 0.2, 0), Vector3(0.5, 0.3, 1.3), DARK))
	mover.add_child(kit.box(Vector3(0, 0.28, 0.8), Vector3(0.36, 0.3, 0.36), DARK))
	mover.add_child(kit.box(Vector3(-0.09, 0.33, 0.99), Vector3(0.07, 0.04, 0.02), EYE_RED, 3.0))
	mover.add_child(kit.box(Vector3(0.09, 0.33, 0.99), Vector3(0.07, 0.04, 0.02), EYE_RED, 3.0))
	for z: float in [-0.4, 0.4]:
		mover.add_child(kit.box(Vector3(0, 0.1, z), Vector3(1.5, 0.07, 0.07), DARK))
