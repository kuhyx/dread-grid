class_name FootageProse
extends RefCounted
## Words for Found Footage, shared by the rules' messages and the text view:
## tape timecodes, where something is relative to the player, a look around.

const RELATIVE: PackedStringArray = ["ahead of you", "on your right", "behind you", "on your left"]


## Elapsed seconds as tape timecode: HH:MM:SS, plus :FF (25 fps) if `frames`.
static func timecode(seconds: float, frames: bool) -> String:
	var hours: int = floori(seconds / 3600.0)
	var minutes: int = floori(seconds / 60.0) % 60
	var out: String = "%02d:%02d:%02d" % [hours, minutes, floori(seconds) % 60]
	if frames:
		out += ":%02d" % int(fposmod(seconds, 1.0) * 25.0)
	return out


## The compass facing (CellGrid.DIRS index) that best points from `from` to
## `to`, or -1 when they are the same cell.
static func compass(from: Vector2i, to: Vector2i) -> int:
	var probe: GridWalker = GridWalker.new(null, from, -1)
	probe.face_towards(to)
	return probe.facing


## "to the north, ahead of you" - compass plus where that is for the walker.
static func where(walker: GridWalker, target: Vector2i) -> String:
	var dir: int = compass(walker.cell, target)
	if dir < 0:
		return "right where you stand"
	return "to the %s, %s" % [GridWalker.DIR_NAMES[dir], RELATIVE[(dir - walker.facing + 4) % 4]]


## Stereo pan for a sound at `target`: -1 hard left .. 1 hard right.
static func pan(walker: GridWalker, target: Vector2i) -> float:
	var d: Vector2 = Vector2(target - walker.cell)
	if d == Vector2.ZERO:
		return 0.0
	var right: Vector2 = Vector2(CellGrid.DIRS[(walker.facing + 1) % 4])
	return clampf(d.normalized().dot(right), -1.0, 1.0)


## What the player can make out: the room, facing, ways on, open floor ahead.
static func look(grid: CellGrid, walker: GridWalker, room: String) -> String:
	var ways: Array[String] = []
	for dir: int in 4:
		if grid.is_open(walker.cell + CellGrid.DIRS[dir]):
			ways.append(GridWalker.DIR_NAMES[dir])
	var ahead: int = 0
	while grid.is_open(walker.cell + walker.forward_vector() * (ahead + 1)):
		ahead += 1
	var sight: String = "A wall, right in front of you."
	if ahead > 0:
		sight = "%d step%s of floor ahead." % [ahead, "" if ahead == 1 else "s"]
	return (
		"You are in %s, facing %s. Ways on: %s. %s"
		% [room, GridWalker.DIR_NAMES[walker.facing], ", ".join(PackedStringArray(ways)), sight]
	)
