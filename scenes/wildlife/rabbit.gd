class_name Rabbit
extends CharacterBody3D
## Jagdwild: hoppelt umher, flieht vor Tributen. Erlegt (Pfeil/Nahkampf)
## laesst es rohes Fleisch fallen — am Lagerfeuer braten!

const WANDER_SPEED := 1.6
const FLEE_SPEED := 6.5
const FLEE_RADIUS := 7.0

var health := 10.0
var _move_target := Vector3.ZERO
var _has_target := false
var _think_accumulator := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("wildlife")
	_rng.randomize()

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.18
	capsule.height = 0.5
	shape.shape = capsule
	shape.position.y = 0.25
	add_child(shape)

	var body := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.5
	body.mesh = mesh
	body.position.y = 0.25
	body.rotation_degrees.x = 90
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.45, 0.35).lerp(Color(0.75, 0.7, 0.65), _rng.randf())
	body.material_override = material
	add_child(body)

func take_damage(amount: float, _source: String) -> void:
	health -= amount
	if health <= 0.0:
		var meat := LootPickup.create("rohes_fleisch", global_position)
		get_parent().add_child(meat)
		queue_free()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if GameManager.phase in [GameManager.Phase.COUNTDOWN, GameManager.Phase.GAME_OVER]:
		move_and_slide()
		return

	_think_accumulator += delta
	if _think_accumulator >= 0.4:
		_think_accumulator = 0.0
		_think()

	if _has_target:
		var to_target := _move_target - global_position
		to_target.y = 0
		if to_target.length() < 0.8:
			_has_target = false
		else:
			var fleeing := _nearest_threat() != null
			var speed := FLEE_SPEED if fleeing else WANDER_SPEED
			var direction := to_target.normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, 0.3)
		velocity.z = move_toward(velocity.z, 0, 0.3)
	move_and_slide()

func _think() -> void:
	var threat := _nearest_threat()
	if threat != null:
		var away := (global_position - threat.global_position).normalized()
		_move_target = global_position + away * 15.0
		_has_target = true
	elif not _has_target and _rng.randf() < 0.3:
		_move_target = global_position + Vector3(_rng.randf_range(-8, 8), 0, _rng.randf_range(-8, 8))
		_has_target = true

func _nearest_threat() -> Node3D:
	for node in get_tree().get_nodes_in_group("tributes"):
		var tribute := node as TributeBase
		if tribute.alive and global_position.distance_to(tribute.global_position) < FLEE_RADIUS:
			return tribute
	return null
