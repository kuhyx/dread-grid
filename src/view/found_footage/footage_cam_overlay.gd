class_name FootageCamOverlay
extends CanvasLayer
## The camcorder's burnt-in display over any Found Footage view: a blinking
## REC dot (or STBY), the tape timecode and a battery bar. With `night` it
## also lays the camera's eye (footage_cam.gdshader) over the picture - the
## green night vision while recording. Sits under the Hud (layer 10).

const CAM: Shader = preload("res://src/view/found_footage/footage_cam.gdshader")
const CORNER: Vector2 = Vector2(1080, 18)
const BAR: Vector2 = Vector2(150, 14)
const RED: Color = Color(0.95, 0.12, 0.1)
const PALE: Color = Color(0.88, 0.9, 0.85)

var _eye: ColorRect = ColorRect.new()
var _eye_material: ShaderMaterial = ShaderMaterial.new()
var _dot: ColorRect = ColorRect.new()
var _mode: Label = Label.new()
var _clock: Label = Label.new()
var _bar_frame: ColorRect = ColorRect.new()
var _bar: ColorRect = ColorRect.new()


func _init(night: bool) -> void:
	layer = 5
	if night:
		_eye_material.shader = CAM
		_eye.material = _eye_material
		_eye.set_anchors_preset(Control.PRESET_FULL_RECT)
		_eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_eye)
	_dot.color = RED
	_dot.size = Vector2(16, 16)
	_dot.position = CORNER + Vector2(0, 6)
	_mode.position = CORNER + Vector2(24, -2)
	_clock.position = CORNER + Vector2(0, 24)
	_bar_frame.color = Color(0.1, 0.1, 0.1, 0.8)
	_bar_frame.position = CORNER + Vector2(-2, 58)
	_bar_frame.size = BAR + Vector2(4, 4)
	_bar.position = CORNER + Vector2(0, 60)
	for label: Label in [_mode, _clock]:
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 6)
	_clock.add_theme_color_override("font_color", PALE)
	for node: Control in [_dot, _mode, _clock, _bar_frame, _bar]:
		add_child(node)


func show_state(tape: FoundFootage) -> void:
	var rec: bool = tape.recording
	_dot.visible = rec and fposmod(tape.elapsed, 1.0) < 0.6
	_mode.text = "REC" if rec else "STBY"
	_mode.add_theme_color_override("font_color", RED if rec else PALE)
	_clock.text = tape.timecode()
	var level: float = tape.battery / 100.0
	_bar.size = Vector2(BAR.x * level, BAR.y)
	_bar.color = RED if level < 0.2 else PALE
	_eye_material.set_shader_parameter("recording", 1.0 if rec else 0.0)
