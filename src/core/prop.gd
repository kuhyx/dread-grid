class_name Prop
extends RefCounted
## One placed object, built from a data row so rules and views never embed
## layouts. `segment`/`side` place it along a corridor or at a cell; colour is
## a palette name so the text view can say it and the others can draw it.

var id: String
var kind: String
var cell: Vector2i
var side: int
var color: String
var state: String
var label: String


## Row: [id, kind, x, y_or_side, colour, state, label].
static func from_row(row: Array) -> Prop:
	var prop: Prop = Prop.new()
	prop.id = row[0]
	prop.kind = row[1]
	var x: int = row[2]
	var y: int = row[3]
	prop.cell = Vector2i(x, y)
	prop.side = y
	prop.color = row[4]
	prop.state = row[5]
	prop.label = row[6]
	return prop


## Apply one "set" edit (field name + new value) from a data row.
func apply_edit(field: String, value: String) -> void:
	match field:
		"color":
			color = value
		"state":
			state = value
		"label":
			label = value
		"kind":
			kind = value
