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

	_add_particles()

func _add_particles() -> void:
	# Funken
	var sparks := GPUParticles3D.new()
	var spark_mat := ParticleProcessMaterial.new()
	spark_mat.direction = Vector3.UP
	spark_mat.spread = 12.0
	spark_mat.initial_velocity_min = 1.0
	spark_mat.initial_velocity_max = 2.2
	spark_mat.gravity = Vector3(0, 0.5, 0)
	spark_mat.scale_min = 0.04
	spark_mat.scale_max = 0.09
	spark_mat.color = Color(1.0, 0.55, 0.1)
	sparks.process_material = spark_mat
	sparks.amount = 40
	sparks.lifetime = 0.9
	var spark_mesh := SphereMesh.new()
	spark_mesh.radius = 0.5
	spark_mesh.height = 1.0
	var spark_visual := StandardMaterial3D.new()
	spark_visual.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_visual.albedo_color = Color(1.0, 0.6, 0.15)
	spark_visual.emission_enabled = true
	spark_visual.emission = Color(1.0, 0.5, 0.1)
	spark_mesh.material = spark_visual
	sparks.draw_pass_1 = spark_mesh
	sparks.position.y = 0.5
	add_child(sparks)

	# Rauchsaeule — weithin sichtbar (verraet die Position!)
	var smoke := GPUParticles3D.new()
	var smoke_mat := ParticleProcessMaterial.new()
	smoke_mat.direction = Vector3.UP
	smoke_mat.spread = 6.0
	smoke_mat.initial_velocity_min = 1.6
	smoke_mat.initial_velocity_max = 2.4
	smoke_mat.gravity = Vector3(0.3, 0.8, 0)
	smoke_mat.scale_min = 0.5
	smoke_mat.scale_max = 1.4
	smoke_mat.color = Color(0.4, 0.4, 0.4, 0.35)
	smoke.process_material = smoke_mat
	smoke.amount = 24
	smoke.lifetime = 5.0
	var smoke_mesh := SphereMesh.new()
	smoke_mesh.radius = 0.5
	smoke_mesh.height = 1.0
	var smoke_visual := StandardMaterial3D.new()
	smoke_visual.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_visual.albedo_color = Color(0.45, 0.45, 0.45, 0.3)
	smoke_visual.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mesh.material = smoke_visual
	smoke.draw_pass_1 = smoke_mesh
	smoke.position.y = 1.0
	add_child(smoke)

func _process(delta: float) -> void:
	_burn_seconds -= delta
	if _burn_seconds <= 0.0:
		queue_free()
