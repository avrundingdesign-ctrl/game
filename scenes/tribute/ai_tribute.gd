extends TributeBase
## KI-Tribut mit einfachem Zustandsautomat (Phase 1).
## Profile: karriero (stuermt Loot, bewacht Fuellhorn), ueberlebende (flieht,
## sammelt), opportunist (greift Schwache an), kaempfer/techniker (Mischformen).

enum State { WAIT, RUSH, FLEE, WANDER, GOTO_WATER, GUARD, HUNT }

const THINK_INTERVAL := 0.5
const ARRIVE_DISTANCE := 1.5
const HUNT_GIVE_UP_SECONDS := 12.0

var profil := "ueberlebende"
var state: State = State.WAIT

var _move_target := Vector3.ZERO
var _has_move_target := false
var _claimed_pickup: LootPickup = null
var _items_wanted := 1
var _hunt_target: TributeBase = null
var _hunt_timer := 0.0
var _flee_from := Vector3.ZERO
var _think_accumulator := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("tributes")
	_rng.randomize()
	_items_wanted = 3 if profil == "karriero" else (2 if profil in ["kaempfer", "opportunist"] else 1)

func _physics_process(delta: float) -> void:
	if not alive:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if GameManager.phase in [GameManager.Phase.COUNTDOWN, GameManager.Phase.GAME_OVER]:
		move_and_slide()
		return

	_think_accumulator += delta
	if _think_accumulator >= THINK_INTERVAL:
		_think_accumulator = 0.0
		_think()

	_move(delta)

# --- Denken (alle 0,5 s) ----------------------------------------------------

func _think() -> void:
	# Beduerfnisse haben Vorrang (ausser mitten im Kampf)
	if state != State.HUNT:
		if thirst < 35.0 and state != State.GOTO_WATER:
			_start_goto_water()
			return
		if hunger < 40.0 and best_food_index() >= 0:
			selected_slot = best_food_index()
			consume_selected()
			equip_best_weapon()

	match state:
		State.WAIT:
			_on_bloodbath_start()
		State.RUSH:
			_think_rush()
		State.FLEE:
			if not _has_move_target:
				_start_wander()
		State.WANDER:
			_think_wander()
		State.GOTO_WATER:
			_think_goto_water()
		State.GUARD:
			_think_guard()
		State.HUNT:
			_think_hunt()

func _on_bloodbath_start() -> void:
	if GameManager.phase == GameManager.Phase.COUNTDOWN:
		return
	match profil:
		"karriero":
			_claim_next_pickup(60.0)
		"opportunist", "kaempfer":
			# Nur aeusserer Ring (weniger Risiko), sonst Flucht
			if _rng.randf() < 0.6 and _claim_next_pickup(55.0, 20.0):
				pass
			else:
				_start_flee_from(Vector3.ZERO)
		_:
			# Katniss-Move: 40 % schnappen sich erst ein nahes Item vom Aussenring
			if _rng.randf() < 0.4 and _claim_next_pickup(18.0, 24.0):
				pass
			else:
				_start_flee_from(Vector3.ZERO)

func _think_rush() -> void:
	if _claimed_pickup == null or not is_instance_valid(_claimed_pickup):
		if _items_wanted > 0 and not _claim_next_pickup(60.0):
			_after_looting()
		elif _items_wanted <= 0:
			_after_looting()
		return
	if global_position.distance_to(_claimed_pickup.global_position) < ARRIVE_DISTANCE + 0.5:
		if _claimed_pickup.try_take(self):
			_items_wanted -= 1
			equip_best_weapon()
		_claimed_pickup = null
	# Karrieros kaempfen im Blutbad gegen Nicht-Karrieros in der Naehe
	if profil == "karriero" and GameManager.phase == GameManager.Phase.BLOODBATH:
		var enemy := _nearest_enemy(10.0)
		if enemy != null:
			_start_hunt(enemy)

func _after_looting() -> void:
	if profil == "karriero":
		_start_guard()
	elif GameManager.phase == GameManager.Phase.BLOODBATH:
		# Nach dem Griff ins Blutbad: raus aus der Gefahrenzone
		_start_flee_from(Vector3.ZERO)
	else:
		_start_wander()

func _think_wander() -> void:
	if not _has_move_target:
		_pick_wander_target()
	# Sammeln beim Umherstreifen (Ueberleben-Attribut): Beeren/Wurzeln finden
	if _rng.randf() < stats.ueberleben * 0.0012:
		hunger = minf(100.0, hunger + 25.0)
	# Opportunisten greifen deutlich schwaechere Tribute an
	if profil == "opportunist":
		var prey := _nearest_enemy(8.0)
		if prey != null and prey.health < health - 20.0:
			_start_hunt(prey)

func _think_goto_water() -> void:
	var lake := get_tree().get_first_node_in_group("lake")
	if lake == null:
		_start_wander()
		return
	var lake_radius: float = lake.get_meta("radius", 25.0)
	if global_position.distance_to(lake.global_position) < lake_radius + 1.5:
		drink_from_source()
		_start_wander()

func _think_guard() -> void:
	if not _has_move_target:
		_set_move_target(Vector3(_rng.randf_range(-18, 18), 0, _rng.randf_range(-18, 18)))
	var enemy := _nearest_enemy(14.0)
	if enemy != null:
		_start_hunt(enemy)

func _think_hunt() -> void:
	_hunt_timer += THINK_INTERVAL
	if _hunt_target == null or not is_instance_valid(_hunt_target) or not _hunt_target.alive \
			or _hunt_timer > HUNT_GIVE_UP_SECONDS:
		_hunt_target = null
		_after_looting()
		return
	_set_move_target(_hunt_target.global_position)
	try_melee_attack(_hunt_target)

# --- Zustandswechsel --------------------------------------------------------

func _start_hunt(target: TributeBase) -> void:
	state = State.HUNT
	_hunt_target = target
	_hunt_timer = 0.0
	equip_best_weapon()

func _start_guard() -> void:
	state = State.GUARD
	_has_move_target = false

func _start_wander() -> void:
	state = State.WANDER
	_has_move_target = false

func _start_goto_water() -> void:
	var lake := get_tree().get_first_node_in_group("lake")
	if lake == null:
		return
	state = State.GOTO_WATER
	var offset := Vector3(_rng.randf_range(-5, 5), 0, _rng.randf_range(-5, 5))
	_set_move_target(lake.global_position + offset)

func _start_flee_from(danger: Vector3) -> void:
	state = State.FLEE
	_flee_from = danger
	var away := (global_position - danger).normalized()
	if away.length() < 0.5:
		away = Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)).normalized()
	var distance := _rng.randf_range(80.0, 160.0)
	_set_move_target(global_position + away * distance)

func _pick_wander_target() -> void:
	var angle := _rng.randf() * TAU
	var radius := _rng.randf_range(60.0, 200.0)
	_set_move_target(Vector3(cos(angle) * radius, 0, sin(angle) * radius))

## Beansprucht das naechste freie Pickup im Umkreis. min_radius > 0 meidet das Zentrum.
func _claim_next_pickup(max_radius: float, min_radius := 0.0) -> bool:
	var best: LootPickup = null
	var best_distance := INF
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if pickup.claimed_by != null and is_instance_valid(pickup.claimed_by):
			continue
		var center_distance: float = pickup.global_position.length()
		if center_distance < min_radius:
			continue
		var distance := global_position.distance_to(pickup.global_position)
		if distance < best_distance and distance < max_radius:
			best_distance = distance
			best = pickup
	if best == null:
		return false
	best.claimed_by = self
	_claimed_pickup = best
	state = State.RUSH
	_set_move_target(best.global_position)
	return true

func _nearest_enemy(max_distance: float) -> TributeBase:
	var best: TributeBase = null
	var best_distance := max_distance
	for node in get_tree().get_nodes_in_group("tributes"):
		var other := node as TributeBase
		if other == self or not other.alive:
			continue
		# Karrieros greifen keine anderen Karrieros an (Ruedel-Allianz, Phase 1)
		if profil == "karriero" and "profil" in other and other.profil == "karriero":
			continue
		var distance := global_position.distance_to(other.global_position)
		if distance < best_distance:
			best_distance = distance
			best = other
	return best

# --- Bewegung & Schaden -----------------------------------------------------

func _set_move_target(target: Vector3) -> void:
	_move_target = target
	_has_move_target = true

func _move(_delta: float) -> void:
	if not _has_move_target:
		velocity.x = move_toward(velocity.x, 0, 0.5)
		velocity.z = move_toward(velocity.z, 0, 0.5)
		move_and_slide()
		return
	var to_target := _move_target - global_position
	to_target.y = 0
	if to_target.length() < ARRIVE_DISTANCE:
		_has_move_target = false
		move_and_slide()
		return
	var speed := sprint_speed() if state in [State.RUSH, State.FLEE, State.HUNT] else move_speed()
	var direction := to_target.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	look_at(global_position + direction, Vector3.UP)
	move_and_slide()

func take_damage(amount: float, source_name: String) -> void:
	super.take_damage(amount, source_name)
	if not alive:
		return
	# Reaktion auf Angriff: Kaempfer wehren sich, der Rest flieht
	var attacker := _find_tribute_by_name(source_name)
	if attacker != null:
		if profil in ["karriero", "kaempfer"] and health > 40.0:
			_start_hunt(attacker)
		else:
			_start_flee_from(attacker.global_position)

func _find_tribute_by_name(searched: String) -> TributeBase:
	for node in get_tree().get_nodes_in_group("tributes"):
		if node is TributeBase and node.tribute_name == searched and node.alive:
			return node
	return null
