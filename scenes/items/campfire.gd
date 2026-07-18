class_name Campfire
extends Node3D
## Lagerfeuer: waermt (kein Kaelteschaden nachts), brennt ~3 Arena-Stunden.
## Der Feuerschein verraet die Position an KI-Tribute in der Naehe.

var _burn_seconds := 0.0

func _ready() -> void:
	add_to_group("campfires")
	_burn_seconds = 3.0 / 24.0 * DayNight.day_length_seconds

	var logs := MeshInstance3D.new()
	var log_mesh := CylinderMesh.new()
	log_mesh.top_radius = 0.35
	log_mesh.bottom_radius = 0.45
	log_mesh.height = 0.3
	logs.mesh = log_mesh
	var log_material := StandardMaterial3D.new()
	log_material.albedo_color = Color(0.3, 0.2, 0.1)
	logs.material_override = log_material
	logs.position.y = 0.15
	add_child(logs)

	var flame := MeshInstance3D.new()
	var flame_mesh := CylinderMesh.new()
	flame_mesh.top_radius = 0.0
	flame_mesh.bottom_radius = 0.25
	flame_mesh.height = 0.6
	flame.mesh = flame_mesh
	var flame_material := StandardMaterial3D.new()
	flame_material.albedo_color = Color(1.0, 0.55, 0.1)
	flame_material.emission_enabled = true
	flame_material.emission = Color(1.0, 0.45, 0.05)
	flame_material.emission_energy_multiplier = 2.0
	flame.material_override = flame_material
	flame.position.y = 0.6
	add_child(flame)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.25)
	light.light_energy = 2.5
	light.omni_range = 9.0
	light.position.y = 1.0
	add_child(light)

func _process(delta: float) -> void:
	_burn_seconds -= delta
	if _burn_seconds <= 0.0:
		queue_free()
