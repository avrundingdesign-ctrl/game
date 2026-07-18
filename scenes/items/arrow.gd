class_name Arrow
extends Node3D
## Pfeil: fliegt ballistisch, trifft Tribute, bleibt sonst im Boden stecken
## und kann dort wieder aufgesammelt werden (60 % Chance, dass er heil bleibt).

const SPEED := 38.0
const GRAVITY := 9.8
const MAX_LIFETIME := 8.0

var velocity := Vector3.ZERO
var shooter: TributeBase
var damage := 30.0
var _lifetime := 0.0
var _stuck := false

static func shoot(from: Vector3, direction: Vector3, by: TributeBase, base_damage: float) -> Arrow:
	var arrow := Arrow.new()
	arrow.position = from
	arrow.velocity = direction.normalized() * SPEED
	arrow.shooter = by
	arrow.damage = base_damage * (0.8 + float(by.stats.geschick) * 0.04)
	return arrow

func _ready() -> void:
	var mesh := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.015
	shaft.bottom_radius = 0.015
	shaft.height = 0.7
	mesh.mesh = shaft
	mesh.rotation_degrees.x = -90
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.75, 0.7, 0.5)
	mesh.material_override = material
	add_child(mesh)
	if velocity.length() > 0.1:
		look_at(global_position + velocity.normalized(), Vector3.UP)

func _physics_process(delta: float) -> void:
	if _stuck:
		return
	_lifetime += delta
	if _lifetime > MAX_LIFETIME:
		queue_free()
		return

	velocity.y -= GRAVITY * delta
	var motion := velocity * delta
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(global_position, global_position + motion)
	if shooter != null:
		query.exclude = [shooter.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		global_position += motion
		look_at(global_position + velocity.normalized(), Vector3.UP)
		return

	var collider: Object = hit.collider
	if collider is TributeBase and collider.alive:
		collider.take_damage(damage, shooter.tribute_name if shooter != null else "Pfeil")
		if randf() < 0.5:
			collider.bleeding_seconds = maxf(collider.bleeding_seconds, 20.0)
		queue_free()
		return
	if collider is WolfMutt:
		collider.take_damage(damage, shooter.tribute_name if shooter != null else "Pfeil")
		queue_free()
		return

	# Im Boden/Baum steckengeblieben: als Pickup wiederverwertbar
	_stuck = true
	global_position = hit.position
	set_physics_process(false)
	if randf() < 0.6:
		var pickup := LootPickup.create("pfeile", hit.position)
		pickup.item.count = 1
		get_parent().add_child(pickup)
	queue_free()
