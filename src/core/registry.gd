class_name Registry
extends RefCounted
## The 5 x 3 grid of games. A game id is "<concept>/<perspective>" and its
## view lives at src/view/<concept>/<concept>_<perspective>.gd.

const CONCEPTS: PackedStringArray = [
	"anomaly", "stalker", "wrong_place", "found_footage", "blind_nav"
]
const PERSPECTIVES: PackedStringArray = ["fps", "topdown", "text"]
const CONCEPT_TITLES: Dictionary = {
	"anomaly": "Anomaly Loop",
	"stalker": "Stalker",
	"wrong_place": "Wrong Place",
	"found_footage": "Found Footage",
	"blind_nav": "Blind Descent",
}
const PERSPECTIVE_TITLES: Dictionary = {
	"fps": "First person",
	"topdown": "Top-down",
	"text": "Text + audio",
}


static func all_games() -> PackedStringArray:
	var out: Array[String] = []
	for concept: String in CONCEPTS:
		for perspective: String in PERSPECTIVES:
			out.append("%s/%s" % [concept, perspective])
	return PackedStringArray(out)


static func is_valid(game: String) -> bool:
	return all_games().has(game)


static func view_path(game: String) -> String:
	var parts: PackedStringArray = game.split("/")
	return "res://src/view/%s/%s_%s.gd" % [parts[0], parts[0], parts[1]]


static func title(game: String) -> String:
	var parts: PackedStringArray = game.split("/")
	return "%s - %s" % [CONCEPT_TITLES[parts[0]], PERSPECTIVE_TITLES[parts[1]]]


## Instantiate the view for `game`, or null if its script is missing.
static func make_view(game: String) -> GameView:
	var path: String = view_path(game)
	if not ResourceLoader.exists(path):
		return null
	var script: GDScript = load(path)
	var instance: Object = script.new()
	return instance as GameView
