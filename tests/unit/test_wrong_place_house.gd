extends GutTest
## Wrong Place's data: the house, its objects and the wrong-variant pool.


func test_every_variant_changes_its_object() -> void:
	for i: int in WrongPlaceCatalog.VARIANTS.size():
		var normal: Array[Prop] = WrongPlaceHouse.props()
		var edited: Array[Prop] = WrongPlaceHouse.props()
		WrongPlaceCatalog.apply(edited, i)
		var target: String = WrongPlaceCatalog.target_of(i)
		var before: Prop = _by_id(normal, target)
		var after: Prop = _by_id(edited, target)
		assert_not_null(after, "variant %d targets a real object" % i)
		assert_ne(_signature(after), _signature(before), "variant %d edits" % i)
		assert_ne(
			WrongPlaceCatalog.describe(after),
			WrongPlaceCatalog.describe(before),
			"variant %d reads differently" % i
		)
		var drawn_before: String = "%s|%s" % [before.color, WrongPlaceCatalog.tag(before)]
		var drawn_after: String = "%s|%s" % [after.color, WrongPlaceCatalog.tag(after)]
		assert_ne(drawn_after, drawn_before, "variant %d shows from above" % i)
		assert_true(WrongPlaceCatalog.COLORS.has(after.color), "variant %d colour known" % i)


func test_pool_is_big_enough() -> void:
	var targets: Dictionary = {}
	for i: int in WrongPlaceCatalog.VARIANTS.size():
		targets[WrongPlaceCatalog.target_of(i)] = true
	assert_gte(WrongPlaceCatalog.VARIANTS.size(), 14)
	assert_gte(targets.size(), WrongPlace.WRONG_COUNT)


func test_every_object_reachable_and_against_one_wall() -> void:
	var game: WrongPlace = WrongPlace.new(1)
	var dist: PackedInt32Array = game.grid.distances(game.walker.cell, game.solid)
	for prop: Prop in game.props:
		var walls: int = 0
		for d: Vector2i in CellGrid.DIRS:
			walls += 0 if game.grid.is_open(prop.cell + d) else 1
		assert_eq(walls, 1, "%s stands against one wall" % prop.id)
		assert_ne(WrongPlaceHouse.room_at(prop.cell), "doorway", prop.id)
		var reachable: bool = false
		for stand: Vector2i in game.stand_cells(prop):
			reachable = reachable or dist[stand.y * game.grid.width + stand.x] >= 0
		assert_true(reachable, "%s reachable" % prop.id)
	var door: Vector2i = game.back_door + Vector2i(0, 1)
	assert_gte(dist[door.y * game.grid.width + door.x], 0, "back door reachable")


func test_every_object_is_described() -> void:
	for prop: Prop in WrongPlaceHouse.props():
		assert_false(WrongPlaceCatalog.describe(prop).begins_with("Something"), prop.kind)
		assert_true(WrongPlaceCatalog.COLORS.has(prop.color), prop.id)


func _by_id(props: Array[Prop], id: String) -> Prop:
	for prop: Prop in props:
		if prop.id == id:
			return prop
	return null


func _signature(p: Prop) -> String:
	return "%s|%s|%s|%s|%s" % [p.id, p.kind, p.color, p.state, p.label]
