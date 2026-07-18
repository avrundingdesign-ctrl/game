class_name LootPickup
extends Area3D
## Aufhebbares Item in der Welt: farbige Box + schwebendes Namensschild.
## KI "beansprucht" ein Pickup (claimed_by), damit nicht alle zum selben rennen.

var item: Dictionary
var claimed_by: Node = null

static func create(item_id: String, at: Vector3) -> LootPickup:
	var pickup := LootPickup.new()
	pickup.item = LootTables.get_item(item_id)
	pickup.position = at + Vector3(0, 0.3, 0)
	return pickup

func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 4
	collision_mask = 0

	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = 0.6
	add_child(shape)

	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.mesh.size = Vector3(0.35, 0.35, 0.35)
	var material := StandardMaterial3D.new()
	material.albedo_color = item.color
	material.emission_enabled = true
	material.emission = item.color * 0.4
	mesh.material_override = material
	add_child(mesh)

	var label := Label3D.new()
	label.text = item.name
	label.position.y = 0.7
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 40
	label.modulate = Color(1, 1, 1, 0.85)
	add_child(label)

## Nimmt das Item auf. Gibt false zurueck, wenn das Inventar voll ist.
func try_take(taker: TributeBase) -> bool:
	if not taker.add_item(item):
		return false
	queue_free()
	return true
