class_name Hud
extends CanvasLayer
## Status line, a short message log and the end card, drawn over any view.

const LOG_LINES: int = 4

var _status: Label = Label.new()
var _log: Label = Label.new()
var _end: Label = Label.new()
var _lines: Array[String] = []


func _init() -> void:
	layer = 10
	for label: Label in [_status, _log, _end]:
		label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 6)
		add_child(label)
	_status.position = Vector2(16, 12)
	_status.add_theme_font_size_override("font_size", 20)
	_log.position = Vector2(16, 560)
	_log.add_theme_font_size_override("font_size", 20)
	_end.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_end.add_theme_font_size_override("font_size", 44)
	_end.visible = false


func set_status(text: String) -> void:
	_status.text = text


func push(text: String) -> void:
	_lines.append(text)
	if _lines.size() > LOG_LINES:
		_lines.remove_at(0)
	_log.text = "\n".join(PackedStringArray(_lines))


func show_end(won: bool, detail: String) -> void:
	var head: String = "YOU MADE IT OUT" if won else "IT IS OVER"
	_end.text = "%s\n%s\n\nR - again    Esc - menu" % [head, detail]
	_end.visible = true
