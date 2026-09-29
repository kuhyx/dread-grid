extends FpsView
## Blind Descent, first person: you sit in the cockpit and never see the
## trench. The camera is fixed; moving the sub changes only the instruments.
## A collision flashes the alarm lamp and shakes the room.

const SEAT: Vector3 = Vector3(0, 1.2, 0.55)
const SCREEN_HZ: float = 12.0
const ALARM_TIME: float = 1.6

var nav: BlindNav
var cockpit: BlindCockpit = BlindCockpit.new()
var _noise: RandomNumberGenerator = RandomNumberGenerator.new()
var _shake: float = 0.0
var _alarm: float = 0.0
var _repaint: float = 0.0
var _seen_crashes: int = 0
var _painted_photo: int = -1


func make_concept(seed_value: int) -> Concept:
	nav = BlindNav.new(seed_value)
	return nav


func concept_id() -> String:
	return "blind_nav"


func extra_keys() -> Dictionary:
	return {KEY_SPACE: &"ping", KEY_F: &"photo"}


func build_world() -> void:
	environment.fog_density = 0.03
	environment.ambient_light_color = Color(0.2, 0.19, 0.18)
	flashlight.visible = false
	camera.position = SEAT
	camera.rotation = Vector3(-0.08, 0.0, 0.0)
	cockpit.build(kit)
	world.add_child(cockpit)
	hud.push("No window. Space pings the sonar, F takes a photo (3 s to develop).")
	hud.push("Log all four waypoints by their coordinates. Mind the hull.")


func on_acted(action: StringName) -> void:
	if nav.crashes > _seen_crashes:
		_seen_crashes = nav.crashes
		_shake = 1.0
		_alarm = ALARM_TIME
		Sfx.play(self, Sfx.sample("crunch"), -2.0)
		Sfx.play(self, Sfx.tone(55.0, 0.8, 0.0, 0.8), -4.0)
	elif action == &"ping":
		Sfx.play(self, Sfx.tone(880.0, 0.6), -8.0)
	elif action == &"photo":
		Sfx.play(self, Sfx.tone(140.0, 0.5, 0.0, 0.7), -12.0)
	elif action in [&"forward", &"back"]:
		Sfx.play(self, Sfx.tone(70.0, 0.3, 0.0, 0.5), -18.0)


func _process(delta: float) -> void:
	super(delta)
	_shake = maxf(0.0, _shake - delta * 1.8)
	_alarm = maxf(0.0, _alarm - delta)
	var wobble: Vector3 = Vector3(_noise.randf_range(-1, 1), _noise.randf_range(-1, 1), 0)
	camera.position = SEAT + wobble * 0.04 * _shake
	camera.rotation.z = _noise.randf_range(-1, 1) * 0.025 * _shake
	cockpit.set_alarm((_alarm > 0.0 and fmod(_alarm, 0.4) > 0.2) or nav.hull <= 25)
	_repaint -= delta
	if _repaint <= 0.0:
		_repaint = 1.0 / SCREEN_HZ
		_paint_screens()


func refresh() -> void:
	super.refresh()
	var c: Vector2i = nav.walker.cell
	cockpit.coords.text = (
		"X %02d\nY %02d\nHDG %s" % [c.x, c.y, BlindNav.HEADINGS[nav.walker.facing]]
	)
	cockpit.set_hull(nav.hull)
	var text: String = ""
	for i: int in nav.waypoints.size():
		var w: Vector2i = nav.waypoints[i]
		var mark: String = "x" if nav.visited[i] else " "
		text += "\n" if i == 2 else ("   " if i > 0 else "")
		text += "%s %02d,%02d [%s]" % [BlindTrench.LABELS[i], w.x, w.y, mark]
	cockpit.waypoint_label.text = text


func _paint_screens() -> void:
	BlindScreens.sonar(cockpit.sonar_img, nav)
	cockpit.sonar_tex.update(cockpit.sonar_img)
	if nav.locked():
		cockpit.photo_caption.text = "DEVELOPING"
		BlindScreens.snow(cockpit.photo_img, _noise, 0.35)
		cockpit.photo_tex.update(cockpit.photo_img)
		_painted_photo = -1
	elif nav.photo_showing():
		cockpit.photo_caption.text = ""
		if _painted_photo != nav.photos:
			_painted_photo = nav.photos
			BlindScreens.photo(cockpit.photo_img, nav, _noise)
			cockpit.photo_tex.update(cockpit.photo_img)
	elif _painted_photo != 0:
		_painted_photo = 0
		cockpit.photo_caption.text = "NO IMAGE"
		BlindScreens.snow(cockpit.photo_img, _noise, 0.06)
		cockpit.photo_tex.update(cockpit.photo_img)
