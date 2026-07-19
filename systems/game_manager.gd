extends Node
## Steuert die Spielphasen: Countdown -> Blutbad -> Tage/Naechte -> Finale,
## zaehlt Tribute, meldet Tode (Kanone) und beendet die Partie.

enum Phase { COUNTDOWN, BLOODBATH, DAY, NIGHT, FINALE, GAME_OVER }

signal phase_changed(new_phase: Phase)
signal countdown_tick(seconds_left: int)
signal tribute_died(tribute_name: String, district: int, killer_name: String)
signal fallen_projection(fallen: Array)  # Himmelsprojektion am Abend
signal game_ended(victory: bool, stats: Dictionary)

const PLAYER_NAME := "Spieler"

## Schnelltest-Modus (PANEM_FAST=1): verkuerzte Zeiten fuer Headless-Tests.
var countdown_seconds := 60
var bloodbath_seconds := 180
## Observer-Modus (PANEM_OBSERVER=1): Simulation laeuft ohne Spieler bis zum Sieger.
var observer_mode := false

func _ready() -> void:
	if OS.get_environment("PANEM_FAST") == "1":
		countdown_seconds = 5
		bloodbath_seconds = 15
	observer_mode = OS.get_environment("PANEM_OBSERVER") == "1"

var phase: Phase = Phase.COUNTDOWN
var day_number := 1
var tributes_alive := 0
var deaths_today: Array[Dictionary] = []
var all_fallen_districts: Array[int] = []
var player_kills := 0
var player_alive := true

var _phase_timer := 0.0
var _countdown_left := 60

func reset() -> void:
	phase = Phase.COUNTDOWN
	day_number = 1
	tributes_alive = 0
	deaths_today = []
	all_fallen_districts = []
	player_kills = 0
	player_alive = true
	_phase_timer = 0.0
	_countdown_left = countdown_seconds

func register_tributes(count: int) -> void:
	tributes_alive = count

func _process(delta: float) -> void:
	match phase:
		Phase.COUNTDOWN:
			_phase_timer += delta
			var left := countdown_seconds - int(_phase_timer)
			if left != _countdown_left:
				_countdown_left = left
				countdown_tick.emit(left)
			if left <= 0:
				set_phase(Phase.BLOODBATH)
		Phase.BLOODBATH:
			_phase_timer += delta
			if _phase_timer >= bloodbath_seconds:
				set_phase(Phase.DAY)

func set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_phase_timer = 0.0
	phase_changed.emit(new_phase)
	print("[GameManager] Phase: %s (Tag %d, %d Tribute am Leben)" % [Phase.keys()[new_phase], day_number, tributes_alive])

func on_sunrise() -> void:
	if phase == Phase.NIGHT:
		day_number += 1
		set_phase(Phase.DAY)

func on_sunset() -> void:
	if phase == Phase.DAY:
		set_phase(Phase.NIGHT)
	if not deaths_today.is_empty():
		fallen_projection.emit(deaths_today.duplicate())
		deaths_today = []

func report_death(tribute_name: String, district: int, killer_name: String) -> void:
	tributes_alive -= 1
	deaths_today.append({"name": tribute_name, "district": district})
	all_fallen_districts.append(district)
	tribute_died.emit(tribute_name, district, killer_name)
	print("[Kanone] %s (D%d) gefallen — %s. Noch %d am Leben." % [tribute_name, district, killer_name, tributes_alive])
	if killer_name == PLAYER_NAME:
		player_kills += 1
	if tribute_name == PLAYER_NAME:
		player_alive = false
		if not observer_mode:
			_end_game(false)
			return
	if tributes_alive <= 1:
		_end_game(player_alive)
	elif tributes_alive <= 3 and phase not in [Phase.FINALE, Phase.GAME_OVER]:
		set_phase(Phase.FINALE)

func _end_game(victory: bool) -> void:
	set_phase(Phase.GAME_OVER)
	game_ended.emit(victory, {
		"tage": day_number,
		"kills": player_kills,
		"uebrig": tributes_alive,
		"rating": SponsorSystem.rating,
	})
