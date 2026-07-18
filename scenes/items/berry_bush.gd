class_name BerryBush
extends Node3D
## Beerenstrauch: [E] pfluecken. 15 % der Straeucher tragen Nachtschatten —
## toedlich! Tribute mit Ueberleben >= 6 erkennen die Gefahr am Namen.

const REGROW_SECONDS := 120.0

var is_poisonous := false
var has_berries := true

var _berry_meshes: Array[MeshInstance3D] = []
var _regrow_timer := 0.0

static func create(at: Vector3, poisonous: bool) -> BerryBush:
	var bush := BerryBush.new()
	bush.position = at
	bush.is_poisonous = poisonous
	return bush

func _ready() -> void:
	add_to_group("bushes")
	var foliage := MeshInstance3D.new()
	var foliage_mesh := SphereMesh.new()
	foliage_mesh.radius = 0.6
	foliage_mesh.height = 1.0
	foliage.mesh = foliage_mesh
	var foliage_material := StandardMaterial3D.new()
	foliage_material.albedo_color = Color(0.2, 0.4, 0.18)
	foliage.material_override = foliage_material
	foliage.position.y = 0.5
	add_child(foliage)

	var berry_material := StandardMaterial3D.new()
	berry_material.albedo_color = Color(0.35, 0.15, 0.45)
	for i in 5:
		var berry := MeshInstance3D.new()
		var berry_mesh := SphereMesh.new()
		berry_mesh.radius = 0.05
		berry_mesh.height = 0.1
		berry.mesh = berry_mesh
		berry.material_override = berry_material
		var angle := TAU * i / 5.0
		berry.position = Vector3(cos(angle) * 0.45, 0.6 + 0.15 * sin(i * 2.1), sin(angle) * 0.45)
		add_child(berry)
		_berry_meshes.append(berry)

func _process(delta: float) -> void:
	if has_berries:
		return
	_regrow_timer -= delta
	if _regrow_timer <= 0.0:
		has_berries = true
		for berry in _berry_meshes:
			berry.visible = true

## Pfluecken: liefert das Beeren-Item (bei Giftstrauch: Nachtschatten).
func pick(picker: TributeBase) -> Dictionary:
	if not has_berries:
		return {}
	var item := LootTables.get_item("nachtschatten" if is_poisonous else "beeren")
	if is_poisonous and float(picker.stats.ueberleben) >= 6.0:
		item["name"] = "Nachtschatten (GIFTIG!)"
	has_berries = false
	_regrow_timer = REGROW_SECONDS
	for berry in _berry_meshes:
		berry.visible = false
	return item
