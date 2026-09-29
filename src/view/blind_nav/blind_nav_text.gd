extends TextView
## Blind Descent as a terminal: coordinates after every move, the sonar as a
## line of text and as stereo beeps - one per direction, panned west to east,
## higher and louder the closer the rock - and photos as a 5x5 sketch.

const BEEP_GAP: float = 0.13
const CLEAR_TONE: float = 180.0

var nav: BlindNav
var _seen_crashes: int = 0


func make_concept(seed_value: int) -> Concept:
	nav = BlindNav.new(seed_value)
	return nav


func concept_id() -> String:
	return "blind_nav"


func words() -> Dictionary:
	return {
		"forward": &"forward",
		"f": &"forward",
		"back": &"back",
		"b": &"back",
		"left": &"turn_left",
		"l": &"turn_left",
		"right": &"turn_right",
		"r": &"turn_right",
		"ping": &"ping",
		"p": &"ping",
		"photo": &"photo",
		"ph": &"photo",
		"status": &"status",
	}


## A photo takes its whole developing time in one command.
func tick_seconds() -> float:
	return maxf(1.0, nav.develop_left)


func intro() -> void:
	write("[b]BLIND DESCENT[/b]")
	write("The hatch is welded shut. There is no window. There is a coordinate readout,")
	write("a sonar that pings eight ways, and a camera that takes three seconds a picture.")
	write("Log four waypoints by their coordinates. Four collisions and the hull fails.")
	write("Commands: forward/f, back/b, left/l, right/r, ping/p, photo/ph, status, help.")
	write("[color=#c93]%s[/color]" % nav.hud_line().get_slice("\n", 1))
	_where()


func on_acted(action: StringName) -> void:
	if nav.crashes > _seen_crashes:
		_seen_crashes = nav.crashes
		Sfx.play(self, Sfx.sample("crunch"), -2.0)
		Sfx.play(self, Sfx.tone(55.0, 0.8, 0.0, 0.8), -4.0)
	match action:
		&"forward", &"back", &"turn_left", &"turn_right":
			_where()
		&"ping":
			_beeps()
		&"photo":
			_sketch()


func _where() -> void:
	var c: Vector2i = nav.walker.cell
	var heading: String = GridWalker.DIR_NAMES[nav.walker.facing]
	write(
		"[color=#8ab]X %02d  Y %02d  heading %s  hull %d%%[/color]" % [c.x, c.y, heading, nav.hull]
	)


func _sketch() -> void:
	if not nav.photo_showing():
		return
	var rows: Array[String] = BlindSonar.sketch(nav.grid, nav.photo_cells)
	write("[code]%s[/code]" % "\n".join(PackedStringArray(rows)))
	if nav.photo_eye:
		write("[color=#b33]Across the top of the frame: a pupil the size of a door.[/color]")


## One beep per compass direction, north first, clockwise.
func _beeps() -> void:
	for i: int in nav.ping_ranges.size():
		var timer: SceneTreeTimer = get_tree().create_timer(BEEP_GAP * (i + 1))
		Wire.link(timer.timeout, _beep.bind(nav.ping_ranges[i], BlindSonar.pan_of(i)))


func _beep(reach: int, pan: float) -> void:
	if reach < 0:
		Sfx.play(self, Sfx.tone(CLEAR_TONE, 0.12, pan), -26.0)
		return
	var near: float = float(BlindSonar.RANGE + 1 - reach) / BlindSonar.RANGE
	Sfx.play(self, Sfx.tone(300.0 + near * 700.0, 0.12, pan), -20.0 + near * 16.0)
