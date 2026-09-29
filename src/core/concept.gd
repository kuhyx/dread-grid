class_name Concept
extends RefCounted
## The rules of one horror concept, independent of how it is drawn. A
## perspective view renders it and feeds it actions; the concept's bot feeds
## it the same actions, so an autodrive win exercises the real rules.

signal message(text: String)
signal finished(won: bool)

enum Status { PLAYING, WON, LOST }

var status: Status = Status.PLAYING
var elapsed: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(seed_value: int) -> void:
	rng.seed = seed_value


## Advance game time. Real-time views call this every frame; the text view
## calls it with a fixed slice per command.
func advance(delta: float) -> void:
	if status != Status.PLAYING:
		return
	elapsed += delta
	_on_advance(delta)


## Apply one named action (the shared vocabulary of input, text and bot).
## Returns false when the action is unknown or not possible right now.
func perform(action: StringName) -> bool:
	if status != Status.PLAYING:
		return false
	return _on_perform(action)


## One status line for a HUD or the text prompt.
func hud_line() -> String:
	return ""


## The actions a player may take, for help text and input mapping.
func actions() -> Array[StringName]:
	return []


## The bot's next action, or &"" to wait this beat.
func bot_action() -> StringName:
	return &""


func _on_advance(_delta: float) -> void:
	pass


func _on_perform(_action: StringName) -> bool:
	return false


func _say(text: String) -> void:
	message.emit(text)


func _finish(won: bool) -> void:
	if status != Status.PLAYING:
		return
	status = Status.WON if won else Status.LOST
	finished.emit(won)
