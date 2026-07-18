class_name TrackerJackerNest
extends Node3D
## Jaegerwespen-Nest: haengt an einem Baum. Wer zu nahe kommt, scheucht den
## Schwarm auf — er verfolgt sein Opfer, Stiche vergiften (Halluzinationen, DoT).

const TRIGGER_RADIUS := 3.5
const SWARM_SPEED := 7.5
const SWARM_DURATION := 20.0
const STING_RANGE := 1.5

var _swarm_active := false
var _swarm_position := Vector3.ZERO
var _swarm_target: TributeBase = null
var _swarm_time := 0.0
var _swarm_visual: MeshInstance3D

static func create(at: Vector3) -> TrackerJackerNest:
	var nest := TrackerJackerNest.new()
	nest.position = at
	return nest

func _ready() -> void:
	add_to_group("wasp_nests")
	var nest_mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.55
	nest_mesh.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.45, 0.2)
	nest_mesh.material_override = material
	add_child(nest_mesh)

func _physics_process(delta: float) -> void:
	if not _swarm_active:
		_check_trigger()
		return

	_swarm_time += delta
	if _swarm_time > SWARM_DURATION or _swarm_target == null \
			or not is_instance_valid(_swarm_target) or not _swarm_target.alive:
		_end_swarm()
		return

	var to_target := _swarm_target.global_position + Vector3.UP - _swarm_position
	_swarm_position += to_target.normalized() * SWARM_SPEED * delta
	_swarm_visual.global_position = _swarm_position
	if to_target.length() < STING_RANGE:
		_swarm_target.take_damage(6.0 * delta, "Jaegerwespen")
		_swarm_target.venom_seconds = maxf(_swarm_target.venom_seconds, 15.0)

func _check_trigger() -> void:
	for node in get_tree().get_nodes_in_group("tributes"):
		var tribute := node as TributeBase
		if tribute.alive and global_position.distance_to(tribute.global_position) < TRIGGER_RADIUS:
			_start_swarm(tribute)
			return

func _start_swarm(target: TributeBase) -> void:
	_swarm_active = true
	_swarm_target = target
	_swarm_time = 0.0
	_swarm_position = global_position

	_swarm_visual = MeshInstance3D.new()
	var cloud := SphereMesh.new()
	cloud.radius = 0.8
	cloud.height = 1.2
	_swarm_visual.mesh = cloud
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.65, 0.1, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_swarm_visual.material_override = material
	get_tree().current_scene.add_child(_swarm_visual)
	_swarm_visual.global_position = _swarm_position
	print("[Jaegerwespen] Schwarm aufgescheucht — Ziel: %s" % target.tribute_name)

func _end_swarm() -> void:
	_swarm_active = false
	if _swarm_visual != null and is_instance_valid(_swarm_visual):
		_swarm_visual.queue_free()
	# Nest ist verbraucht
	queue_free()
