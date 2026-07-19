class_name TerrainBuilder
extends StaticBody3D
## Prozedurales Terrain: sanfte Huegel per Noise, flaches Plateau ums Fuellhorn,
## Senken fuer See und Teiche. Vertex-Farben (Gras/Fels/Sand) + Heightmap-Kollision.

const SIZE := 500.0        # Kantenlaenge in Metern
const RESOLUTION := 200    # Quads pro Kante
const PLATEAU_RADIUS := 55.0

var noise := FastNoiseLite.new()
var detail_noise := FastNoiseLite.new()

## Wasserstellen: [Zentrum, Radius] — dort wird das Terrain abgesenkt.
var water_spots: Array = []

func setup(seed_value: int, spots: Array) -> void:
	water_spots = spots
	noise.seed = seed_value
	noise.frequency = 0.008
	noise.fractal_octaves = 3
	detail_noise.seed = seed_value + 1
	detail_noise.frequency = 0.15

func get_height(x: float, z: float) -> float:
	var base: float = noise.get_noise_2d(x, z) * 7.0 + detail_noise.get_noise_2d(x, z) * 0.4
	# Flaches Plateau im Zentrum (Fuellhorn-Ebene), weicher Uebergang
	var center_distance := Vector2(x, z).length()
	var plateau_factor := clampf((center_distance - PLATEAU_RADIUS) / 40.0, 0.0, 1.0)
	var height := base * plateau_factor
	# Wasser-Senken
	for spot in water_spots:
		var spot_distance: float = Vector2(x - spot[0].x, z - spot[0].z).length()
		var spot_radius: float = spot[1]
		if spot_distance < spot_radius + 12.0:
			var depth_factor := 1.0 - clampf((spot_distance - spot_radius) / 12.0, 0.0, 1.0)
			height = lerpf(height, -2.2, depth_factor)
	return height

func build() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := SIZE / RESOLUTION
	var half := SIZE / 2.0

	for zi in RESOLUTION + 1:
		for xi in RESOLUTION + 1:
			var x := -half + xi * step
			var z := -half + zi * step
			var y := get_height(x, z)
			surface.set_color(_vertex_color(x, z, y))
			surface.set_uv(Vector2(x, z) * 0.1)
			surface.add_vertex(Vector3(x, y, z))

	for zi in RESOLUTION:
		for xi in RESOLUTION:
			var i := zi * (RESOLUTION + 1) + xi
			surface.add_index(i)
			surface.add_index(i + RESOLUTION + 1)
			surface.add_index(i + 1)
			surface.add_index(i + 1)
			surface.add_index(i + RESOLUTION + 1)
			surface.add_index(i + RESOLUTION + 2)

	surface.generate_normals()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
	mesh_instance.material_override = material
	add_child(mesh_instance)

	_build_collision()

func _vertex_color(x: float, z: float, y: float) -> Color:
	var grass := Color(0.24, 0.36, 0.16)
	var grass_dry := Color(0.38, 0.38, 0.18)
	var dirt := Color(0.32, 0.26, 0.18)
	var sand := Color(0.62, 0.55, 0.38)
	var rock := Color(0.42, 0.4, 0.38)

	# Sand an Wasserraendern
	for spot in water_spots:
		var spot_distance: float = Vector2(x - spot[0].x, z - spot[0].z).length()
		if spot_distance < spot[1] + 10.0:
			return sand
	# Fels in der Hoehe, Erde im Zentrum, sonst Grasvariation
	if y > 6.0:
		return rock
	var center_distance := Vector2(x, z).length()
	if center_distance < PLATEAU_RADIUS:
		return dirt
	var variation := (detail_noise.get_noise_2d(x * 0.3, z * 0.3) + 1.0) / 2.0
	return grass.lerp(grass_dry, variation * 0.6)

func _build_collision() -> void:
	var shape := HeightMapShape3D.new()
	var samples := RESOLUTION + 1
	shape.map_width = samples
	shape.map_depth = samples
	var data := PackedFloat32Array()
	data.resize(samples * samples)
	var step := SIZE / RESOLUTION
	var half := SIZE / 2.0
	for zi in samples:
		for xi in samples:
			data[zi * samples + xi] = get_height(-half + xi * step, -half + zi * step)
	shape.map_data = data
	var collision := CollisionShape3D.new()
	collision.shape = shape
	# HeightMapShape3D ist um den Ursprung zentriert; Skalierung auf Weltmasse
	collision.scale = Vector3(step, 1.0, step)
	add_child(collision)
