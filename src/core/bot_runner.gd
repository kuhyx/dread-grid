class_name BotRunner
extends RefCounted
## Play a concept to the end with its own bot, no view: the winnability check
## the tests run over many seeds. Each beat advances `beat` seconds of game
## time and then applies the bot's action, as a view's autodrive does.


static func play(concept: Concept, beat: float = 0.3, max_beats: int = 20000) -> Concept.Status:
	for _i: int in max_beats:
		if concept.status != Concept.Status.PLAYING:
			break
		concept.advance(beat)
		var action: StringName = concept.bot_action()
		if action != &"" and not concept.perform(action):
			push_warning("bot action %s refused" % action)
	return concept.status
