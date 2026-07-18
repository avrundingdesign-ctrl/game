extends Node
## Steuert die Spielphasen: Countdown -> Blutbad -> Tage/Naechte -> Finale.

enum Phase { COUNTDOWN, BLOODBATH, DAY, NIGHT, FINALE, GAME_OVER }

signal phase_changed(new_phase: Phase)
signal countdown_tick(seconds_left: int)
signal tribute_died(tribute_name: String, district: int)

const COUNTDOWN_SECONDS := 60
const BLOODBATH_SECONDS := 180

var phase: Phase = Phase.COUNTDOWN
var day_number := 1
var tributes_alive := 24

var _phase_timer := 0.0
var _countdown_left := COUNTDOWN_SECONDS

func _ready() -> void:
	set_phase(Phase.COUNTDOWN)

func _process(delta: float) -> void:
	match phase:
		Phase.COUNTDOWN:
			_phase_timer += delta
			var left := COUNTDOWN_SECONDS - int(_phase_timer)
			if left != _countdown_left:
				_countdown_left = left
				countdown_tick.emit(left)
			if left <= 0:
				set_phase(Phase.BLOODBATH)
		Phase.BLOODBATH:
			_phase_timer += delta
			if _phase_timer >= BLOODBATH_SECONDS:
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

func report_death(tribute_name: String, district: int) -> void:
	tributes_alive -= 1
	tribute_died.emit(tribute_name, district)
	# TODO: Kanonenschuss abspielen, abends Himmelsprojektion
	if tributes_alive <= 3 and phase != Phase.FINALE:
		set_phase(Phase.FINALE)
	if tributes_alive <= 1:
		set_phase(Phase.GAME_OVER)
