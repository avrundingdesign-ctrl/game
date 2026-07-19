class_name TributeBase
extends CharacterBody3D
## Gemeinsame Basis fuer Spieler und KI-Tribute: Attribute, Beduerfnisse,
## Gesundheit, Inventar und Kampf. Spieler und KI teilen dieselben Regeln.

signal died(tribute: TributeBase, killer_name: String)
signal needs_changed(health: float, thirst: float, hunger: float)
signal inventory_changed(inventory: Array, selected_slot: int)

const MAX_SLOTS := 6
const FIST_DAMAGE := 8.0
const MELEE_RANGE := 2.0
const MELEE_COOLDOWN := 1.2

var tribute_name := "Tribut"
var district := 12
## Attribute 1-10: staerke, geschick, ausdauer, ueberleben, tarnung, charisma
var stats := {"staerke": 5, "geschick": 5, "ausdauer": 5, "ueberleben": 5, "tarnung": 5, "charisma": 5}

var health := 100.0
var thirst := 100.0   # 100 = voll hydriert
var hunger := 100.0   # 100 = satt
var alive := true

var inventory: Array[Dictionary] = []
var selected_slot := 0
var bleeding_seconds := 0.0
var venom_seconds := 0.0   # Jaegerwespen-Gift: Schaden + Verlangsamung
var is_sprinting := false
var _melee_cooldown := 0.0
var _last_attacker_name := ""

## Verfall pro Echtzeit-Sekunde (bei 600 s/Tag: Durst ~1,5 Tage, Hunger ~2,5 Tage).
## Hohe Ausdauer verlangsamt den Verfall um bis zu 30 %.
func _needs_decay_factor() -> float:
	return 1.0 - (float(stats.ausdauer) - 5.0) * 0.06

func _process(delta: float) -> void:
	if not alive:
		return
	if GameManager.phase in [GameManager.Phase.COUNTDOWN, GameManager.Phase.GAME_OVER]:
		return
	_melee_cooldown = maxf(0.0, _melee_cooldown - delta)
	# Durst leert sich in ~1,5 Arena-Tagen, Hunger in ~2,5 (skaliert mit Taglaenge)
	var factor := _needs_decay_factor() * WeatherSystem.thirst_multiplier()
	var day: float = DayNight.day_length_seconds
	thirst = maxf(0.0, thirst - 100.0 / (1.5 * day) * factor * delta)
	hunger = maxf(0.0, hunger - 100.0 / (2.5 * day) * factor * delta)
	if thirst <= 0.0 or hunger <= 0.0:
		var cause := "Verdursten" if thirst <= 0.0 else "Verhungern"
		take_damage(2.0 * delta, cause)
	# Blutende Wunden (Verband/Medizin stoppt sie)
	if bleeding_seconds > 0.0:
		bleeding_seconds = maxf(0.0, bleeding_seconds - delta)
		take_damage(1.2 * delta, "Blutverlust")
	# Wespengift: Schaden ueber Zeit + Verlangsamung
	if venom_seconds > 0.0:
		venom_seconds = maxf(0.0, venom_seconds - delta)
		take_damage(1.5 * delta, "Jaegerwespen")
	# Tiefe Nacht (23-5 Uhr) ohne Schlafsack oder Lagerfeuer: Kaelteschaden
	if (DayNight.hour < 5.0 or DayNight.hour >= 23.0) and not _is_warm():
		take_damage(11.0 / (0.25 * day) * delta, "Kaelte")
	elif health < 100.0 and health > 0.0 and thirst > 60.0 and hunger > 60.0 and bleeding_seconds <= 0.0:
		# Langsame Heilung bei guter Versorgung (~12 HP pro Tag)
		health = minf(100.0, health + 12.0 / day * delta)
	needs_changed.emit(health, thirst, hunger)

func move_speed() -> float:
	var base: float = 3.2 + float(stats.geschick) * 0.25
	if thirst < 20.0 or hunger < 20.0:
		base *= 0.7  # geschwaecht
	if venom_seconds > 0.0:
		base *= 0.75  # vergiftet
	return base

func sprint_speed() -> float:
	return move_speed() * 1.8

func take_damage(amount: float, source_name: String) -> void:
	if not alive:
		return
	health -= amount
	_last_attacker_name = source_name
	needs_changed.emit(health, thirst, hunger)
	if health <= 0.0:
		die(source_name)

func die(killer_name: String) -> void:
	if not alive:
		return
	alive = false
	health = 0.0
	died.emit(self, killer_name)
	GameManager.report_death(tribute_name, district, killer_name)
	# Leiche: nur das Mesh umlegen (Kamera bleibt aufrecht), Kollision aus
	if has_node("Mesh"):
		get_node("Mesh").rotation.z = PI / 2.0
	set_collision_layer_value(1, false)
	set_physics_process(false)

# --- Inventar ---------------------------------------------------------------

func add_item(item: Dictionary) -> bool:
	if inventory.size() >= MAX_SLOTS:
		return false
	inventory.append(item)
	inventory_changed.emit(inventory, selected_slot)
	return true

func selected_item() -> Dictionary:
	if selected_slot < inventory.size():
		return inventory[selected_slot]
	return {}

func consume_selected() -> bool:
	var item := selected_item()
	if item.is_empty() or item.type not in ["essen", "wasser", "medizin"]:
		return false
	if item.get("giftig", false):
		inventory.remove_at(selected_slot)
		selected_slot = clampi(selected_slot, 0, maxi(0, inventory.size() - 1))
		inventory_changed.emit(inventory, selected_slot)
		take_damage(999.0, "Nachtschatten")
		return true
	thirst = minf(100.0, thirst + item.get("hydration", 0.0))
	hunger = minf(100.0, hunger + item.get("nutrition", 0.0))
	health = minf(100.0, health + item.get("heal", 0.0))
	if item.type == "medizin":
		bleeding_seconds = 0.0
	inventory.remove_at(selected_slot)
	selected_slot = clampi(selected_slot, 0, maxi(0, inventory.size() - 1))
	inventory_changed.emit(inventory, selected_slot)
	needs_changed.emit(health, thirst, hunger)
	return true

func best_food_index() -> int:
	for i in inventory.size():
		if inventory[i].type == "essen" and not inventory[i].get("giftig", false):
			return i
	return -1

func best_water_index() -> int:
	for i in inventory.size():
		if inventory[i].type == "wasser":
			return i
	return -1

func best_medicine_index() -> int:
	for i in inventory.size():
		if inventory[i].type == "medizin":
			return i
	return -1

func drink_from_source() -> void:
	thirst = 100.0
	needs_changed.emit(health, thirst, hunger)

func has_item(id: String) -> bool:
	for item in inventory:
		if item.id == id:
			return true
	return false

func _is_warm() -> bool:
	if has_item("schlafsack"):
		return true
	for fire in get_tree().get_nodes_in_group("campfires"):
		if global_position.distance_to(fire.global_position) < 4.5:
			return true
	return false

# --- Munition ---------------------------------------------------------------

func arrow_count() -> int:
	var total := 0
	for item in inventory:
		if item.id == "pfeile":
			total += item.count
	return total

func use_arrow() -> bool:
	for i in inventory.size():
		if inventory[i].id == "pfeile":
			inventory[i].count -= 1
			if inventory[i].count <= 0:
				inventory.remove_at(i)
				selected_slot = clampi(selected_slot, 0, maxi(0, inventory.size() - 1))
			inventory_changed.emit(inventory, selected_slot)
			return true
	return false

# --- Kampf ------------------------------------------------------------------

func equipped_weapon() -> Dictionary:
	var item := selected_item()
	return item if not item.is_empty() and item.type == "waffe" else {}

func best_weapon_damage() -> float:
	var best := FIST_DAMAGE
	for item in inventory:
		if item.type == "waffe":
			best = maxf(best, item.damage)
	return best

func melee_damage() -> float:
	var weapon := equipped_weapon()
	var base: float = weapon.damage if not weapon.is_empty() else FIST_DAMAGE
	return base * (0.75 + float(stats.staerke) * 0.05)

## Greift ein Ziel an, wenn es in Reichweite ist. Gibt true bei Treffer zurueck.
func try_melee_attack(target: TributeBase) -> bool:
	if _melee_cooldown > 0.0 or not alive or target == null or not target.alive:
		return false
	if global_position.distance_to(target.global_position) > MELEE_RANGE:
		return false
	_melee_cooldown = MELEE_COOLDOWN
	target.take_damage(melee_damage(), tribute_name)
	# Waffentreffer koennen blutende Wunden reissen
	if not equipped_weapon().is_empty() and randf() < 0.35:
		target.bleeding_seconds = maxf(target.bleeding_seconds, 20.0)
	return true

## Schiesst einen Pfeil, wenn Bogen ausgeruestet und Pfeile vorhanden sind.
func try_shoot_arrow(from: Vector3, direction: Vector3) -> bool:
	if _melee_cooldown > 0.0 or not alive:
		return false
	var weapon := equipped_weapon()
	if weapon.is_empty() or weapon.id != "bogen":
		return false
	if not use_arrow():
		return false
	_melee_cooldown = 1.0
	var arrow := Arrow.shoot(from, direction, self, weapon.damage)
	get_parent().add_child(arrow)
	return true

## Waehlt das Item mit der gegebenen ID in den aktiven Slot. true bei Erfolg.
func select_item(id: String) -> bool:
	for i in inventory.size():
		if inventory[i].id == id:
			selected_slot = i
			inventory_changed.emit(inventory, selected_slot)
			return true
	return false

## KI-Helfer: bestes Item im Inventar als Waffe in den aktiven Slot legen.
func equip_best_weapon() -> void:
	var best_index := -1
	var best_damage := 0.0
	for i in inventory.size():
		if inventory[i].type == "waffe" and inventory[i].damage > best_damage:
			best_damage = inventory[i].damage
			best_index = i
	if best_index >= 0:
		selected_slot = best_index
		inventory_changed.emit(inventory, selected_slot)
