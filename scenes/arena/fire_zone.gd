class_name FireZone
extends Node3D
## Waldbrand-Zone: waechst vom Startpunkt, verletzt Tribute darin und
## treibt die KI Richtung Arena-Zentrum (Spielmacher-Treiber).

const DAMAGE_PER_SECOND := 6.0
const GROW_SPEED := 4.0     # Meter pro Sekunde
const MAX_RADIUS := 90.0

var radius := 15.0
var _visual: MeshInstance3D
var _embers: GPUParticles3D
var _burn_time := 0.0
var _max_burn_seconds := 0.0

static func create(at: Vector3) -> FireZone:
	var zone := FireZone.new()
	zone.position = at
	return zone

func _ready() -> void:
	add_to_group("firezones")
	_max_burn_seconds = 3.0 / 24.0 * DayNight.day_length_seconds

	_visual = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 12.0
	_visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.35, 0.05, 0.35)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(1.0, 0.4, 0.0)
	material.emission_energy_multiplier = 1.5
	_visual.material_override = material
	_visual.position.y = 6.0
	add_child(_visual)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.45, 0.1)
	light.light_energy = 4.0
	light.omni_range = 40.0
	light.position.y = 8.0
	add_child(light)

	# Glut und Aschesaeule
	_embers = GPUParticles3D.new()
	var ember_material := ParticleProcessMaterial.new()
	ember_material.direction = Vector3.UP
	ember_material.spread = 25.0
	ember_material.initial_velocity_min = 3.0
	ember_material.initial_velocity_max = 8.0
	ember_material.gravity = Vector3(0.5, 2.0, 0)
	ember_material.scale_min = 0.1
	ember_material.scale_max = 0.35
	ember_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	ember_material.emission_sphere_radius = radius
	ember_material.color = Color(1.0, 0.45, 0.05)
	_embers.process_material = ember_material
	_embers.amount = 300
	_embers.lifetime = 2.5
	var ember_mesh := SphereMesh.new()
	ember_mesh.radius = 0.5
	ember_mesh.height = 1.0
	var ember_visual := StandardMaterial3D.new()
	ember_visual.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ember_visual.albedo_color = Color(1.0, 0.5, 0.05)
	ember_visual.emission_enabled = true
	ember_visual.emission = Color(1.0, 0.4, 0.0)
	ember_mesh.material = ember_visual
	_embers.draw_pass_1 = ember_mesh
	_embers.position.y = 2.0
	add_child(_embers)

func _process(delta: float) -> void:
	_burn_time += delta
	if _burn_time >= _max_burn_seconds:
		queue_free()
		return
	radius = minf(MAX_RADIUS, radius + GROW_SPEED * delta)
	_visual.scale = Vector3(radius, 1.0, radius)
	if _embers != null:
		(_embers.process_material as ParticleProcessMaterial).emission_sphere_radius = radius

	for node in get_tree().get_nodes_in_group("tributes"):
		var tribute := node as TributeBase
		if not tribute.alive:
			continue
		if Vector2(tribute.global_position.x - global_position.x,
				tribute.global_position.z - global_position.z).length() < radius:
			tribute.take_damage(DAMAGE_PER_SECOND * delta, "Feuer")
