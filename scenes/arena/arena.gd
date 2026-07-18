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

var rng := RandomNumberGenerator.new()

@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	GameManager.reset()
	rng.randomize()
	_build_lake()
	_build_forest()
	_spawn_pedestals_and_tributes()
	_spawn_bloodbath_loot()
	print("[Arena] Aufbau fertig: %d Tribute, %d Pickups, Seed %d" % [
		get_tree().get_nodes_in_group("tributes").size(),
		get_tree().get_nodes_in_group("pickups").size(),
		rng.seed])

func _physics_process(_delta: float) -> void:
	# Arenagrenze: unsichtbares Kraftfeld
	for node in get_tree().get_nodes_in_group("tributes"):
		var tribute := node as TributeBase
		var flat := Vector2(tribute.global_position.x, tribute.global_position.z)
		if flat.length() > ARENA_RADIUS:
			flat = flat.normalized() * ARENA_RADIUS
			tribute.global_position.x = flat.x
			tribute.global_position.z = flat.y

# --- Aufbau -----------------------------------------------------------------

func _spawn_pedestals_and_tributes() -> void:
	var file := FileAccess.open("res://data/tributes.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	var tributes: Array = data.tributes
	GameManager.register_tributes(tributes.size())

	var player_index := -1
	for i in tributes.size():
		if tributes[i].profil == "spieler":
			player_index = i

	for i in tributes.size():
		var angle := TAU * i / tributes.size()
		var spawn := Vector3(cos(angle) * PEDESTAL_RING_RADIUS, 0.0, sin(angle) * PEDESTAL_RING_RADIUS)
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
		tribute.global_position = spawn + Vector3(0, 0.3, 0)
		# Blick zum Fuellhorn
		tribute.look_at(Vector3(0, tribute.global_position.y, 0), Vector3.UP)

		if is_player:
			hud.bind_player(tribute)
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
		var pickup := LootPickup.create(spawn.id, spawn.position)
		add_child(pickup)

func _build_lake() -> void:
	var lake := Node3D.new()
	lake.name = "Lake"
	lake.position = LAKE_CENTER
	lake.add_to_group("lake")
	lake.set_meta("radius", LAKE_RADIUS)
	add_child(lake)

	var surface := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = LAKE_RADIUS
	mesh.bottom_radius = LAKE_RADIUS
	mesh.height = 0.1
	surface.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.15, 0.35, 0.6, 0.85)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.1
	material.metallic = 0.3
	surface.material_override = material
	surface.position.y = 0.05
	lake.add_child(surface)

func _build_forest() -> void:
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.3
	trunk_mesh.height = 4.0
	var trunk_material := StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.35, 0.25, 0.15)

	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = 0.0
	crown_mesh.bottom_radius = 1.8
	crown_mesh.height = 4.5
	var crown_material := StandardMaterial3D.new()
	crown_material.albedo_color = Color(0.15, 0.35, 0.15)

	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.3
	trunk_shape.height = 4.0

	for i in TREE_COUNT:
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(60.0, ARENA_RADIUS - 10.0)
		var at := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		if at.distance_to(LAKE_CENTER) < LAKE_RADIUS + 8.0:
			continue

		var tree := StaticBody3D.new()
		tree.position = at

		var trunk := MeshInstance3D.new()
		trunk.mesh = trunk_mesh
		trunk.material_override = trunk_material
		trunk.position.y = 2.0
		tree.add_child(trunk)

		var crown := MeshInstance3D.new()
		crown.mesh = crown_mesh
		crown.material_override = crown_material
		crown.position.y = 5.5
		tree.add_child(crown)

		var collision := CollisionShape3D.new()
		collision.shape = trunk_shape
		collision.position.y = 2.0
		tree.add_child(collision)

		add_child(tree)
