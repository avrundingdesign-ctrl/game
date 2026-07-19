class_name TributeBody
extends Node3D
## Prozeduraler Humanoid statt Kapsel: Kopf, Torso, Arme, Beine.
## Beine/Arme schwingen beim Gehen (Geschwindigkeit vom CharacterBody-Parent).

const SKIN_TONES := [
	Color(0.87, 0.72, 0.58), Color(0.76, 0.57, 0.42),
	Color(0.55, 0.38, 0.26), Color(0.93, 0.79, 0.67),
]

var _torso: MeshInstance3D
var _head: MeshInstance3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _outfit_material := StandardMaterial3D.new()
var _skin_material := StandardMaterial3D.new()
var _phase := 0.0

func _ready() -> void:
	_outfit_material.albedo_color = Color(0.4, 0.4, 0.45)
	_outfit_material.albedo_texture = load("res://assets/textures/Fabric030/Fabric030_1K-PNG_Color.png")
	_outfit_material.normal_enabled = true
	_outfit_material.normal_texture = load("res://assets/textures/Fabric030/Fabric030_1K-PNG_NormalGL.png")
	_outfit_material.uv1_scale = Vector3(2.5, 2.5, 1.0)
	_outfit_material.roughness = 0.95
	_skin_material.albedo_color = SKIN_TONES[randi() % SKIN_TONES.size()]
	_skin_material.roughness = 0.7

	# Beine: Pivot an der Huefte (y 0.78)
	_left_leg = _make_limb(Vector3(-0.11, 0.78, 0), 0.78, 0.085, _outfit_material)
	_right_leg = _make_limb(Vector3(0.11, 0.78, 0), 0.78, 0.085, _outfit_material)

	# Torso
	_torso = MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.19
	torso_mesh.height = 0.75
	_torso.mesh = torso_mesh
	_torso.material_override = _outfit_material
	_torso.position.y = 1.12
	add_child(_torso)

	# Arme: Pivot an der Schulter (y 1.42)
	_left_arm = _make_limb(Vector3(-0.27, 1.42, 0), 0.68, 0.06, _outfit_material)
	_right_arm = _make_limb(Vector3(0.27, 1.42, 0), 0.68, 0.06, _outfit_material)

	# Kopf
	_head = MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.13
	head_mesh.height = 0.26
	_head.mesh = head_mesh
	_head.material_override = _skin_material
	_head.position.y = 1.66
	add_child(_head)

func _make_limb(at: Vector3, length: float, radius: float, material: StandardMaterial3D) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = at
	var mesh_instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = length
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position.y = -length / 2.0
	pivot.add_child(mesh_instance)
	add_child(pivot)
	return pivot

func set_outfit(color: Color) -> void:
	_outfit_material.albedo_color = color

func _process(delta: float) -> void:
	var parent := get_parent()
	if parent is not CharacterBody3D:
		return
	var speed: float = Vector2(parent.velocity.x, parent.velocity.z).length()
	if speed > 0.3:
		_phase += delta * speed * 2.4
		var swing := sin(_phase) * 0.65 * clampf(speed / 6.0, 0.45, 1.0)
		_left_leg.rotation.x = swing
		_right_leg.rotation.x = -swing
		_left_arm.rotation.x = -swing * 0.8
		_right_arm.rotation.x = swing * 0.8
	else:
		_left_leg.rotation.x = lerpf(_left_leg.rotation.x, 0.0, 10.0 * delta)
		_right_leg.rotation.x = lerpf(_right_leg.rotation.x, 0.0, 10.0 * delta)
		_left_arm.rotation.x = lerpf(_left_arm.rotation.x, 0.0, 10.0 * delta)
		_right_arm.rotation.x = lerpf(_right_arm.rotation.x, 0.0, 10.0 * delta)
