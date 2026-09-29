extends GutTest


func test_defaults() -> void:
	var o: LaunchOptions = LaunchOptions.parse([])
	assert_eq(o.game, "")
	assert_eq(o.seed_value, 1)
	assert_false(o.autodrive)


func test_every_flag() -> void:
	var o: LaunchOptions = (
		LaunchOptions
		. parse(
			[
				"--game=stalker/fps",
				"--seed=9",
				"--autodrive",
				"--quit-on-finish",
				"--speed=4",
				"--screenshot=/x/y.png",
				"--screenshot-at=2.5",
				"--timeout=30",
			]
		)
	)
	assert_eq(o.game, "stalker/fps")
	assert_eq(o.seed_value, 9)
	assert_true(o.autodrive and o.quit_on_finish)
	assert_eq(o.speed, 4.0)
	assert_eq(o.screenshot_path, "/x/y.png")
	assert_eq(o.screenshot_at, 2.5)
	assert_eq(o.timeout, 30.0)


func test_registry_lists_fifteen_games_with_views() -> void:
	var games: PackedStringArray = Registry.all_games()
	assert_eq(games.size(), 15)
	for game: String in games:
		assert_true(ResourceLoader.exists(Registry.view_path(game)), "%s has a view" % game)
	assert_false(Registry.is_valid("anomaly/vr"))
