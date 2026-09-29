class_name FootageEvent
extends RefCounted
## One scripted scare from a FootageData row. It waits until the player comes
## within `radius` path steps, plays for DURATION seconds, then is gone for
## good - on tape if it was filmed while it played, missed otherwise.

enum Phase { WAITING, ACTIVE, OVER }

const DURATION: float = 5.0

var id: String
var kind: String
var cell: Vector2i
var radius: int
var label: String
var text: String
var phase: Phase = Phase.WAITING
var captured: bool = false
var left: float = 0.0
## Path distance from every cell of the grid to this event (-1 unreachable).
var reach: PackedInt32Array = PackedInt32Array()
var _grid: CellGrid


## Row: [id, kind, x, y, radius, label, prose]; `flip` mirrors the building.
static func from_row(row: Array, grid: CellGrid, flip: Vector2i) -> FootageEvent:
	var event: FootageEvent = FootageEvent.new()
	event.id = row[0]
	event.kind = row[1]
	var x: int = row[2]
	var y: int = row[3]
	event._grid = grid
	event.place(FootageData.flipped(Vector2i(x, y), flip))
	event.radius = row[4]
	event.label = row[5]
	event.text = row[6]
	return event


## Put the event on `at` (the seed deals spots out between events).
func place(at: Vector2i) -> void:
	cell = at
	reach = _grid.distances(at)


## Path steps from `c` to the event, or -1 if it cannot be reached.
func steps_from(c: Vector2i) -> int:
	return reach[c.y * _grid.width + c.x] if _grid.in_bounds(c) else -1


## True when standing on `c` sets the event off (if it is still waiting).
func in_ring(c: Vector2i) -> bool:
	var d: int = steps_from(c)
	return d >= 0 and d <= radius


func is_live() -> bool:
	return phase == Phase.ACTIVE and not captured


func start() -> void:
	phase = Phase.ACTIVE
	left = DURATION


## Count down; true on the tick the event ends.
func tick(delta: float) -> bool:
	if phase != Phase.ACTIVE:
		return false
	left -= delta
	if left > 0.0:
		return false
	phase = Phase.OVER
	return true


## 0 when it starts, 1 when it is gone: views animate from this.
func progress() -> float:
	return clampf(1.0 - left / DURATION, 0.0, 1.0)
