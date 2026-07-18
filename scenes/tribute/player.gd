extends TributeBase
## Spieler: Third-Person-Controller (WASD + Maus, Shift = Sprint, Space = Sprung).
## E = aufheben/trinken, F = essen/trinken aus Slot, 1-6 = Slot, LMB = Angriff.
## Waehrend des Countdowns ist Bewegung gesperrt (Platten-Regel!).

signal interact_hint_changed(hint: String)

const JUMP_VELOCITY := 4.2
const MOUSE_SENSITIVITY := 0.0025
const INTERACT_RANGE := 2.5

@onready var pivot: Node3D = $CameraPivot

var _nearby_pickup: LootPickup = null
var _can_drink := false

func _ready() -> void:
	add_to_group("tributes")
	add_to_group("player")
	tribute_name = GameManager.PLAYER_NAME
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		pivot.rotation.x = clamp(pivot.rotation.x, -1.2, 0.6)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if not alive or GameManager.phase == GameManager.Phase.GAME_OVER:
		return
	if event.is_action_pressed("interact"):
		_interact()
	elif event.is_action_pressed("consume"):
		consume_selected()
	elif event.is_action_pressed("attack"):
		_attack()
	else:
		for slot in 6:
			if event.is_action_pressed("slot_%d" % (slot + 1)) and slot < inventory.size():
				selected_slot = slot
				inventory_changed.emit(inventory, selected_slot)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not alive or GameManager.phase == GameManager.Phase.COUNTDOWN:
		move_and_slide()
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := sprint_speed() if Input.is_action_pressed("sprint") else move_speed()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	_update_interact_hint()

# --- Interaktion ------------------------------------------------------------

func _update_interact_hint() -> void:
	_nearby_pickup = null
	_can_drink = false

	var lake := get_tree().get_first_node_in_group("lake")
	if lake != null:
		var lake_radius: float = lake.get_meta("radius", 25.0)
		if global_position.distance_to(lake.global_position) < lake_radius + 1.5:
			_can_drink = true

	var best_distance := INTERACT_RANGE
	for pickup in get_tree().get_nodes_in_group("pickups"):
		var distance: float = global_position.distance_to(pickup.global_position)
		if distance < best_distance:
			best_distance = distance
			_nearby_pickup = pickup

	if _nearby_pickup != null:
		interact_hint_changed.emit("[E] %s aufheben" % _nearby_pickup.item.name)
	elif _can_drink:
		interact_hint_changed.emit("[E] Trinken")
	else:
		interact_hint_changed.emit("")

func _interact() -> void:
	if _nearby_pickup != null:
		if not _nearby_pickup.try_take(self):
			interact_hint_changed.emit("Inventar voll!")
	elif _can_drink:
		drink_from_source()

func _attack() -> void:
	var forward := -global_transform.basis.z
	for node in get_tree().get_nodes_in_group("tributes"):
		var other := node as TributeBase
		if other == self or not other.alive:
			continue
		var to_other := other.global_position - global_position
		if to_other.length() > MELEE_RANGE + 0.3:
			continue
		if forward.dot(to_other.normalized()) < 0.3:
			continue  # nicht im Blickfeld
		try_melee_attack(other)
		return
