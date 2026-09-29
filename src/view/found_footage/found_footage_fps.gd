extends FpsView
## Found Footage, first person, through the camcorder. On standby the building
## is near black with a weak lamp; recording switches to green night vision
## with REC and the timecode burnt in. Events are built only while they play.

const WALLS: Color = Color(0.55, 0.53, 0.46)
const FLOORS: Color = Color(0.3, 0.28, 0.25)

var tape: FoundFootage
var overlay: FootageCamOverlay = FootageCamOverlay.new(true)
var scenes: FootageScenes


func make_concept(seed_value: int) -> Concept:
	tape = FoundFootage.new(seed_value)
	return tape


func concept_id() -> String:
	return "found_footage"


func extra_keys() -> Dictionary:
	return {KEY_SPACE: &"record"}


func build_world() -> void:
	build_grid(tape.grid, WALLS, FLOORS)
	scenes = FootageScenes.new(kit, world, tape.grid)
	add_child(overlay)
	Wire.link(tape.event_started, _on_event_started)
	Wire.link(tape.event_captured, _on_event_captured)
	place_camera(tape.walker.cell, tape.walker.facing, true)
	hud.push("Something happens in here. Get five of it on tape. Space records.")


func refresh() -> void:
	super.refresh()
	var rec: bool = tape.recording
	environment.ambient_light_color = Color(0.24, 0.27, 0.24) if rec else Color(0.12, 0.12, 0.13)
	environment.fog_density = 0.08 if rec else 0.1
	flashlight.light_energy = 2.0 if rec else 0.8
	flashlight.spot_range = 14.0 if rec else 10.0
	scenes.sync(tape.events, camera.position)
	overlay.show_state(tape)


func on_acted(action: StringName) -> void:
	place_camera(tape.walker.cell, tape.walker.facing)
	if action == &"forward" or action == &"back":
		Sfx.play(self, Sfx.sample("footstep"), -6.0)
	elif action in [&"record", &"rec_start", &"rec_stop"]:
		Sfx.play(self, Sfx.tone(1400.0 if tape.recording else 900.0, 0.08), -12.0)


func _on_event_started(event: FootageEvent) -> void:
	var pan: float = FootageProse.pan(tape.walker, event.cell)
	Sfx.play(self, Sfx.tone(70.0, 1.2, pan, 0.5), -2.0)
	Sfx.play(self, Sfx.sample("static"), -8.0)


func _on_event_captured(_event: FootageEvent) -> void:
	Sfx.play(self, Sfx.tone(2200.0, 0.12), -10.0)
