extends Node
## Entry point: the launcher, or straight into one game with --game=. Owns
## the automation plumbing: screenshot, timeout and exit code.

var options: LaunchOptions
var _view: GameView
var _launcher: Launcher
var _game: String = ""
var _seed_offset: int = 0
var _shot_done: bool = false


func _ready() -> void:
	options = LaunchOptions.parse(OS.get_cmdline_user_args())
	Engine.time_scale = options.speed if options.autodrive else 1.0
	if options.game == "":
		_show_launcher()
	elif Registry.is_valid(options.game):
		_open(options.game)
	else:
		printerr("unknown --game=%s; one of %s" % [options.game, Registry.all_games()])
		get_tree().quit(3)


func _process(_delta: float) -> void:
	if options.screenshot_path != "" and not _shot_done:
		if Time.get_ticks_msec() / 1000.0 >= options.screenshot_at:
			_shot_done = true
			await RenderingServer.frame_post_draw
			var err: Error = get_viewport().get_texture().get_image().save_png(
				options.screenshot_path
			)
			print("SCREENSHOT %s err=%d" % [options.screenshot_path, err])
			if not options.quit_on_finish:
				get_tree().quit(0 if err == OK else 4)
	if _view != null and _view.concept.elapsed > options.timeout:
		print("RESULT game=%s timeout after %.0fs" % [_game, _view.concept.elapsed])
		get_tree().quit(2)


func _show_launcher() -> void:
	_close_view()
	_launcher = Launcher.new()
	add_child(_launcher)
	Wire.link(_launcher.chosen, _open)


func _open(game: String) -> void:
	if _launcher != null:
		_launcher.queue_free()
		_launcher = null
	_close_view()
	_game = game
	_view = Registry.make_view(game)
	if _view == null:
		printerr("view for %s is not built yet" % game)
		get_tree().quit(3)
		return
	add_child(_view)
	Wire.link(_view.game_over, _on_game_over)
	Wire.link(_view.leave_requested, _on_leave)
	var run: LaunchOptions = LaunchOptions.parse(OS.get_cmdline_user_args())
	run.seed_value = options.seed_value + _seed_offset
	_view.start(run)
	print("START game=%s seed=%d" % [game, run.seed_value])


func _close_view() -> void:
	if _view != null:
		_view.queue_free()
		_view = null


func _on_game_over(won: bool) -> void:
	var line: String = _view.concept.hud_line().replace("\n", " | ")
	print("RESULT game=%s won=%s time=%.1fs %s" % [_game, won, _view.concept.elapsed, line])
	if options.quit_on_finish:
		get_tree().quit(0 if won else 1)


func _on_leave(restart: bool) -> void:
	if restart:
		_seed_offset += 1
		_open(_game)
	elif options.game == "":
		_show_launcher()
	else:
		get_tree().quit(0)
