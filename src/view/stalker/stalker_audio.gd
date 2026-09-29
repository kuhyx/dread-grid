class_name StalkerAudio
extends RefCounted
## Sound cues the three stalker views share: its footfalls (a low thud,
## louder the nearer it is, panned towards it) and the listen beep.

const EARSHOT: int = 16


## -1 hard left .. 1 hard right, relative to where the player faces, in
## half steps so the tone cache stays small.
static func pan_towards(game: StalkerGame) -> float:
	var offset: Vector2 = Vector2(game.hunter.cell - game.walker.cell)
	if offset == Vector2.ZERO:
		return 0.0
	var ahead: Vector2 = Vector2(game.walker.forward_vector())
	var right: Vector2 = Vector2(-ahead.y, ahead.x)
	return roundf(offset.normalized().dot(right) * 2.0) / 2.0


static func volume(game: StalkerGame) -> float:
	return -4.0 - 2.5 * float(game.stalker_distance())


## One footfall; silent beyond earshot, heavier while it runs.
static func thud(parent: Node, game: StalkerGame) -> void:
	if game.stalker_distance() > EARSHOT:
		return
	var freq: float = 64.0 if game.hunter.hunting else 48.0
	Sfx.play(parent, Sfx.tone(freq, 0.22, pan_towards(game), 0.35), volume(game))


## The listen cue: a beep from the stalker's side, as loud as it is near.
static func beep(parent: Node, game: StalkerGame) -> void:
	Sfx.play(parent, Sfx.tone(700.0, 0.18, pan_towards(game)), volume(game) + 8.0)
