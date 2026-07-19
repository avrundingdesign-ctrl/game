extends Node3D
## Baut die Graybox-Arena auf: Startplatten, Loot-Ringe, See, Wald,
## spawnt Spieler + 23 KI-Tribute und haelt alle innerhalb der Arenagrenze.

const PEDESTAL_RING_RADIUS := 22.0
const ARENA_RADIUS := 235.0
const LAKE_CENTER := Vector3(130, 0, 90)
const LAKE_RADIUS := 25.0
const TREE_COUNT := 250

const AI_SCENE := preload("res://scenes/tribute/ai_tribute.tscn")
const PLAYER_SCENE := preload("res://scenes/tribute/player.tscn")

const PROFILE_COLORS := {
	"karriero": Color(0.75, 0.2, 0.2),
	"kaempfer": Color(0.8, 0.5, 0.2),
	"opportunist": Color(0.75, 0.7, 0.2),
	"techniker": Color(0.5, 0.35, 0.7),
	"ueberlebende": Color(0.25, 0.6, 0.3),
}

const POND_CENTERS := [Vector3(-140, 0, -60), Vector3(60, 0, -150)]
const POND_RADIUS := 8.0
const WATER_LEVEL := -1.1

var rng := RandomNumberGenerator.new()
var terrain: TerrainBuilder
var _tree_positions: Array[Vector3] = []
var _rain: GPUParticles3D
var _bark_material: StandardMaterial3D
var _needle_material: StandardMaterial3D
var _orbit_camera: Camera3D
var _orbit_angle := 0.0

@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	GameManager.reset()
	Gamemaker.reset()
	SponsorSystem.reset()
	rng.randomize()
	_gild_cornucopia()
	_build_terrain()
	_build_lake()
	_build_ponds()
	_build_forest()
	_build_berry_bushes()
	_spawn_pedestals_and_tributes()
	_spawn_bloodbath_loot()
	Gamemaker.feast_started.connect(_on_feast_started)
	Gamemaker.ponds_dried.connect(_on_ponds_dried)
	Gamemaker.wildfire_started.connect(_on_wildfire_started)
	Gamemaker.mutts_released.connect(_on_mutts_released)
	_build_rain()
	if OS.get_environment("PANEM_CAMERA") == "1":
		_orbit_camera = Camera3D.new()
		_orbit_camera.fov = 60
		add_child(_orbit_camera)
		_orbit_camera.make_current()
	WeatherSystem.weather_changed.connect(func(w: int) -> void:
		_rain.emitting = w == WeatherSystem.Weather.REGEN)
	print("[Arena] Aufbau fertig: %d Tribute, %d Pickups, Seed %d" % [
		get_tree().get_nodes_in_group("tributes").size(),
		get_tree().get_nodes_in_group("pickups").size(),
		rng.seed])

func _physics_process(_delta: float) -> void:
	# Kino-Orbit (PANEM_CAMERA=1): langsame Kreisfahrt ueber der Arena
	if _orbit_camera != null:
		_orbit_angle += 0.1 * _delta
		var camera_position := Vector3(cos(_orbit_angle) * 55.0, 14.0, sin(_orbit_angle) * 55.0)
		camera_position.y = ground_y(camera_position.x, camera_position.z) + 12.0
		_orbit_camera.global_position = camera_position
		_orbit_camera.look_at(Vector3(0, 6, 0), Vector3.UP)

	# Regen folgt dem Spieler
	if _rain != null and _rain.emitting:
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player != null:
			_rain.global_position = player.global_position + Vector3(0, 18, 0)

	# Arenagrenze: unsichtbares Kraftfeld
	for node in get_tree().get_nodes_in_group("tributes"):
		var tribute := node as TributeBase
		var flat := Vector2(tribute.global_position.x, tribute.global_position.z)
		if flat.length() > ARENA_RADIUS:
			flat = flat.normalized() * ARENA_RADIUS
			tribute.global_position.x = flat.x
			tribute.global_position.z = flat.y

# --- Aufbau -----------------------------------------------------------------

func _build_rain() -> void:
	_rain = GPUParticles3D.new()
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3.DOWN
	material.spread = 3.0
	material.initial_velocity_min = 16.0
	material.initial_velocity_max = 22.0
	material.gravity = Vector3(0, -22, 0)
	material.scale_min = 0.6
	material.scale_max = 1.0
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(35, 1, 35)
	material.color = Color(0.65, 0.75, 0.85, 0.45)
	_rain.process_material = material
	_rain.amount = 1400
	_rain.lifetime = 1.3
	var drop := QuadMesh.new()
	drop.size = Vector2(0.02, 0.4)
	var drop_material := StandardMaterial3D.new()
	drop_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_material.albedo_color = Color(0.65, 0.75, 0.85, 0.4)
	drop_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	drop.material = drop_material
	_rain.draw_pass_1 = drop
	_rain.emitting = false
	add_child(_rain)

## Fuellhorn: echtes Goldmetall (Metal032, gold getoent)
func _gild_cornucopia() -> void:
	var horn := $Cornucopia as MeshInstance3D
	var material := StandardMaterial3D.new()
	material.albedo_texture = load("res://assets/textures/Metal032/Metal032_1K-JPG_Color.jpg")
	material.albedo_color = Color(1.0, 0.8, 0.4)
	material.metallic = 1.0
	material.metallic_texture = load("res://assets/textures/Metal032/Metal032_1K-JPG_Metalness.jpg")
	material.roughness = 1.0
	material.roughness_texture = load("res://assets/textures/Metal032/Metal032_1K-JPG_Roughness.jpg")
	material.normal_enabled = true
	material.normal_texture = load("res://assets/textures/Metal032/Metal032_1K-JPG_NormalGL.jpg")
	material.uv1_scale = Vector3(3.0, 2.0, 1.0)
	horn.material_override = material

func _build_terrain() -> void:
	terrain = TerrainBuilder.new()
	var spots := [[LAKE_CENTER, LAKE_RADIUS]]
	for center in POND_CENTERS:
		spots.append([center, POND_RADIUS])
	terrain.setup(int(rng.seed), spots)
	terrain.build()
	add_child(terrain)

## Gelaendehoehe an Position (fuer alle Spawns).
func ground_y(x: float, z: float) -> float:
	return terrain.get_height(x, z)

func _spawn_pedestals_and_tributes() -> void:
	var file := FileAccess.open("res://data/tributes.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	var tributes: Array = data.tributes
	GameManager.register_tributes(tributes.size())
	hud.show_roster(tributes)

	var player_index := -1
	for i in tributes.size():
		if tributes[i].profil == "spieler":
			player_index = i

	for i in tributes.size():
		var angle := TAU * i / tributes.size()
		var spawn := Vector3(cos(angle) * PEDESTAL_RING_RADIUS, 0.0, sin(angle) * PEDESTAL_RING_RADIUS)
		spawn.y = ground_y(spawn.x, spawn.z)
		_build_pedestal(spawn)

		var profile: Dictionary = tributes[i]
		var is_player := i == player_index and not GameManager.observer_mode
		var tribute: TributeBase
		if is_player:
			tribute = PLAYER_SCENE.instantiate()
		else:
			tribute = AI_SCENE.instantiate()
			tribute.profil = profile.profil if profile.profil != "spieler" else "kaempfer"
		add_child(tribute)
		tribute.tribute_name = profile.name
		tribute.district = profile.district
		tribute.stats = profile.stats
		tribute.global_position = spawn + Vector3(0, 0.5, 0)
		# Blick zum Fuellhorn
		tribute.look_at(Vector3(0, tribute.global_position.y, 0), Vector3.UP)

		if is_player:
			hud.bind_player(tribute)
			SponsorSystem.bind_player(tribute)
		else:
			_color_ai(tribute)

func _color_ai(tribute: TributeBase) -> void:
	var mesh: MeshInstance3D = tribute.get_node("Mesh")
	var material := StandardMaterial3D.new()
	material.albedo_color = PROFILE_COLORS.get(tribute.profil, Color.GRAY)
	mesh.material_override = material
	var tag: Label3D = tribute.get_node("NameTag")
	tag.text = "%s (D%d)" % [tribute.tribute_name, tribute.district]

func _build_pedestal(at: Vector3) -> void:
	var pedestal := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.75
	mesh.bottom_radius = 0.75
	mesh.height = 0.25
	pedestal.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.45, 0.5)
	material.metallic = 0.6
	pedestal.material_override = material
	pedestal.position = at + Vector3(0, 0.125, 0)
	add_child(pedestal)

func _spawn_bloodbath_loot() -> void:
	for spawn in LootTables.roll_bloodbath_loot(rng):
		var at: Vector3 = spawn.position
		at.y = ground_y(at.x, at.z)
		add_child(LootPickup.create(spawn.id, at))

func _build_lake() -> void:
	add_child(_make_water_body("Lake", LAKE_CENTER, LAKE_RADIUS, ["lake"]))

## Kleine Teiche: trocknen im Endgame zuerst aus (Phase 3)
func _build_ponds() -> void:
	for center in POND_CENTERS:
		add_child(_make_water_body("Pond", center, POND_RADIUS, ["lake", "ponds"]))

func _make_water_body(body_name: String, center: Vector3, radius: float, groups: Array) -> Node3D:
	var body := Node3D.new()
	body.name = body_name
	body.position = Vector3(center.x, 0, center.z)
	for group in groups:
		body.add_to_group(group)
	body.set_meta("radius", radius)

	var surface := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(radius * 2.4, radius * 2.4)
	mesh.subdivide_width = 24
	mesh.subdivide_depth = 24
	surface.mesh = mesh
	surface.material_override = _water_material()
	surface.position.y = WATER_LEVEL
	body.add_child(surface)
	return body

func _water_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/water.gdshader")
	return material

func _build_berry_bushes() -> void:
	for i in 60:
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(60.0, 220.0)
		var at := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if _is_near_water(at, 5.0):
			continue
		at.y = ground_y(at.x, at.z)
		add_child(BerryBush.create(at, rng.randf() < 0.15))

func _is_near_water(at: Vector3, margin: float) -> bool:
	if Vector2(at.x - LAKE_CENTER.x, at.z - LAKE_CENTER.z).length() < LAKE_RADIUS + margin:
		return true
	for center in POND_CENTERS:
		if Vector2(at.x - center.x, at.z - center.z).length() < POND_RADIUS + margin:
			return true
	return false

func _build_forest() -> void:
	# Rinde (Bark012) fuer Staemme, getoentes Triplanar-Gras als Nadelstruktur
	_bark_material = StandardMaterial3D.new()
	_bark_material.albedo_texture = load("res://assets/textures/Bark012/Bark012_1K-JPG_Color.jpg")
	_bark_material.normal_enabled = true
	_bark_material.normal_texture = load("res://assets/textures/Bark012/Bark012_1K-JPG_NormalGL.jpg")
	_bark_material.uv1_scale = Vector3(2.0, 2.0, 1.0)
	_bark_material.roughness = 0.95

	_needle_material = StandardMaterial3D.new()
	_needle_material.albedo_texture = load("res://assets/textures/Grass001/Grass001_1K-JPG_Color.jpg")
	_needle_material.uv1_triplanar = true
	_needle_material.uv1_scale = Vector3(1.6, 1.6, 1.6)
	_needle_material.roughness = 1.0

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.32
	trunk_mesh.height = 4.0

	var crown_meshes: Array[CylinderMesh] = []
	for size in [[2.0, 2.6], [1.55, 2.2], [1.05, 1.9]]:
		var crown := CylinderMesh.new()
		crown.top_radius = 0.0
		crown.bottom_radius = size[0]
		crown.height = size[1]
		crown_meshes.append(crown)

	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.3
	trunk_shape.height = 4.0

	for i in TREE_COUNT:
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(60.0, ARENA_RADIUS - 10.0)
		var at := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if _is_near_water(at, 8.0):
			continue
		at.y = ground_y(at.x, at.z)

		var tree := StaticBody3D.new()
		tree.position = at
		tree.rotation.y = rng.randf() * TAU
		var tree_scale := rng.randf_range(0.8, 1.5)
		tree.scale = Vector3.ONE * tree_scale

		var trunk := MeshInstance3D.new()
		trunk.mesh = trunk_mesh
		trunk.material_override = _bark_material
		trunk.position.y = 2.0
		tree.add_child(trunk)

		# Krone aus 3 gestapelten Kegeln, Nadel-Struktur per Triplanar-Gras
		var crown_material := _needle_material.duplicate()
		crown_material.albedo_color = Color(0.28, 0.5, 0.28).lerp(Color(0.5, 0.75, 0.4), rng.randf())
		var crown_y := 4.2
		for crown_mesh in crown_meshes:
			var crown := MeshInstance3D.new()
			crown.mesh = crown_mesh
			crown.material_override = crown_material
			crown.position.y = crown_y
			tree.add_child(crown)
			crown_y += crown_mesh.height * 0.55

		var collision := CollisionShape3D.new()
		collision.shape = trunk_shape
		collision.position.y = 2.0
		tree.add_child(collision)

		add_child(tree)
		_tree_positions.append(at + Vector3(0, 0, 0))

	_spawn_wasp_nests()
	_build_grass()
	_build_boulders()
	_spawn_wildlife()

## Verstreute Felsbrocken (rein dekorativ)
func _build_boulders() -> void:
	var rock_material := StandardMaterial3D.new()
	rock_material.albedo_texture = load("res://assets/textures/Rock030/Rock030_1K-JPG_Color.jpg")
	rock_material.normal_enabled = true
	rock_material.normal_texture = load("res://assets/textures/Rock030/Rock030_1K-JPG_NormalGL.jpg")
	rock_material.uv1_triplanar = true
	rock_material.uv1_scale = Vector3(0.5, 0.5, 0.5)
	rock_material.roughness = 0.9

	for i in 45:
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(55.0, ARENA_RADIUS - 8.0)
		var at := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if _is_near_water(at, 4.0):
			continue
		var boulder := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 1.6
		boulder.mesh = mesh
		boulder.material_override = rock_material
		var boulder_scale := rng.randf_range(0.5, 2.6)
		boulder.scale = Vector3(boulder_scale, boulder_scale * rng.randf_range(0.5, 0.8), boulder_scale * rng.randf_range(0.7, 1.2))
		boulder.rotation.y = rng.randf() * TAU
		boulder.position = Vector3(at.x, ground_y(at.x, at.z) - 0.3 * boulder_scale, at.z)
		add_child(boulder)

## Kaninchen im Wald — Jagdbeute (rohes Fleisch, am Feuer braten)
func _spawn_wildlife() -> void:
	for i in 18:
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(70.0, 210.0)
		var at := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if _is_near_water(at, 3.0):
			continue
		var rabbit := Rabbit.new()
		rabbit.position = Vector3(at.x, ground_y(at.x, at.z) + 0.3, at.z)
		add_child(rabbit)

## Grasbueschel als MultiMesh (gekreuzte Quads mit Wind-Shader)
func _build_grass() -> void:
	var blade := QuadMesh.new()
	blade.size = Vector2(0.5, 0.6)
	blade.center_offset = Vector3(0, 0.3, 0)
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/grass.gdshader")
	material.set_shader_parameter("blade_texture",
		load("res://assets/textures/Grass001/Grass001_1K-JPG_Color.jpg"))
	blade.material = material

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = blade
	multimesh.instance_count = 9000

	var placed := 0
	var attempts := 0
	while placed < multimesh.instance_count and attempts < multimesh.instance_count * 3:
		attempts += 1
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(58.0, ARENA_RADIUS - 5.0)
		var at := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if _is_near_water(at, 2.0):
			continue
		at.y = ground_y(at.x, at.z) + 0.02
		var transform := Transform3D(Basis(Vector3.UP, rng.randf() * TAU), at)
		multimesh.set_instance_transform(placed, transform)
		placed += 1
	multimesh.visible_instance_count = placed

	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)

## Jaegerwespen-Nester an zufaelligen Baeumen
func _spawn_wasp_nests() -> void:
	for i in 4:
		if _tree_positions.is_empty():
			return
		var at: Vector3 = _tree_positions[rng.randi() % _tree_positions.size()]
		add_child(TrackerJackerNest.create(at + Vector3(0.4, 3.2, 0)))

# --- Gamemaker-Events -------------------------------------------------------

func _on_feast_started(_position: Vector3) -> void:
	var feast_pool := ["medikit", "medikit", "schwert", "trockenfleisch", "wasserflasche", "pfeile", "verband", "brot"]
	for i in feast_pool.size():
		var angle := TAU * i / feast_pool.size()
		var at := Vector3(cos(angle) * 6.0, 0.0, sin(angle) * 6.0)
		at.y = ground_y(at.x, at.z)
		var pickup := LootPickup.create(feast_pool[i], at)
		pickup.item["name"] = "%s (Fest)" % pickup.item.name
		add_child(pickup)

func _on_ponds_dried() -> void:
	for pond in get_tree().get_nodes_in_group("ponds"):
		pond.queue_free()

func _on_wildfire_started(center: Vector3) -> void:
	add_child(FireZone.create(center))

func _on_mutts_released() -> void:
	var fallen := GameManager.all_fallen_districts
	var count := mini(5, maxi(3, fallen.size()))
	for i in count:
		var district: int = fallen[i % maxi(1, fallen.size())] if not fallen.is_empty() else 0
		var angle := rng.randf() * TAU
		var at := Vector3(cos(angle), 0, sin(angle)) * 200.0
		at.y = ground_y(at.x, at.z) + 0.5
		add_child(WolfMutt.create(at, district))
