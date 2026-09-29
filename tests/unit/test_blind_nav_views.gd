extends GutTest
## The three Blind Descent views on real nodes: a collision (backing off the
## south edge at the start is always rock), a ping and a photo each run
## their view code path without errors.


func _start(game: String) -> GameView:
	var view: GameView = Registry.make_view(game)
	add_child_autofree(view)
	view.start(LaunchOptions.new())
	return view


func test_every_view_survives_a_crash_a_ping_and_a_photo() -> void:
	for perspective: String in Registry.PERSPECTIVES:
		var view: GameView = _start("blind_nav/" + perspective)
		var nav: BlindNav = view.concept as BlindNav
		view.act(&"back")
		assert_eq(nav.hull, BlindNav.MAX_HULL - BlindNav.CRASH_DAMAGE, perspective)
		view.act(&"ping")
		view.act(&"photo")
		await wait_process_frames(5)
		assert_eq(nav.pings, 1, perspective)
		assert_eq(nav.photos, 1, perspective)


func test_the_text_view_develops_a_photo_in_one_command() -> void:
	var view: GameView = _start("blind_nav/text")
	var nav: BlindNav = view.concept as BlindNav
	view.act(&"photo")
	assert_false(nav.locked())
	assert_true(nav.photo_showing())
