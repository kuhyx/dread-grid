extends TextView
## Found Footage as a tape transcript: every command is two seconds of tape and
## every line carries its timecode. Events are told with a direction; film one
## by facing it with the tape rolling. Messages the rules raise mid-command
## are held back and written after the line for the command itself; each
## line is stamped with the tape time it happened at.

var tape: FoundFootage
var _held: Array[String] = []
var _since: float = 0.0
var _ended: bool = false
var _won: bool = false


func make_concept(seed_value: int) -> Concept:
	tape = FoundFootage.new(seed_value)
	return tape


func concept_id() -> String:
	return "found_footage"


func tick_seconds() -> float:
	return 2.0


func words() -> Dictionary:
	return {
		"forward": &"forward",
		"f": &"forward",
		"back": &"back",
		"b": &"back",
		"left": &"turn_left",
		"right": &"turn_right",
		"north": &"face_north",
		"east": &"face_east",
		"south": &"face_south",
		"west": &"face_west",
		"go north": &"go_north",
		"go east": &"go_east",
		"go south": &"go_south",
		"go west": &"go_west",
		"record": &"rec_start",
		"rec": &"rec_start",
		"stop": &"rec_stop",
		"wait": &"wait",
		"look": &"look",
		"l": &"look",
	}


func intro() -> void:
	Wire.link(tape.event_started, _on_event_started)
	write("[b]FOUND FOOTAGE[/b]")
	write("An abandoned sanatorium, a camcorder, a battery that will not last.")
	write(
		(
			"Things happen here, once each, when you come near. Face one with the tape"
			+ " rolling ('record') to get it. Five on tape and you have your proof."
		)
	)
	write("'north' etc. turn you, 'go north' walks, 'stop' saves battery. 'help' lists all.")
	write(_stamped(0.0, FootageProse.look(tape.grid, tape.walker, tape.room_name())))


func on_acted(action: StringName) -> void:
	write(_stamped(_since, _narrate(action)))
	for line: String in _held:
		write(line)
	_held.clear()
	_since = tape.elapsed
	if _ended:
		super._on_finished(_won)


func _narrate(action: StringName) -> String:
	var line: String = "You turn to face %s." % GridWalker.DIR_NAMES[tape.walker.facing]
	match action:
		&"forward", &"back", &"go_north", &"go_east", &"go_south", &"go_west":
			Sfx.play(self, Sfx.sample("footstep"), -8.0)
			line = "You walk. " + FootageProse.look(tape.grid, tape.walker, tape.room_name())
		&"rec_start":
			line = "[color=#e33]REC[/color] The tape is rolling."
		&"rec_stop":
			line = "[color=#999]STOP[/color] You save the battery."
		&"look":
			line = FootageProse.look(tape.grid, tape.walker, tape.room_name())
		&"wait":
			line = "You hold still and listen."
	return line


## A transcript line: "[00:03:12] text".
func _stamped(at: float, text: String) -> String:
	return "[color=#6a6][lb]%s[rb][/color] %s" % [FootageProse.timecode(at, false), text]


func _on_message(text: String) -> void:
	_held.append(_stamped(tape.elapsed, text))


func _on_finished(won: bool) -> void:
	_ended = true
	_won = won


func _on_event_started(event: FootageEvent) -> void:
	Sfx.play(self, Sfx.tone(70.0, 1.2, FootageProse.pan(tape.walker, event.cell), 0.5), -2.0)
	Sfx.play(self, Sfx.sample("static"), -8.0)
