class_name AnomalyCatalog
extends RefCounted
## The corridor's normal props and the ten ways it can be wrong, as data.
## Every view renders props generically from these rows, so an anomaly is a
## row here, never code in a view. Row: [id, kind, segment, side, colour,
## state, label]; side -1 is the left wall walking out, 1 the right, 0 middle.

const LENGTH: int = 8
const LAYOUT: Array = [
	["light_a", "light", 1, 0, "white", "on", ""],
	["poster", "poster", 2, -1, "yellow", "", "SAFETY FIRST"],
	["door_a", "door", 3, 1, "grey", "closed", ""],
	["extinguisher", "extinguisher", 4, -1, "red", "", ""],
	["light_b", "light", 4, 0, "white", "on", ""],
	["clock", "clock", 5, 1, "white", "", "12:00"],
	["bench", "bench", 6, -1, "brown", "", ""],
	["light_c", "light", 7, 0, "white", "on", ""],
	["exit_sign", "sign", 7, 0, "green", "", "EXIT ->"],
]
## [id, op, target, field, value]; "add" carries a whole LAYOUT row as target.
const ANOMALIES: Array = [
	["poster_eyes", "set", "poster", "label", "IT SEES YOU"],
	["red_light", "set", "light_b", "color", "red"],
	["extra_door", "add", ["door_x", "door", 5, -1, "grey", "closed", ""], "", ""],
	["missing_extinguisher", "remove", "extinguisher", "", ""],
	["watcher", "add", ["watcher", "figure", 6, 1, "black", "", ""], "", ""],
	["mirrored_sign", "set", "exit_sign", "label", "<- TIXE"],
	["dark_light", "set", "light_a", "state", "off"],
	["blood", "add", ["blood", "stain", 3, 0, "red", "", ""], "", ""],
	["open_door", "set", "door_a", "state", "open"],
	["clock_13", "set", "clock", "label", "13:00"],
]
const COLORS: Dictionary = {
	"white": Color(0.9, 0.88, 0.8),
	"red": Color(0.75, 0.05, 0.05),
	"yellow": Color(0.85, 0.75, 0.2),
	"grey": Color(0.45, 0.45, 0.47),
	"green": Color(0.2, 0.75, 0.3),
	"brown": Color(0.4, 0.25, 0.12),
	"black": Color(0.02, 0.02, 0.02),
}


## The corridor's props for one loop: LAYOUT with anomaly `index` applied
## (-1 = a normal loop). A prop's cell.x is its segment, `side` its wall.
static func props_for(index: int) -> Array[Prop]:
	var props: Array[Prop] = []
	for row: Array in LAYOUT:
		props.append(Prop.from_row(row))
	if index < 0:
		return props
	var anomaly: Array = ANOMALIES[index]
	var op: String = anomaly[1]
	if op == "add":
		var row: Array = anomaly[2]
		props.append(Prop.from_row(row))
	elif op == "remove":
		var gone: String = anomaly[2]
		props = props.filter(func(p: Prop) -> bool: return p.id != gone)
	else:
		var target: String = anomaly[2]
		var field: String = anomaly[3]
		var value: String = anomaly[4]
		for p: Prop in props:
			if p.id == target:
				p.apply_edit(field, value)
	return props


static func color_of(prop: Prop) -> Color:
	return COLORS[prop.color]


## One sentence per prop for the text view; `flip` swaps left and right
## when the player walks back towards the start.
static func describe(prop: Prop, flip: bool) -> String:
	var side_value: int = prop.side * (-1 if flip else 1)
	var side: String = "left" if side_value < 0 else "right"
	var color: String = prop.color
	match prop.kind:
		"light":
			return (
				"A %s ceiling light %s." % [color, "hums" if prop.state == "on" else "hangs dead"]
			)
		"poster":
			return 'A %s poster on the %s wall reads "%s".' % [color, side, prop.label]
		"door":
			return "A %s door on the %s, %s." % [color, side, prop.state]
		"extinguisher":
			return "A %s fire extinguisher hangs on the %s wall." % [color, side]
		"clock":
			return "A clock on the %s wall shows %s." % [side, prop.label]
		"bench":
			return "A %s bench stands against the %s wall." % [color, side]
		"sign":
			return 'A %s sign above the far door: "%s".' % [color, prop.label]
		"figure":
			return "A man in a black suit stands by the %s wall. He is watching you." % side
		"stain":
			return "A wet %s stain spreads across the floor." % color
	return "Something you cannot name."
