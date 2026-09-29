class_name GameView
extends Node
## One playable (concept x perspective). Subclasses build the scene and map
## keys to actions; autodrive feeds the concept's bot actions through the
## same `act()`, so a green autodrive run exercises the real code path.

signal game_over(won: bool)
signal leave_requested(restart: bool)

const BOT_BEAT: float = 0.3
const MOVE_KEYS: Dictionary = {
	KEY_W: &"forward",
	KEY_UP: &"forward",
	KEY_S: &"back",
	KEY_DOWN: &"back",
	KEY_A: &"turn_left",
	KEY_LEFT: &"turn_left",
	KEY_D: &"turn_right",
	KEY_RIGHT: &"turn_right",
}

var concept: Concept
var options: LaunchOptions
var hud: Hud
var _beat: float = 0.0


func start(opts: LaunchOptions) -> void:
	options = opts
	concept = make_concept(opts.seed_value)
	Wire.link(concept.message, _on_message)
	Wire.link(concept.finished, _on_finished)
	build()
	refresh()


## Subclass hooks ----------------------------------------------------------


func make_concept(seed_value: int) -> Concept:
	return Concept.new(seed_value)


func build() -> void:
	pass


## Sync the visuals to the concept's state; called every frame.
func refresh() -> void:
	if hud != null:
		hud.set_status(concept.hud_line())


func is_realtime() -> bool:
	return true


## True while an animation runs: input and the bot wait for it.
func busy() -> bool:
	return false


func extra_keys() -> Dictionary:
	return {}


func on_acted(_action: StringName) -> void:
	pass


## Shared plumbing ---------------------------------------------------------


func act(action: StringName) -> void:
	if concept.perform(action):
		on_acted(action)


func _process(delta: float) -> void:
	if concept == null or concept.status != Concept.Status.PLAYING:
		return
	if is_realtime():
		concept.advance(delta)
	if options.autodrive and not busy():
		_beat += delta
		if _beat >= BOT_BEAT:
			_beat = 0.0
			var action: StringName = concept.bot_action()
			if action != &"":
				act(action)
	refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed:
		return
	if (
		key.keycode == KEY_ESCAPE
		or (key.keycode == KEY_R and concept.status != Concept.Status.PLAYING)
	):
		leave_requested.emit(key.keycode == KEY_R)
		return
	if options.autodrive or busy() or concept.status != Concept.Status.PLAYING:
		return
	var keys: Dictionary = MOVE_KEYS.merged(extra_keys())
	if keys.has(key.keycode) and (not key.echo or MOVE_KEYS.has(key.keycode)):
		var action: StringName = keys[key.keycode]
		act(action)


func _on_message(text: String) -> void:
	if hud != null:
		hud.push(text)


func _on_finished(won: bool) -> void:
	if hud != null:
		hud.show_end(won, concept.hud_line())
	game_over.emit(won)
