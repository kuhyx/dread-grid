class_name TextView
extends GameView
## Text + audio: a log, a prompt and sound cues. Turn-based - every command
## advances the concept by tick_seconds(). The bot "types" its commands so a
## screenshot of an autodrive run reads like a real session.

var log_box: RichTextLabel = RichTextLabel.new()
var prompt: LineEdit = LineEdit.new()
var status_label: Label = Label.new()


func build() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 40
	box.offset_right = -40
	box.offset_top = 24
	box.offset_bottom = -24
	add_child(box)
	log_box.bbcode_enabled = true
	log_box.scroll_following = true
	log_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.add_theme_font_size_override("normal_font_size", 20)
	log_box.add_theme_color_override("default_color", Color(0.78, 0.76, 0.7))
	box.add_child(log_box)
	status_label.add_theme_color_override("font_color", Color(0.75, 0.2, 0.2))
	box.add_child(status_label)
	prompt.placeholder_text = "type a command - 'help' lists them"
	prompt.add_theme_font_size_override("font_size", 20)
	box.add_child(prompt)
	Wire.link(prompt.text_submitted, _on_submit)
	prompt.call_deferred("grab_focus")
	Sfx.play(self, Sfx.music(concept_id()), -16.0)
	intro()


## Subclass hooks ---------------------------------------------------------------


func concept_id() -> String:
	return ""


func intro() -> void:
	pass


## Words the player can type, each mapped to a concept action.
func words() -> Dictionary:
	return {}


func tick_seconds() -> float:
	return 1.0


## Plumbing -----------------------------------------------------------------------


func is_realtime() -> bool:
	return false


func refresh() -> void:
	status_label.text = concept.hud_line().replace("\n", "   ")


func write(text: String) -> void:
	log_box.append_text(text + "\n")


func act(action: StringName) -> void:
	if options.autodrive:
		write("[color=#777]> %s[/color]" % _word_for(action))
	if concept.perform(action):
		concept.advance(tick_seconds())
		on_acted(action)
	else:
		write("You can't do that now.")


func _on_submit(text: String) -> void:
	prompt.clear()
	var word: String = text.strip_edges().to_lower()
	write("[color=#777]> %s[/color]" % word)
	if word == "help" or word == "?":
		write("Commands: " + ", ".join(PackedStringArray(words().keys())))
	elif word == "quit":
		leave_requested.emit(false)
	elif words().has(word):
		var action: StringName = words()[word]
		if concept.perform(action):
			concept.advance(tick_seconds())
			on_acted(action)
		else:
			write("You can't do that now.")
	else:
		write("Nothing happens. ('help' lists commands)")


func _on_message(text: String) -> void:
	write(text)


func _on_finished(won: bool) -> void:
	write(
		(
			"\n[b]%s[/b]\n%s\n(R - again, Esc - menu)"
			% ["YOU MADE IT OUT" if won else "IT IS OVER", concept.hud_line()]
		)
	)
	prompt.editable = false
	prompt.release_focus()
	game_over.emit(won)


func _word_for(action: StringName) -> String:
	var table: Dictionary = words()
	for word: String in table:
		if table[word] == action:
			return word
	return String(action)
