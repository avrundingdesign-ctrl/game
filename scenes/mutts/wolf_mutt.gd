class_name WolfMutt
extends CharacterBody3D
## Wolfsmutt der Spielmacher (Finale): jagt den naechsten Tribut und treibt
## alle zum Fuellhorn. Traegt die Distriktnummer eines gefallenen Tributs.

const SPEED := 6.8
const BITE_DAMAGE := 22.0
const BITE_RANGE := 1.8
const BITE_COOLDOWN := 1.5

var district := 0
var health := 60.0
var _bite_cooldown := 0.0
var _target: TributeBase = null
var _retarget_timer := 0.0

static func create(at: Vector3, dead_district: int) -> WolfMutt:
	var mutt := WolfMutt.new()
	mutt.position = at
	mutt.district = dead_district
	return mutt

func _ready() -> void:
	add_to_group("mutts")

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.2
	shape.shape = capsule
	shape.position.y = 0.6
	add_child(shape)

	var mesh := MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.4
	body.height = 1.2
	mesh.mesh = body
	mesh.position.y = 0.6
	mesh.rotation_degrees.x = 90
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.1, 0.1)
	mesh.material_override = material
	add_child(mesh)

	var tag := Label3D.new()
	tag.text = "MUTT D%d" % district
	tag.position.y = 1.6
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size = 32
	tag.modulate = Color(1.0, 0.3, 0.3, 0.9)
	add_child(tag)

func take_damage(amount: float, _source: String) -> void:
	health -= amount
	if health <= 0.0:
		print("[Mutt] Wolfsmutt D%d erlegt" % district)
		queue_free()

func _physics_process(delta: float) -> void:
	if GameManager.phase == GameManager.Phase.GAME_OVER:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	_bite_cooldown = maxf(0.0, _bite_cooldown - delta)

	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or _target == null or not is_instance_valid(_target) or not _target.alive:
		_retarget_timer = 1.0
		_target = _nearest_tribute()
	if _target == null:
		move_and_slide()
		return

	var to_target := _target.global_position - global_position
	to_target.y = 0
	var distance := to_target.length()
	if distance < BITE_RANGE:
		if _bite_cooldown <= 0.0:
			_bite_cooldown = BITE_COOLDOWN
			_target.take_damage(BITE_DAMAGE, "Wolfsmutt")
			if randf() < 0.5:
				_target.bleeding_seconds = maxf(_target.bleeding_seconds, 15.0)
		velocity.x = 0
		velocity.z = 0
	else:
		var direction := to_target.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_at(global_position + direction, Vector3.UP)
	move_and_slide()

func _nearest_tribute() -> TributeBase:
	var best: TributeBase = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("tributes"):
		var tribute := node as TributeBase
		if not tribute.alive:
			continue
		var distance := global_position.distance_to(tribute.global_position)
		if distance < best_distance:
			best_distance = distance
			best = tribute
	return best
