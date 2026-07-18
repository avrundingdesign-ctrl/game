extends Node
## Wetter der Arena — vollstaendig von den Spielmachern kontrolliert.
## Beeinflusst Durst-Verfall, Sichtweite der KI und Lagerfeuer.

enum Weather { KLAR, REGEN, NEBEL, HITZE }

signal weather_changed(new_weather: Weather)

var weather: Weather = Weather.KLAR

var _hours_until_change := 8.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func _process(delta: float) -> void:
	if GameManager.phase in [GameManager.Phase.COUNTDOWN, GameManager.Phase.GAME_OVER]:
		return
	var hours_per_second := 24.0 / DayNight.day_length_seconds
	_hours_until_change -= delta * hours_per_second
	if _hours_until_change <= 0.0:
		_roll_weather()

func _roll_weather() -> void:
	var pool: Array = [Weather.KLAR, Weather.KLAR, Weather.KLAR, Weather.REGEN, Weather.NEBEL, Weather.HITZE]
	set_weather(pool[_rng.randi() % pool.size()])

## Auch der Gamemaker ruft das direkt auf (erzwungenes Wetter).
func set_weather(new_weather: Weather) -> void:
	_hours_until_change = _rng.randf_range(5.0, 12.0)
	if new_weather == weather:
		return
	weather = new_weather
	weather_changed.emit(weather)
	print("[Wetter] %s" % Weather.keys()[weather])
	if weather == Weather.REGEN:
		# Regen loescht alle Lagerfeuer
		for fire in get_tree().get_nodes_in_group("campfires"):
			fire.queue_free()
	_apply_environment()

func weather_name() -> String:
	match weather:
		Weather.REGEN: return "Regen"
		Weather.NEBEL: return "Nebel"
		Weather.HITZE: return "Gluthitze"
		_: return "Klar"

## Multiplikator fuer den Durst-Verfall.
func thirst_multiplier() -> float:
	match weather:
		Weather.HITZE: return 1.8
		Weather.REGEN: return 0.6
		_: return 1.0

## Multiplikator fuer die KI-Sichtweite.
func sight_multiplier() -> float:
	match weather:
		Weather.NEBEL: return 0.45
		Weather.REGEN: return 0.75
		_: return 1.0

func _apply_environment() -> void:
	var env_node := get_tree().get_first_node_in_group("world_env") as WorldEnvironment
	if env_node == null:
		return
	var env := env_node.environment
	match weather:
		Weather.NEBEL:
			env.fog_enabled = true
			env.fog_density = 0.03
			env.fog_light_color = Color(0.75, 0.77, 0.8)
		Weather.REGEN:
			env.fog_enabled = true
			env.fog_density = 0.008
			env.fog_light_color = Color(0.5, 0.55, 0.62)
		_:
			env.fog_enabled = false
