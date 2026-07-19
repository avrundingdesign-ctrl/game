extends SceneTree
## Werkzeug: generiert die Nadelzweig-Karte (RGBA, 512x512) fuer Branch-Card-Baeume.
## Aufruf: godot --headless --script res://tools/generate_branch_texture.gd

const SIZE := 512

var img: Image

func _init() -> void:
	img = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 74

	# Hauptstiel: leicht gebogen von links nach rechts
	var stem_points: Array[Vector2] = []
	for i in 40:
		var t := float(i) / 39.0
		stem_points.append(Vector2(20.0 + t * 470.0, 256.0 + sin(t * PI) * -18.0))
	for i in stem_points.size() - 1:
		_line(stem_points[i], stem_points[i + 1], Color(0.32, 0.22, 0.12, 1.0), 3)

	# Fiederzweige mit Nadelbuescheln entlang des Stiels
	for i in range(2, stem_points.size() - 1, 2):
		var t := float(i) / 39.0
		var base := stem_points[i]
		for side: float in [-1.0, 1.0]:
			var twig_len := lerpf(85.0, 18.0, t) * rng.randf_range(0.75, 1.15)
			var tip := base + Vector2(twig_len * 0.45, side * twig_len * 0.85)
			_line(base, tip, Color(0.3, 0.21, 0.12, 1.0), 2)
			_needles_along(base, tip, rng, lerpf(1.0, 0.55, t))
	# Nadeln an der Spitze des Hauptstiels
	_needles_along(stem_points[30], stem_points[39], rng, 0.7)

	# Leichte Weichzeichnung gegen harte Pixellinien (runter- und wieder hochskalieren)
	img.resize(384, 384, Image.INTERPOLATE_BILINEAR)
	img.resize(512, 512, Image.INTERPOLATE_BILINEAR)

	var dir := DirAccess.open("res://assets/textures")
	if not dir.dir_exists("generated"):
		dir.make_dir("generated")
	img.save_png("res://assets/textures/generated/branch_card.png")
	print("[Tool] branch_card.png geschrieben")
	quit()

## Nadelbueschel beidseitig entlang einer Zweigachse.
## Zwei Paesse: dunkler Schatten-Layer, dann Nadeln mit Basis->Spitze-Verlauf.
func _needles_along(from: Vector2, to: Vector2, rng: RandomNumberGenerator, density: float) -> void:
	var axis := to - from
	var length := axis.length()
	var direction := axis / maxf(length, 0.001)
	var normal := Vector2(-direction.y, direction.x)
	var count := int(length * 2.6 * density)
	# Schatten-Pass (Tiefenwirkung)
	for i in count:
		var t := rng.randf()
		var base := from + axis * t
		for side: float in [-1.0, 1.0]:
			var needle_len := rng.randf_range(8.0, 17.0) * lerpf(1.0, 0.6, t)
			var sweep := direction * needle_len * 0.55 + normal * side * needle_len
			_line(base + Vector2(1, 2), base + sweep + Vector2(1, 2), Color(0.03, 0.1, 0.04, 0.85), 3)
	# Nadel-Pass mit Verlauf
	for i in count:
		var t := rng.randf()
		var base := from + axis * t
		var green := Color(
			rng.randf_range(0.09, 0.2),
			rng.randf_range(0.32, 0.55),
			rng.randf_range(0.1, 0.24), 1.0)
		for side: float in [-1.0, 1.0]:
			var needle_len := rng.randf_range(8.0, 17.0) * lerpf(1.0, 0.6, t)
			var sweep := direction * needle_len * 0.55 + normal * side * needle_len
			var mid := base + sweep * 0.55
			_line(base, mid, green.darkened(0.25), 2)
			var tip_color := green.lightened(0.2)
			tip_color.a = 0.9
			_line(mid, base + sweep, tip_color, 2)

## Simple dicke Linie per Schrittzeichnung
func _line(from: Vector2, to: Vector2, color: Color, thickness: int) -> void:
	var steps := int(from.distance_to(to)) + 1
	for i in steps:
		var p := from.lerp(to, float(i) / steps)
		for ox in thickness:
			for oy in thickness:
				var x := int(p.x) + ox - thickness / 2
				var y := int(p.y) + oy - thickness / 2
				if x >= 0 and x < SIZE and y >= 0 and y < SIZE:
					img.set_pixel(x, y, color)
