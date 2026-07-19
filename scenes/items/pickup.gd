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

	_build_prop()

	var label := Label3D.new()
	label.text = item.name
	label.position.y = 0.7
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 40
	label.modulate = Color(1, 1, 1, 0.85)
	add_child(label)

func _process(delta: float) -> void:
	rotate_y(0.8 * delta)

# --- Erkennbare Item-Modelle statt Wuerfel ---------------------------------

var _steel: StandardMaterial3D
var _wood: StandardMaterial3D

func _build_prop() -> void:
	_steel = StandardMaterial3D.new()
	_steel.albedo_color = Color(0.75, 0.77, 0.8)
	_steel.metallic = 0.9
	_steel.roughness = 0.3
	_wood = StandardMaterial3D.new()
	_wood.albedo_color = Color(0.4, 0.28, 0.16)
	_wood.roughness = 0.9

	match item.get("id", ""):
		"schwert":
			_blade(0.75, 0.07)
		"messer", "kleines_messer":
			_blade(0.4, 0.05)
		"wurfmesser":
			for i in 3:
				var knife := _blade(0.3, 0.04)
				knife.position.x = -0.08 + i * 0.08
				knife.rotation.z = -0.2 + i * 0.2
		"speer":
			_part(CylinderMesh.new(), _wood, Vector3(0, 0.55, 0), Vector3(0.03, 1.1, 0.03))
			var spear_tip := CylinderMesh.new()
			spear_tip.top_radius = 0.0
			spear_tip.bottom_radius = 0.05
			_part(spear_tip, _steel, Vector3(0, 1.2, 0), Vector3(1, 0.22, 1))
		"axt":
			_part(CylinderMesh.new(), _wood, Vector3(0, 0.4, 0), Vector3(0.035, 0.8, 0.035))
			_part(BoxMesh.new(), _steel, Vector3(0.13, 0.7, 0), Vector3(0.26, 0.18, 0.05))
		"bogen":
			var bow := TorusMesh.new()
			bow.inner_radius = 0.34
			bow.outer_radius = 0.4
			_part(bow, _wood, Vector3(0, 0.4, 0), Vector3(1, 1, 0.3))
		"pfeile":
			_part(CylinderMesh.new(), _wood, Vector3(0, 0.25, 0), Vector3(0.09, 0.5, 0.09))
			for i in 2:
				_part(CylinderMesh.new(), _steel, Vector3(-0.04 + i * 0.08, 0.55, 0), Vector3(0.012, 0.45, 0.012))
		"medikit", "verband":
			var white := StandardMaterial3D.new()
			white.albedo_color = Color(0.92, 0.92, 0.9)
			_part(BoxMesh.new(), white, Vector3(0, 0.14, 0), Vector3(0.34, 0.22, 0.26))
			var red := StandardMaterial3D.new()
			red.albedo_color = Color(0.85, 0.1, 0.1)
			_part(BoxMesh.new(), red, Vector3(0, 0.26, 0), Vector3(0.2, 0.02, 0.06))
			_part(BoxMesh.new(), red, Vector3(0, 0.26, 0), Vector3(0.06, 0.02, 0.2))
		"wasserflasche":
			var glass := StandardMaterial3D.new()
			glass.albedo_color = Color(0.4, 0.65, 0.9, 0.7)
			glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			glass.roughness = 0.1
			_part(CylinderMesh.new(), glass, Vector3(0, 0.17, 0), Vector3(0.09, 0.34, 0.09))
			_part(CylinderMesh.new(), _steel, Vector3(0, 0.37, 0), Vector3(0.04, 0.06, 0.04))
		"brot":
			var crust := StandardMaterial3D.new()
			crust.albedo_color = Color(0.68, 0.48, 0.25)
			crust.roughness = 0.95
			_part(CapsuleMesh.new(), crust, Vector3(0, 0.11, 0), Vector3(0.36, 0.2, 0.22))
		"apfel":
			var apple := StandardMaterial3D.new()
			apple.albedo_color = Color(0.75, 0.15, 0.12)
			apple.roughness = 0.4
			_part(SphereMesh.new(), apple, Vector3(0, 0.09, 0), Vector3(0.18, 0.18, 0.18))
		"beeren", "nachtschatten":
			var berry := StandardMaterial3D.new()
			berry.albedo_color = Color(0.32, 0.14, 0.42)
			for offset in [Vector3(-0.05, 0.05, 0), Vector3(0.05, 0.05, 0.03), Vector3(0, 0.1, -0.04)]:
				_part(SphereMesh.new(), berry, offset, Vector3(0.09, 0.09, 0.09))
		"trockenfleisch", "rohes_fleisch", "braten":
			var meat := StandardMaterial3D.new()
			meat.albedo_color = item.color
			meat.roughness = 0.8
			_part(BoxMesh.new(), meat, Vector3(0, 0.06, 0), Vector3(0.3, 0.1, 0.2))
		"schlafsack", "plane":
			var roll := StandardMaterial3D.new()
			roll.albedo_color = item.color
			roll.roughness = 0.95
			var roll_part := _part(CapsuleMesh.new(), roll, Vector3(0, 0.12, 0), Vector3(0.24, 0.44, 0.24))
			roll_part.rotation.z = PI / 2.0
		"lagerfeuer_set":
			_part(CylinderMesh.new(), _wood, Vector3(0, 0.08, 0), Vector3(0.05, 0.4, 0.05)).rotation.z = PI / 2.0
			_part(CylinderMesh.new(), _wood, Vector3(0, 0.14, 0), Vector3(0.05, 0.4, 0.05)).rotation = Vector3(PI / 2.0, PI / 4.0, 0)
		_:
			# Restliche Ausruestung: Beutel
			var sack := StandardMaterial3D.new()
			sack.albedo_color = item.color
			sack.roughness = 0.95
			_part(SphereMesh.new(), sack, Vector3(0, 0.14, 0), Vector3(0.24, 0.28, 0.2))

func _blade(length: float, width: float) -> MeshInstance3D:
	var blade := _part(BoxMesh.new(), _steel, Vector3(0, 0.25 + length / 2.0, 0), Vector3(width, length, 0.015))
	_part(BoxMesh.new(), _wood, Vector3(0, 0.22, 0), Vector3(width * 2.2, 0.03, 0.03))
	_part(CylinderMesh.new(), _wood, Vector3(0, 0.12, 0), Vector3(0.025, 0.18, 0.025))
	return blade

func _part(mesh: Mesh, material: StandardMaterial3D, at: Vector3, part_scale: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	instance.scale = part_scale
	add_child(instance)
	return instance

## Nimmt das Item auf. Gibt false zurueck, wenn das Inventar voll ist.
func try_take(taker: TributeBase) -> bool:
	if not taker.add_item(item):
		return false
	queue_free()
	return true
