class_name BlindScreens
extends RefCounted
## Paints the cockpit's two low-res screens into Images: the round sonar
## scope (8 returns fading over 2 s) and the camera monitor (a grainy 5x5
## patch, static while it develops, and on the fourth photo an eye).

const SONAR_PX: int = 64
const PHOTO_PX: int = 60
const CELL_PX: int = 12
const SCOPE: float = 29.0
const GREEN: Color = Color(0.35, 1.0, 0.55)


static func blank(px: int) -> Image:
	return Image.create_empty(px, px, false, Image.FORMAT_RGB8)


static func sonar(img: Image, nav: BlindNav) -> void:
	img.fill(Color(0.01, 0.05, 0.03))
	var mid: Vector2 = Vector2(SONAR_PX, SONAR_PX) / 2.0
	for ring: int in range(1, 4):
		_ring(img, mid, SCOPE * ring / 3.0, Color(0.05, 0.22, 0.1))
	var fwd: Vector2 = Vector2(nav.walker.forward_vector())
	for s: int in 6:
		_dot(img, mid + fwd * (4.0 + s), 0, Color(0.9, 0.85, 0.5))
	_dot(img, mid, 1, Color(0.9, 0.85, 0.5))
	if nav.pings == 0 or nav.ping_age >= BlindNav.RETURN_TIME:
		return
	var fade: float = 1.0 - nav.ping_age / BlindNav.RETURN_TIME
	_ring(img, mid, SCOPE * (1.0 - fade), GREEN * (0.25 + 0.5 * fade))
	var per_cell: float = SCOPE / BlindSonar.RANGE
	for i: int in BlindSonar.DIRS8.size():
		var d: Vector2 = Vector2(BlindSonar.DIRS8[i]).normalized()
		var k: int = nav.ping_ranges[i]
		if k > 0:
			_dot(img, mid + d * per_cell * k, 1, GREEN * fade)
		else:
			_dot(img, mid + d * SCOPE, 0, GREEN * (0.3 * fade))


## The developed photo: far row at the top, near row at the bottom.
static func photo(img: Image, nav: BlindNav, noise: RandomNumberGenerator) -> void:
	for y: int in PHOTO_PX:
		for x: int in PHOTO_PX:
			var row: int = floori(float(y) / CELL_PX)
			var cell: Vector2i = nav.photo_cells[
				row * BlindSonar.PATCH + floori(float(x) / CELL_PX)
			]
			var v: float = 0.16 if nav.grid.is_open(cell) else 0.72
			v += noise.randf_range(-0.09, 0.09)
			v *= 1.0 - 0.6 * Vector2(x - 30, y - 30).length() / 42.0
			v *= 0.8 if y % 2 == 0 else 1.0
			img.set_pixel(x, y, Color(v * 0.9, v, v * 0.85))
	if nav.photo_eye:
		_eye(img)


## Snow, for the developing screen and the idle one.
static func snow(img: Image, noise: RandomNumberGenerator, level: float) -> void:
	for y: int in img.get_height():
		for x: int in img.get_width():
			var v: float = noise.randf() * level
			img.set_pixel(x, y, Color(v, v, v))


static func _eye(img: Image) -> void:
	for y: int in range(0, 22):
		for x: int in PHOTO_PX:
			var p: Vector2 = Vector2((x - 30) / 27.0, (y - 9) / 9.0)
			if p.length() > 1.0:
				continue
			var iris: float = Vector2(x - 30, y - 9).length()
			var c: Color = Color(0.7, 0.66, 0.5)
			if iris < 8.0:
				c = Color(0.4, 0.05, 0.02)
			if absi(x - 30) < 2 and iris < 8.5:
				c = Color.BLACK
			img.set_pixel(x, y, c)


static func _ring(img: Image, mid: Vector2, radius: float, color: Color) -> void:
	for s: int in 96:
		var p: Vector2 = mid + Vector2.from_angle(TAU * s / 96.0) * radius
		_dot(img, p, 0, color)


static func _dot(img: Image, p: Vector2, grow: int, color: Color) -> void:
	var at: Vector2i = Vector2i(roundi(p.x), roundi(p.y))
	var rect: Rect2i = Rect2i(at - Vector2i(grow, grow), Vector2i.ONE * (grow * 2 + 1))
	img.fill_rect(rect.intersection(Rect2i(0, 0, img.get_width(), img.get_height())), color)
