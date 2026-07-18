extends Node
## Der Spielmacher-Regisseur: misst die Spannung und greift ein, wenn die
## Spiele langweilig werden — Wetter, Waldbrand, Feast, Austrocknung, Mutts.
## "Nichts in der Arena ist Zufall."

signal announcement(text: String)  # Lautsprecher-Durchsage
signal feast_started(position: Vector3)
signal ponds_dried()
signal wildfire_started(center: Vector3)
signal mutts_released()

## Arena-Stunden ohne Tod, bis die Spielmacher eingreifen.
const BOREDOM_LIMIT_HOURS := 20.0

var _boredom_hours := 0.0
var _feast_done := false
var _ponds_dried := false
var _wildfire_active := false
var _mutts_released := false
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	GameManager.tribute_died.connect(func(_n: String, _d: int, _k: String) -> void:
		_boredom_hours = 0.0)
	GameManager.phase_changed.connect(_on_phase_changed)

func reset() -> void:
	_boredom_hours = 0.0
	_feast_done = false
	_ponds_dried = false
	_wildfire_active = false
	_mutts_released = false

func _process(delta: float) -> void:
	if GameManager.phase in [GameManager.Phase.COUNTDOWN, GameManager.Phase.BLOODBATH, GameManager.Phase.GAME_OVER]:
		return
	_boredom_hours += delta * 24.0 / DayNight.day_length_seconds
	if _boredom_hours >= BOREDOM_LIMIT_HOURS:
		_boredom_hours = 0.0
		_intervene()

## Endgame-Bedingungen unabhaengig von Langeweile.
func _on_phase_changed(new_phase: GameManager.Phase) -> void:
	if new_phase == GameManager.Phase.FINALE:
		if not _ponds_dried:
			_dry_ponds()
		# Wolfsmutts kommen kurz nach Finale-Beginn
		get_tree().create_timer(2.0 / 24.0 * DayNight.day_length_seconds).timeout.connect(_release_mutts)

## Die Spielmacher waehlen den passenden Eingriff.
func _intervene() -> void:
	# Prioritaet: Feast (einmalig, ab Tag 2, max 12 Ueberlebende) > Waldbrand > Wetter
	if not _feast_done and GameManager.day_number >= 2 and GameManager.tributes_alive <= 18:
		_start_feast()
	elif not _wildfire_active and _rng.randf() < 0.5:
		_start_wildfire()
	elif not _ponds_dried and GameManager.day_number >= 4:
		_dry_ponds()
	else:
		WeatherSystem.set_weather([WeatherSystem.Weather.HITZE, WeatherSystem.Weather.NEBEL][_rng.randi() % 2])
		announcement.emit("Das Wetter schlaegt um ...")

func _start_feast() -> void:
	_feast_done = true
	announcement.emit("Achtung, Tribute! Beim Fuellhorn erwartet euch ein Fest.\nJeder von euch braucht etwas — dringend.")
	print("[Gamemaker] FEAST angekuendigt")
	feast_started.emit(Vector3.ZERO)

func _start_wildfire() -> void:
	_wildfire_active = true
	var angle := _rng.randf() * TAU
	var center := Vector3(cos(angle), 0, sin(angle)) * 180.0
	print("[Gamemaker] WALDBRAND bei %s" % center)
	wildfire_started.emit(center)
	get_tree().create_timer(3.0 / 24.0 * DayNight.day_length_seconds).timeout.connect(
		func() -> void: _wildfire_active = false)

func _dry_ponds() -> void:
	_ponds_dried = true
	announcement.emit("Die Quellen der Arena versiegen. Nur der See bleibt.")
	print("[Gamemaker] Teiche ausgetrocknet")
	ponds_dried.emit()

func _release_mutts() -> void:
	if _mutts_released or GameManager.phase == GameManager.Phase.GAME_OVER:
		return
	_mutts_released = true
	announcement.emit("Die Spielmacher schicken ihre letzten Kreaturen.")
	print("[Gamemaker] WOLFSMUTTS freigelassen")
	mutts_released.emit()
