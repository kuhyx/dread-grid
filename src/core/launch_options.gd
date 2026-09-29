class_name LaunchOptions
extends RefCounted
## Command-line flags after `--`. Parsed from a plain string array so the
## parser is testable without an OS.
##   --game=<concept>/<perspective>  skip the launcher (see Registry)
##   --seed=N                        world seed (default 1)
##   --autodrive                     the concept's bot plays
##   --quit-on-finish                exit 0 on a win, 1 on a loss
##   --speed=N                       Engine.time_scale for autodrive runs
##   --screenshot=PATH               save one frame as PNG (needs a display);
##                                   quits after it unless --quit-on-finish
##   --screenshot-at=SECONDS         when to take it (real time, default 3)
##   --timeout=SECONDS               game-time limit, exit 2 (default 900)

var game: String = ""
var seed_value: int = 1
var autodrive: bool = false
var quit_on_finish: bool = false
var speed: float = 1.0
var screenshot_path: String = ""
var screenshot_at: float = 3.0
var timeout: float = 900.0


static func parse(args: PackedStringArray) -> LaunchOptions:
	var options: LaunchOptions = LaunchOptions.new()
	for arg: String in args:
		options.apply(arg)
	return options


func apply(arg: String) -> void:
	if arg == "--autodrive":
		autodrive = true
	elif arg == "--quit-on-finish":
		quit_on_finish = true
	elif arg.begins_with("--game="):
		game = _value(arg)
	elif arg.begins_with("--seed="):
		seed_value = _value(arg).to_int()
	elif arg.begins_with("--speed="):
		speed = clampf(_value(arg).to_float(), 0.1, 64.0)
	elif arg.begins_with("--screenshot="):
		screenshot_path = _value(arg)
	elif arg.begins_with("--screenshot-at="):
		screenshot_at = _value(arg).to_float()
	elif arg.begins_with("--timeout="):
		timeout = _value(arg).to_float()


static func _value(arg: String) -> String:
	return arg.substr(arg.find("=") + 1)
