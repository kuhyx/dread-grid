class_name WrongPlaceCatalog
extends RefCounted
## The ways the house can be wrong, and how every object reads in prose. A
## wrong variant is one "set" edit of one object (the Prop row approach of
## AnomalyCatalog), so views render wrongness generically from the fields.

## [id, target object, field, value, what you feel when you flag it].
const VARIANTS: Array = [
	["photo_you", "photo", "label", "MUM DAD ANNA YOU", "The fourth face in the photo is yours."],
	["clock_13", "clock", "label", "13:00", "The clock ticks once, loudly, and stops."],
	["plant_dead", "plant", "color", "black", "The black leaves crumble at your touch."],
	["window_hands", "window", "state", "handprints", "The handprints are still warm."],
	["tv_face", "tv", "state", "face", "The face in the static turns to follow you."],
	[
		"portrait_scratched",
		"portrait",
		"state",
		"scratched",
		"Flakes of paint are under your nails."
	],
	[
		"books_help",
		"bookshelf",
		"label",
		"HELP ME HELP ME",
		"Something behind the books knocks back."
	],
	["lamp_red", "lamp", "color", "red", "The red light pulses, like a heartbeat."],
	["chair_ceiling", "chair", "state", "ceiling", "The chair creaks overhead. It does not fall."],
	["table_knife", "table", "state", "knife", "The knife is still vibrating."],
	["fridge_open", "fridge", "state", "open", "The dripping stops the moment you look."],
	["bath_red", "bathtub", "color", "red", "The red water ripples. Nothing touched it."],
	["mirror_empty", "mirror", "state", "empty", "Your reflection is still not there."],
	["mirror_figure", "mirror", "state", "figure", "You do not turn around. You know better."],
	["bed_blood", "bed", "color", "darkred", "The sheets are warm and wet."],
	["painting_upside", "painting", "state", "upside_down", "The painted house is upside down."],
	["crib_rocking", "crib", "state", "rocking", "The crib stops rocking. Something small sighs."],
	["doll_wall", "doll", "state", "facing_wall", "The doll whispers: you found me."],
]
const COLORS: Dictionary = {
	"brown": Color(0.36, 0.22, 0.12),
	"cream": Color(0.85, 0.8, 0.66),
	"green": Color(0.25, 0.55, 0.22),
	"grey": Color(0.35, 0.35, 0.37),
	"blue": Color(0.2, 0.35, 0.6),
	"yellow": Color(0.95, 0.78, 0.4),
	"white": Color(0.88, 0.87, 0.82),
	"pink": Color(0.85, 0.55, 0.6),
	"red": Color(0.8, 0.06, 0.05),
	"darkred": Color(0.38, 0.02, 0.02),
	"black": Color(0.04, 0.04, 0.04),
}
const COLOR_WORDS: Dictionary = {"darkred": "soaked dark red", "black": "black and curled"}
## The object itself; {color} and {label} come from the Prop.
const NOUNS: Dictionary = {
	"photo": 'A family photo in a {color} frame, captioned "{label}".',
	"clock": "A {color} wall clock. Its hands say {label}.",
	"plant": "A potted plant, its leaves {color}.",
	"tv": "An old {color} television set.",
	"bookshelf": 'A {color} bookshelf. The spines read "{label}".',
	"lamp": "A standing lamp glowing {color}.",
	"portrait": 'An oil portrait of an old woman. The plate says "{label}".',
	"window": "A window onto the dark garden.",
	"bed": "A double bed. The sheets are {color}.",
	"painting": 'A painting of a little house, titled "{label}".',
	"bathtub": "A bathtub, full to the brim with {color} water.",
	"mirror": "A mirror over the sink.",
	"crib": "A {color} wooden crib.",
	"doll": "A porcelain doll in a {color} dress.",
	"fridge": "A {color} fridge.",
	"table": "A {color} kitchen table.",
	"chair": "A {color} kitchen chair.",
}
## The object's state, as "kind:state".
const PHRASES: Dictionary = {
	"tv:off": "Its screen is dark.",
	"tv:face": "It hisses static. A face presses out of the snow.",
	"portrait:smiling": "She smiles kindly.",
	"portrait:scratched": "Her face has been scratched out, down to the canvas.",
	"window:clean": "The glass is clean.",
	"window:handprints": "Small handprints cover the glass. On the inside.",
	"painting:upright": "A yellow sun hangs over it.",
	"painting:upside_down": "It hangs upside down. The sun is under the grass.",
	"mirror:clear": "It shows you, and the doorway behind you.",
	"mirror:empty": "It shows the doorway behind you. It does not show you.",
	"mirror:figure": "It shows you. Someone tall stands right behind you.",
	"crib:still": "It stands still.",
	"crib:rocking": "It is rocking gently. Nobody is touching it.",
	"doll:facing_room": "It sits facing you, glass eyes shining.",
	"doll:facing_wall": "It sits with its face pressed to the wall.",
	"fridge:closed": "It hums quietly.",
	"fridge:open": "Its door hangs open. Something dark drips off the bottom shelf.",
	"table:set": "Three plates are laid for dinner.",
	"table:knife": "A carving knife stands upright, driven deep into the wood.",
	"chair:floor": "It is tucked in neatly.",
	"chair:ceiling": "It is on the ceiling, legs up, perfectly still.",
}


static func color_of(prop: Prop) -> Color:
	return COLORS[prop.color]


static func color_word(color_name: String) -> String:
	return COLOR_WORDS.get(color_name, color_name)


## One sentence or two for the text view and `look`; every field a variant
## can edit shows up in it, so a wrong object always reads differently.
static func describe(prop: Prop) -> String:
	var noun: String = NOUNS.get(prop.kind, "Something you cannot name.")
	var text: String = noun.format({"color": color_word(prop.color), "label": prop.label})
	var phrase: String = PHRASES.get("%s:%s" % [prop.kind, prop.state], "")
	return text if phrase == "" else "%s %s" % [text, phrase]


## Short map lines for the top-down view: the kind, then its state and any
## label that can change (a wrong colour shows as the glyph's colour).
static func tag_lines(prop: Prop) -> Array[String]:
	var parts: Array[String] = [prop.kind.to_upper()]
	if PHRASES.has("%s:%s" % [prop.kind, prop.state]):
		parts.append(prop.state.replace("_", " "))
	if prop.label != "" and prop.kind in ["clock", "photo", "bookshelf"]:
		parts.append(prop.label)
	return parts


static func tag(prop: Prop) -> String:
	return " ".join(PackedStringArray(tag_lines(prop)))


## Apply variant `index` to the matching prop in `props`.
static func apply(props: Array[Prop], index: int) -> void:
	var row: Array = VARIANTS[index]
	var target: String = row[1]
	var field: String = row[2]
	var value: String = row[3]
	for prop: Prop in props:
		if prop.id == target:
			prop.apply_edit(field, value)


static func target_of(index: int) -> String:
	var row: Array = VARIANTS[index]
	var target: String = row[1]
	return target


static func confirmation(index: int) -> String:
	var row: Array = VARIANTS[index]
	var text: String = row[4]
	return text
