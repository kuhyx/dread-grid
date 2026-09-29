extends TextView
## Anomaly Loop as prose: each step describes the props around you. The
## anomaly is one changed sentence; learn the normal corridor by heart.

var loop: AnomalyLoop
var _shown_loop: int = -1


func make_concept(seed_value: int) -> Concept:
	loop = AnomalyLoop.new(seed_value)
	return loop


func concept_id() -> String:
	return "anomaly"


func words() -> Dictionary:
	return {
		"forward": &"forward",
		"f": &"forward",
		"w": &"forward",
		"walk": &"forward",
		"back": &"turn_back",
		"turn": &"turn_back",
		"s": &"turn_back",
		"look": &"look",
		"l": &"look",
	}


func intro() -> void:
	write("[b]ANOMALY LOOP[/b]")
	write("A corridor that repeats. If everything is as it should be, walk through the far door.")
	write(
		"If anything is different, turn back and leave the way you came. Eight right calls in a row."
	)
	_enter_loop()


func refresh() -> void:
	super.refresh()
	if _shown_loop != loop.loop_index:
		_enter_loop()


func on_acted(action: StringName) -> void:
	if _shown_loop != loop.loop_index:
		return
	if action == &"turn_back":
		write("You turn around." if loop.walking_back() else "You face the far door again.")
	Sfx.play(self, Sfx.sample("footstep"), -8.0)
	_describe()


func _enter_loop() -> void:
	_shown_loop = loop.loop_index
	write(
		(
			"\n[color=#b33]-- Loop %d --[/color] You stand at the start of a long, humming corridor."
			% (loop.loop_index + 1)
		)
	)
	_describe()


func _describe() -> void:
	var segment: int = loop.walker.cell.x
	var lines: Array[String] = []
	for prop: Prop in loop.props_in(segment):
		lines.append(AnomalyCatalog.describe(prop, loop.walking_back()))
	var place: String = "Step %d of %d." % [segment + 1, AnomalyCatalog.LENGTH]
	write(
		(
			"%s %s"
			% [place, " ".join(PackedStringArray(lines)) if not lines.is_empty() else "Bare walls."]
		)
	)
